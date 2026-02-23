// lib/features/profile/profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('My Profile', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),

          // User info card
          Card(
            elevation: 1.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    child: Icon(Icons.person, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Signed in as',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          auth.email ?? 'No email',
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (auth.userId != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'UID: ${auth.userId}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text('Activity', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),

          ListTile(
            leading: const Icon(Icons.favorite_outline),
            title: const Text('Likes & Matches'),
            onTap: () => context.go('/matches'),
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text('Messages'),
            onTap: () => context.go('/messages'),
          ),

          const SizedBox(height: 32),

          FilledButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              // Router redirect will send them to /login once auth state updates
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
