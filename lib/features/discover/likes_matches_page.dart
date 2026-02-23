import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/likes_providers.dart';

class LikesMatchesPage extends ConsumerWidget {
  const LikesMatchesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedAsync = ref.watch(likedProfilesProvider);
    final matchedAsync = ref.watch(matchedProfilesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Likes & Matches')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Text(
            'Matches',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),

          matchedAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Failed to load matches: ${e.toString()}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
            data: (matched) {
              if (matched.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('No matches yet. Keep liking profiles.'),
                );
              }

              return Column(
                children: [
                  for (final p in matched)
                    Card(
                      child: ListTile(
                        leading: _Avatar(url: p.photoUrl),
                        title: Text('${p.name}, ${p.age}'),
                        subtitle: Text(p.location),
                        trailing: FilledButton(
                          onPressed: () => context.go('/chat/${p.id}'),
                          child: const Text('Message'),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          const Text(
            'Likes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),

          likedAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Failed to load likes: ${e.toString()}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
            data: (liked) {
              if (liked.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('You have not liked anyone yet.'),
                );
              }

              return Column(
                children: [
                  for (final p in liked)
                    Card(
                      child: ListTile(
                        leading: _Avatar(url: p.photoUrl),
                        title: Text('${p.name}, ${p.age}'),
                        subtitle: Text(p.location),
                        onTap: () => context.go('/profile/${p.id}'),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String url;
  const _Avatar({required this.url});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.grey.shade300,
      backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
      child: url.isEmpty ? const Icon(Icons.person) : null,
      onBackgroundImageError: (_, __) {},
    );
  }
}
