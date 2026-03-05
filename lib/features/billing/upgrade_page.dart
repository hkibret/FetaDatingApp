import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'billing_providers.dart';
import 'billing_repo.dart';
import 'billing_service.dart';

class UpgradePage extends ConsumerWidget {
  const UpgradePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(billingRepoProvider);
    final service = BillingService();

    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Gold'),
          const SizedBox(height: 8),
          _buy(context, repo, service, 'gold_1m', 'Gold • 1 month'),
          _buy(context, repo, service, 'gold_3m', 'Gold • 3 months (Popular)'),
          _buy(context, repo, service, 'gold_12m', 'Gold • 12 months'),

          const SizedBox(height: 20),
          const Text('Platinum'),
          const SizedBox(height: 8),
          _buy(context, repo, service, 'platinum_1m', 'Platinum • 1 month'),
          _buy(
            context,
            repo,
            service,
            'platinum_3m',
            'Platinum • 3 months (Popular)',
          ),
          _buy(context, repo, service, 'platinum_12m', 'Platinum • 12 months'),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {
              ref.invalidate(myActiveSubscriptionProvider);
              ref.invalidate(myEntitlementsProvider);
              ref.invalidate(isPremiumProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshed subscription status')),
              );
            },
            child: const Text('Refresh status'),
          ),
        ],
      ),
    );
  }

  Widget _buy(
    BuildContext context,
    BillingRepo repo,
    BillingService service,
    String priceKey,
    String label,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton(
        onPressed: () async {
          try {
            final url = await repo.createCheckoutUrl(priceKey: priceKey);
            await service.openExternalUrl(url);
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
