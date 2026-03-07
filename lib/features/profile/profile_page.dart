// lib/features/profile/profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import 'providers/profile_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final profileAsync = ref.watch(myProfileProvider);

    return SafeArea(
      child: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'My Profile',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Edit profile',
                  icon: const Icon(Icons.edit),
                  onPressed: () => context.push('/profile/edit'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Could not load profile: $e',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => ref.invalidate(myProfileProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
        data: (profile) {
          final avatarUrl = profile?.avatarUrl;
          final displayName =
              (profile?.name != null && profile!.name!.trim().isNotEmpty)
              ? profile.name!.trim()
              : 'No name yet';

          final subtitleParts = <String>[
            if (profile?.age != null) '${profile!.age}',
            if (profile?.location != null &&
                profile!.location!.trim().isNotEmpty)
              profile.location!.trim(),
          ];

          final aboutText =
              (profile?.bio != null && profile!.bio!.trim().isNotEmpty)
              ? profile.bio!.trim()
              : 'No bio added yet.';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'My Profile',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit profile',
                    icon: const Icon(Icons.edit),
                    onPressed: () => context.push('/profile/edit'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (avatarUrl != null && avatarUrl.isNotEmpty)
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          child: ClipOval(
                            child: Image.network(
                              avatarUrl,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.person, size: 32),
                            ),
                          ),
                        )
                      else
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
                              displayName,
                              style: Theme.of(context).textTheme.titleLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (subtitleParts.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                subtitleParts.join(' • '),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              auth.email ?? 'No email',
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (auth.userId != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'UID: ${auth.userId}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey),
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

              const SizedBox(height: 16),

              Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(aboutText),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (profile?.gender != null &&
                              profile!.gender!.trim().isNotEmpty)
                            Chip(label: Text(profile.gender!)),
                          if (profile?.interestedIn != null &&
                              profile!.interestedIn!.trim().isNotEmpty)
                            Chip(
                              label: Text(
                                'Interested in ${profile.interestedIn}',
                              ),
                            ),
                          if (profile?.datingIntent != null &&
                              profile!.datingIntent!.trim().isNotEmpty)
                            Chip(
                              label: Text('Intent: ${profile.datingIntent}'),
                            ),
                          if (profile?.religion != null &&
                              profile!.religion!.trim().isNotEmpty)
                            Chip(label: Text(profile.religion!)),
                          if (profile?.education != null &&
                              profile!.education!.trim().isNotEmpty)
                            Chip(label: Text(profile.education!)),
                        ],
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

              const SizedBox(height: 24),

              Text(
                'Membership',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),

              ListTile(
                leading: const Icon(Icons.credit_card),
                title: const Text('Billing'),
                subtitle: const Text('Upgrade or manage your plan'),
                onTap: () => context.push('/billing'),
              ),

              const SizedBox(height: 32),

              FilledButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
