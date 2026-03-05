// lib/features/billing/billing_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'billing_repo.dart';
import 'billing_models.dart';

// Read from --dart-define (same as main.dart)
const String _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

final billingRepoProvider = Provider<BillingRepo>((ref) {
  if (_supabaseAnonKey.isEmpty) {
    throw Exception(
      'Missing SUPABASE_ANON_KEY. Pass it via '
      '--dart-define=SUPABASE_ANON_KEY=...',
    );
  }

  // BillingRepo signature:
  // BillingRepo(SupabaseClient sb, {required String anonKey})
  return BillingRepo(Supabase.instance.client, anonKey: _supabaseAnonKey);
});

/// Active subscription (null => free)
final myActiveSubscriptionProvider = FutureProvider<ActiveSubscription?>((ref) {
  final repo = ref.read(billingRepoProvider);
  return repo.fetchMyActiveSubscription();
});

/// Entitlements set (fast for gating)
final myEntitlementsProvider = FutureProvider<Set<String>>((ref) async {
  final repo = ref.read(billingRepoProvider);
  final ent = await repo.fetchMyEntitlements();
  return ent.map((e) => e.entitlement).toSet();
});

/// Convenience: premium bool (based on active/trialing)
final isPremiumProvider = FutureProvider<bool>((ref) async {
  final sub = await ref.watch(myActiveSubscriptionProvider.future);
  return sub?.isActive ?? false;
});

/// Optional unified state for rendering paywall/billing screens easily.
sealed class BillingState {
  const BillingState();
}

class BillingLoading extends BillingState {
  const BillingLoading();
}

class BillingError extends BillingState {
  final String message;
  const BillingError(this.message);
}

class BillingFree extends BillingState {
  const BillingFree();
}

class BillingActive extends BillingState {
  final ActiveSubscription subscription;
  final Set<String> entitlements;
  const BillingActive(this.subscription, this.entitlements);
}

/// Recommended: watch ONE provider in the UI.
final billingStateProvider = FutureProvider<BillingState>((ref) async {
  try {
    final sub = await ref.watch(myActiveSubscriptionProvider.future);
    final ents = await ref.watch(myEntitlementsProvider.future);

    if (sub == null || !sub.isActive) return const BillingFree();
    return BillingActive(sub, ents);
  } catch (e) {
    return BillingError(e.toString());
  }
});

/// Helper: refresh billing-related data everywhere
void refreshBilling(WidgetRef ref) {
  ref.invalidate(myActiveSubscriptionProvider);
  ref.invalidate(myEntitlementsProvider);
  ref.invalidate(isPremiumProvider);
  ref.invalidate(billingStateProvider);
}
