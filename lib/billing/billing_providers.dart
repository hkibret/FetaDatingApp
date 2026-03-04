import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'billing_repo.dart';
import 'billing_models.dart';

final billingRepoProvider = Provider<BillingRepo>((ref) {
  return BillingRepo(Supabase.instance.client);
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

/// Convenience: premium bool
final isPremiumProvider = FutureProvider<bool>((ref) async {
  final sub = await ref.watch(myActiveSubscriptionProvider.future);
  return sub?.isActive ?? false;
});
