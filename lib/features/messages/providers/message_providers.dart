import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/message.dart';
import '../models/conversation.dart';

const currentUserId = "me"; // mock logged-in user

final conversationsProvider = Provider<List<Conversation>>((ref) {
  final now = DateTime.now();
  return [
    Conversation(
      otherUserId: "p1",
      otherUserName: "Amina",
      otherUserPhoto: "https://picsum.photos/seed/p1/200",
      lastMessage: "Hey, how are you?",
      lastMessageAt: now.subtract(const Duration(minutes: 5)),
    ),
    Conversation(
      otherUserId: "p3",
      otherUserName: "Liya",
      otherUserPhoto: "https://picsum.photos/seed/p3/200",
      lastMessage: "Nice to meet you!",
      lastMessageAt: now.subtract(const Duration(hours: 2)),
    ),
  ];
});

final messagesProvider =
    NotifierProvider.family<MessagesNotifier, List<Message>, String>(
      MessagesNotifier.new,
    );

class MessagesNotifier extends Notifier<List<Message>> {
  MessagesNotifier(this.otherUserId);
  final String otherUserId;

  @override
  List<Message> build() {
    return [
      Message(
        id: "m1",
        fromUserId: otherUserId,
        toUserId: currentUserId,
        text: "Hi!",
        sentAt: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      Message(
        id: "m2",
        fromUserId: currentUserId,
        toUserId: otherUserId,
        text: "Hello 👋",
        sentAt: DateTime.now().subtract(const Duration(minutes: 9)),
      ),
    ];
  }

  void send(String text) {
    state = [
      ...state,
      Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fromUserId: currentUserId,
        toUserId: otherUserId,
        text: text,
        sentAt: DateTime.now(),
      ),
    ];
  }
}
