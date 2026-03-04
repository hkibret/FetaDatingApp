import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../billing/billing_providers.dart';

class UpgradeSuccessPage extends ConsumerStatefulWidget {
  const UpgradeSuccessPage({super.key});

  @override
  ConsumerState<UpgradeSuccessPage> createState() => _UpgradeSuccessPageState();
}

class _UpgradeSuccessPageState extends ConsumerState<UpgradeSuccessPage> {
  @override
  void initState() {
    super.initState();

    // Stripe redirects here after checkout.
    // Webhook may take a few seconds, so refresh immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(myActiveSubscriptionProvider);
      ref.invalidate(myEntitlementsProvider);
      ref.invalidate(isPremiumProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final premiumAsync = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Success')),
      body: Center(
        child: premiumAsync.when(
          data: (isPremium) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isPremium ? 'Premium Activated ✅' : 'Processing…'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(myActiveSubscriptionProvider);
                  ref.invalidate(myEntitlementsProvider);
                  ref.invalidate(isPremiumProvider);
                },
                child: const Text('Refresh'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back'),
              ),
            ],
          ),
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
        ),
      ),
    );
  }
}
