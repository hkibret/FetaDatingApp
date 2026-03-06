// supabase/functions/stripe-create-checkout/index.ts
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import Stripe from "npm:stripe@14.25.0";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, Authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};

function json(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: corsHeaders,
  });
}

const stripeSecret = Deno.env.get("STRIPE_SECRET_KEY") ?? "";
const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const siteUrlEnv = Deno.env.get("SITE_URL") ?? "";

const stripe = new Stripe(stripeSecret, {
  apiVersion: "2024-06-20",
});

const PRICE_MAP: Record<string, string> = {
  gold_1m: Deno.env.get("PRICE_GOLD_1M") ?? "",
  gold_3m: Deno.env.get("PRICE_GOLD_3M") ?? "",
  gold_12m: Deno.env.get("PRICE_GOLD_12M") ?? "",
  platinum_1m: Deno.env.get("PRICE_PLATINUM_1M") ?? "",
  platinum_3m: Deno.env.get("PRICE_PLATINUM_3M") ?? "",
  platinum_12m: Deno.env.get("PRICE_PLATINUM_12M") ?? "",
};

function planFromKey(key: string): "gold" | "platinum" {
  return key.startsWith("platinum") ? "platinum" : "gold";
}

function getSiteUrl(req: Request): string {
  const origin = req.headers.get("origin")?.trim();
  if (origin) return origin.replace(/\/+$/, "");
  if (siteUrlEnv) return siteUrlEnv.replace(/\/+$/, "");
  return "http://localhost:5000";
}

function getAuthHeader(req: Request): string {
  return (
    req.headers.get("authorization") ??
    req.headers.get("Authorization") ??
    ""
  ).trim();
}

function isBearerToken(authHeader: string): boolean {
  return /^Bearer\s+.+$/i.test(authHeader);
}

function getMissingEnvVars(): string[] {
  const missing: string[] = [];

  if (!stripeSecret) missing.push("STRIPE_SECRET_KEY");
  if (!supabaseUrl) missing.push("SUPABASE_URL");
  if (!supabaseAnonKey) missing.push("SUPABASE_ANON_KEY");

  return missing;
}

function getMissingPriceEnvVars(): string[] {
  return Object.entries(PRICE_MAP)
    .filter(([, value]) => !value || value.trim() === "")
    .map(([key]) => key);
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    if (req.method !== "POST") {
      return json(405, { error: "Method not allowed" });
    }

    const missingEnv = getMissingEnvVars();
    if (missingEnv.length > 0) {
      console.error("Missing function env vars:", missingEnv);
      return json(500, {
        error: "Missing required environment variables",
        missing: missingEnv,
      });
    }

    const missingPriceEnv = getMissingPriceEnvVars();
    if (missingPriceEnv.length > 0) {
      console.error("Missing Stripe price env vars:", missingPriceEnv);
      return json(500, {
        error: "Missing Stripe price environment variables",
        missing: missingPriceEnv,
      });
    }

    const authHeader = getAuthHeader(req);

    console.log("AUTH HEADER PRESENT:", !!authHeader);
    console.log(
      "AUTH HEADER PREFIX:",
      authHeader ? authHeader.slice(0, 24) : "(empty)",
    );

    if (!authHeader) {
      return json(401, { error: "Missing Authorization header" });
    }

    if (!isBearerToken(authHeader)) {
      return json(401, {
        error: "Invalid Authorization header format",
        received_prefix: authHeader.slice(0, 40),
      });
    }

    const token = authHeader.replace(/^Bearer\s+/i, "").trim();

    if (!token) {
      return json(401, { error: "Missing bearer token" });
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    });

    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser(token);

    if (userError || !user) {
      console.error("getUser error:", userError);
      return json(401, {
        error: "Unauthorized",
        details: userError?.message ?? "Invalid JWT",
      });
    }

    let payload: Record<string, unknown> = {};
    try {
      payload = await req.json();
    } catch (_) {
      payload = {};
    }

    const priceKey =
      (payload.priceKey as string | undefined) ??
      (payload.price_key as string | undefined);

    if (!priceKey || priceKey.trim() === "") {
      return json(400, {
        error: "Missing priceKey",
        accepted_keys: ["priceKey", "price_key"],
      });
    }

    const normalizedPriceKey = priceKey.trim();
    const priceId = PRICE_MAP[normalizedPriceKey];

    if (!priceId || priceId.trim() === "") {
      return json(400, {
        error: "Invalid priceKey",
        priceKey: normalizedPriceKey,
        allowed: Object.keys(PRICE_MAP),
      });
    }

    const planId = planFromKey(normalizedPriceKey);
    const siteUrl = getSiteUrl(req);

    console.log("Creating checkout for user:", user.id);
    console.log("Using priceKey:", normalizedPriceKey);
    console.log("Using siteUrl:", siteUrl);

    const checkoutSession = await stripe.checkout.sessions.create({
      mode: "subscription",
      line_items: [{ price: priceId, quantity: 1 }],
      success_url: `${siteUrl}/#/upgrade/success`,
      cancel_url: `${siteUrl}/#/upgrade/cancel`,
      allow_promotion_codes: true,
      customer_email: user.email ?? undefined,
      subscription_data: {
        metadata: {
          user_id: user.id,
          plan_id: planId,
          price_key: normalizedPriceKey,
        },
      },
      metadata: {
        user_id: user.id,
        plan_id: planId,
        price_key: normalizedPriceKey,
      },
    });

    if (!checkoutSession.url) {
      return json(500, { error: "Stripe checkout URL missing" });
    }

    return json(200, {
      url: checkoutSession.url,
    });
  } catch (e) {
    console.error("stripe-create-checkout error:", e);
    return json(500, {
      error: "Server error",
      details: e instanceof Error ? e.message : String(e),
    });
  }
});