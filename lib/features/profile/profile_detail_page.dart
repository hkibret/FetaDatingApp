// lib/features/profile/profile_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../discover/models/profile.dart';
import '../discover/providers/discover_providers.dart';
import '../discover/providers/likes_providers.dart';

class ProfileDetailPage extends ConsumerWidget {
  final String profileId;
  const ProfileDetailPage({super.key, required this.profileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // profileByIdProvider returns Profile?
    final profile = ref.watch(profileByIdProvider(profileId));

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Profile not found.')),
      );
    }

    final isLiked = ref.watch(isLikedProvider(profile.id));
    final isMatched = ref.watch(isMatchedProvider(profile.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(profile.name),
        actions: [
          IconButton(
            tooltip: isLiked ? 'Unlike' : 'Like',
            icon: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? Colors.red : null,
            ),
            onPressed: () async {
              await ref.read(likeActionsProvider).toggle(profile.id);
            },
          ),
        ],
      ),
      body: _ProfileDetailBody(profile: profile, isMatched: isMatched),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.favorite),
                label: Text(isLiked ? 'Liked' : 'Like'),
                onPressed: () async {
                  await ref.read(likeActionsProvider).toggle(profile.id);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text(isMatched ? 'Message' : 'Match to message'),
                onPressed: isMatched
                    ? () => context.go('/chat/${profile.id}')
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileDetailBody extends StatelessWidget {
  final Profile profile;
  final bool isMatched;

  const _ProfileDetailBody({required this.profile, required this.isMatched});

  @override
  Widget build(BuildContext context) {
    final distanceLabel = profile.distanceMiles == null
        ? 'Distance unknown'
        : '${profile.distanceMiles!.toStringAsFixed(1)} mi';

    return ListView(
      children: [
        AspectRatio(
          aspectRatio: 3 / 4,
          child: Image.network(
            profile.photoUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade300,
              child: const Center(child: Icon(Icons.person, size: 72)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${profile.name}, ${profile.age}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '${profile.location} • $distanceLabel',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Chip(
                    label: Text(profile.onlineNow ? 'Online now' : 'Offline'),
                  ),
                  const SizedBox(width: 8),
                  if (isMatched) const Chip(label: Text('Matched')),
                ],
              ),
              const SizedBox(height: 16),

              const Text(
                'About',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Next step: load bio/interests/photos from Supabase profiles table.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
