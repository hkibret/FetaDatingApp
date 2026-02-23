// lib/features/matches/matches_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../discover/models/profile.dart';
import 'providers/matches_providers.dart';

class MatchesPage extends ConsumerWidget {
  const MatchesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Now AsyncValue<List<Profile>>
    final matchesAsync = ref.watch(matchesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Matches')),
      body: matchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Failed to load matches.\n$e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
        data: (matches) {
          if (matches.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No matches yet.\nLike profiles in Discover to create a match.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: matches.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final p = matches[i];
              return _MatchTile(profile: p);
            },
          );
        },
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  final Profile profile;
  const _MatchTile({required this.profile});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: profile.photoUrl.isNotEmpty
            ? NetworkImage(profile.photoUrl)
            : null,
        onBackgroundImageError: (_, __) {},
        child: profile.photoUrl.isEmpty ? const Icon(Icons.person) : null,
      ),
      title: Text('${profile.name}, ${profile.age}'),
      subtitle: Text(profile.location),
      trailing: FilledButton(
        onPressed: () => context.go('/chat/${profile.id}'),
        child: const Text('Message'),
      ),
      onTap: () => context.go('/profile/${profile.id}'),
    );
  }
}
