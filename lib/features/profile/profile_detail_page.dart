// lib/features/profile/profile_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import './providers/profile_providers.dart';
import './data/profile_model.dart';
import '../discover/providers/likes_providers.dart';

class ProfileDetailPage extends ConsumerWidget {
  final String profileId;

  const ProfileDetailPage({super.key, required this.profileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileByIdProvider(profileId));

    return profileAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(child: Text('Error loading profile: $e')),
      ),
      data: (profile) {
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
            title: Text(profile.name ?? 'Profile'),
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
      },
    );
  }
}

class _ProfileDetailBody extends StatelessWidget {
  final Profile profile;
  final bool isMatched;

  const _ProfileDetailBody({required this.profile, required this.isMatched});

  @override
  Widget build(BuildContext context) {
    final avatar = profile.avatarUrl;

    return ListView(
      children: [
        AspectRatio(
          aspectRatio: 3 / 4,
          child: avatar != null && avatar.isNotEmpty
              ? Image.network(
                  avatar,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade300,
                    child: const Center(child: Icon(Icons.person, size: 72)),
                  ),
                )
              : Container(
                  color: Colors.grey.shade300,
                  child: const Center(child: Icon(Icons.person, size: 72)),
                ),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${profile.name ?? ''}${profile.age != null ? ', ${profile.age}' : ''}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),

              const SizedBox(height: 8),

              if (profile.location != null)
                Text(
                  profile.location!,
                  style: Theme.of(context).textTheme.titleMedium,
                ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                children: [
                  if (profile.gender != null)
                    Chip(label: Text(profile.gender!)),

                  if (profile.interestedIn != null)
                    Chip(label: Text('Interested in ${profile.interestedIn}')),

                  if (isMatched) const Chip(label: Text('Matched')),
                ],
              ),

              const SizedBox(height: 20),

              if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                const Text(
                  'About',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(profile.bio!),
              ],

              const SizedBox(height: 24),

              const Text(
                'Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (profile.bodyType != null)
                    Chip(label: Text('Body: ${profile.bodyType}')),

                  if (profile.heightCm != null)
                    Chip(label: Text('Height: ${profile.heightCm} cm')),

                  if (profile.smoking != null)
                    Chip(label: Text('Smoking: ${profile.smoking}')),

                  if (profile.drinking != null)
                    Chip(label: Text('Drinking: ${profile.drinking}')),

                  if (profile.datingIntent != null)
                    Chip(label: Text('Intent: ${profile.datingIntent}')),

                  if (profile.hasKids != null)
                    Chip(label: Text('Kids: ${profile.hasKids}')),

                  if (profile.religion != null)
                    Chip(label: Text('Religion: ${profile.religion}')),

                  if (profile.education != null)
                    Chip(label: Text('Education: ${profile.education}')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
