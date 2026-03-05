import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../billing/entitlements_gate.dart';
import 'providers/message_providers.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String otherUserId;

  const ChatPage({super.key, required this.otherUserId});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider(widget.otherUserId));

    return FutureBuilder<bool>(
      future: EntitlementsGate.has(ref, 'unlock_messages'),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final canMessage = snap.data ?? false;

        return Scaffold(
          appBar: AppBar(title: const Text("Chat")),
          body: Column(
            children: [
              Expanded(
                child: messages.isEmpty
                    ? const Center(child: Text("No messages yet"))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: messages.length,
                        itemBuilder: (_, i) {
                          final m = messages[i];
                          final isMe = m.fromUserId == currentUserId;

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.blue
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                m.text,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              /// 🚫 If user NOT premium → show upgrade banner
              if (!canMessage)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.amber.shade50,
                  child: Column(
                    children: [
                      const Text(
                        "Upgrade to send messages",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => context.push('/billing'),
                        child: const Text("Upgrade Now"),
                      ),
                    ],
                  ),
                )
              /// ✅ If premium → show message input
              else
                SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText: "Type a message",
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () {
                          if (controller.text.trim().isEmpty) return;

                          ref
                              .read(
                                messagesProvider(widget.otherUserId).notifier,
                              )
                              .send(controller.text.trim());

                          controller.clear();
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
