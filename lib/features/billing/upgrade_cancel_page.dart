import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UpgradeCancelPage extends StatelessWidget {
  const UpgradeCancelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Cancelled')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cancel, size: 60, color: Colors.redAccent),

              const SizedBox(height: 16),

              const Text(
                'Checkout Cancelled',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text(
                'No payment was made. You can try upgrading again anytime.',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () => context.go('/billing'),
                child: const Text('Try Again'),
              ),

              const SizedBox(height: 10),

              TextButton(
                onPressed: () => context.go('/discover'),
                child: const Text('Back to App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
