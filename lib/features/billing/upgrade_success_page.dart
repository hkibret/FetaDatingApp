import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'billing_providers.dart';

class UpgradeSuccessPage extends ConsumerStatefulWidget {
  const UpgradeSuccessPage({super.key});

  @override
  ConsumerState<UpgradeSuccessPage> createState() => _UpgradeSuccessPageState();
}

class _UpgradeSuccessPageState extends ConsumerState<UpgradeSuccessPage> {
  @override
  void initState() {
    super.initState();

    // Refresh subscription state after returning from Stripe
    Future.microtask(() {
      ref.invalidate(myActiveSubscriptionProvider);
      ref.invalidate(myEntitlementsProvider);
      ref.invalidate(isPremiumProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final premiumAsync = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Successful')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: premiumAsync.when(
          data: (isPremium) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, size: 56, color: Colors.green),
                const SizedBox(height: 12),
                Text(
                  isPremium
                      ? 'You are now Premium ✅'
                      : 'Payment received. Waiting for confirmation…',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  isPremium
                      ? 'Enjoy your upgraded features!'
                      : 'If this takes more than a minute, tap refresh.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(myActiveSubscriptionProvider);
                    ref.invalidate(myEntitlementsProvider);
                    ref.invalidate(isPremiumProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Refreshing…')),
                    );
                  },
                  child: const Text('Refresh status'),
                ),

                const SizedBox(height: 12),

                OutlinedButton(
                  onPressed: () => context.go('/discover'),
                  child: const Text('Back to app'),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Could not verify subscription.'),
              const SizedBox(height: 8),
              Text('Error: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(myActiveSubscriptionProvider);
                  ref.invalidate(myEntitlementsProvider);
                  ref.invalidate(isPremiumProvider);
                },
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
