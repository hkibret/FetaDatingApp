"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { register } from "../../services/auth";

export default function RegisterPage() {
  const router = useRouter();
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [err, setErr] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setErr(null);
    setLoading(true);
    try {
      await register(name, email, password);
      router.push("/search");
    } catch (e: any) {
      setErr(e?.message ?? "Register failed");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div style={{ padding: 24, maxWidth: 420, margin: "0 auto" }}>
      <h1>Register</h1>
      <form onSubmit={onSubmit} style={{ display: "grid", gap: 12 }}>
        <input
          placeholder="Name"
          value={name}
          onChange={(e) => setName(e.target.value)}
          style={{ padding: 12 }}
        />
        <input
          placeholder="Email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          style={{ padding: 12 }}
        />
        <input
          placeholder="Password"
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          style={{ padding: 12 }}
        />
        <button disabled={loading} style={{ padding: 12 }}>
          {loading ? "Creating..." : "Create account"}
        </button>
      </form>
      {err && <p style={{ color: "crimson" }}>{err}</p>}
      <p style={{ marginTop: 12 }}>
        Have an account? <a href="/login">Login</a>
      </p>
    </div>
  );
}
