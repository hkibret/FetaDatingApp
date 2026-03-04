import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'billing_providers.dart';
import 'billing_repo.dart';
import 'billing_service.dart';

class UpgradePage extends ConsumerWidget {
  const UpgradePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremiumAsync = ref.watch(isPremiumProvider);
    final subAsync = ref.watch(myActiveSubscriptionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          isPremiumAsync.when(
            data: (isPremium) => Text(
              isPremium ? 'Status: Premium ✅' : 'Status: Free',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            loading: () => const Text('Checking subscription...'),
            error: (e, _) => Text('Error: $e'),
          ),
          const SizedBox(height: 12),

          subAsync.when(
            data: (sub) => sub == null
                ? const Text('No active subscription.')
                : Text(
                    'Plan: ${sub.planId} • Provider: ${sub.provider} • Cancel at period end: ${sub.cancelAtPeriodEnd}',
                  ),
            loading: () => const SizedBox.shrink(),
            error: (e, _) => Text('Error: $e'),
          ),

          const Divider(height: 32),

          Text('Gold', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _BuyButton(priceKey: 'gold_1m', label: 'Gold • 1 month'),
          _BuyButton(priceKey: 'gold_3m', label: 'Gold • 3 months (Popular)'),
          _BuyButton(priceKey: 'gold_12m', label: 'Gold • 12 months'),

          const SizedBox(height: 24),
          Text('Platinum', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _BuyButton(priceKey: 'platinum_1m', label: 'Platinum • 1 month'),
          _BuyButton(
            priceKey: 'platinum_3m',
            label: 'Platinum • 3 months (Popular)',
          ),
          _BuyButton(priceKey: 'platinum_12m', label: 'Platinum • 12 months'),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: () async {
              // Refresh entitlements/subscription after returning from Stripe
              ref.invalidate(myActiveSubscriptionProvider);
              ref.invalidate(myEntitlementsProvider);
              ref.invalidate(isPremiumProvider);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshed subscription status')),
              );
            },
            child: const Text('I already paid — Refresh status'),
          ),

          const SizedBox(height: 12),

          // Optional: only works if you create stripe-create-portal function
          OutlinedButton(
            onPressed: () async {
              final repo = ref.read(billingRepoProvider);
              final service = BillingService();
              final url = await repo.createPortalUrl();
              await service.openExternalUrl(url);
            },
            child: const Text('Manage subscription'),
          ),
        ],
      ),
    );
  }
}

class _BuyButton extends ConsumerWidget {
  const _BuyButton({required this.priceKey, required this.label});

  final String priceKey;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton(
        onPressed: () async {
          try {
            final repo = ref.read(billingRepoProvider);
            final service = BillingService();

            final url = await repo.createCheckoutUrl(priceKey: priceKey);
            await service.openExternalUrl(url);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Opened Stripe checkout. Complete payment then refresh.',
                ),
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Checkout failed: $e')));
          }
        },
        child: Text(label),
      ),
    );
  }
}
