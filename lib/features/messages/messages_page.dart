import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/message_providers.dart';

class MessagesPage extends ConsumerWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: ListView.separated(
        itemCount: conversations.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final c = conversations[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(c.otherUserPhoto),
            ),
            title: Text(c.otherUserName),
            subtitle: Text(
              c.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => context.push('/chat/${c.otherUserId}'),
          );
        },
      ),
    );
  }
}
