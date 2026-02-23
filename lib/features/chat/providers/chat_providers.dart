import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/storage/hive_service.dart';
import '../../auth/auth_controller.dart';
import '../models/message.dart';

/// State: conversationId -> messages
class ChatController extends Notifier<Map<String, List<ChatMessage>>> {
  SupabaseClient get _sb => Supabase.instance.client;

  @override
  Map<String, List<ChatMessage>> build() {
    // Keep local cache (optional). This makes chat show instantly, then we refresh from Supabase.
    final raw =
        HiveService.getChatsRaw(); // Map<String, List<Map<String, dynamic>>>
    return raw.map((conversationId, list) {
      return MapEntry(
        conversationId,
        list.map(ChatMessage.fromJson).toList(growable: false),
      );
    });
  }

  Future<void> _persist() async {
    final raw = <String, List<Map<String, dynamic>>>{};
    for (final e in state.entries) {
      raw[e.key] = e.value.map((m) => m.toJson()).toList(growable: false);
    }
    await HiveService.saveChatsRaw(raw);
  }

  List<ChatMessage> messagesFor(String conversationId) =>
      state[conversationId] ?? const [];

  /// Pull latest messages for a conversation from Supabase and update state + cache.
  Future<void> refreshConversation(String conversationId) async {
    final myId = ref.read(authControllerProvider).userId;
    if (myId == null) return;

    final rows = await _sb
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    final list = (rows as List)
        .map(
          (r) => ChatMessage.fromSupabase(
            row: Map<String, dynamic>.from(r as Map),
            myUserId: myId,
          ),
        )
        .toList(growable: false);

    state = {...state, conversationId: list};
    await _persist();
  }

  /// Send a message to Supabase (conversation must exist).
  Future<void> send(String conversationId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final myId = ref.read(authControllerProvider).userId;
    if (myId == null) {
      throw Exception('Not logged in.');
    }

    // Insert into Supabase
    final inserted = await _sb
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': myId,
          'body': trimmed,
        })
        .select()
        .single();

    // Update local state immediately (optimistic via returned row)
    final msg = ChatMessage.fromSupabase(
      row: Map<String, dynamic>.from(inserted),
      myUserId: myId,
    );

    final existing = List<ChatMessage>.from(state[conversationId] ?? const []);
    existing.add(msg);

    state = {...state, conversationId: existing};
    await _persist();
  }

  /// Optional: subscribe to realtime updates for one conversation.
  /// Call this from ChatPage init, store subscription somewhere, and dispose when leaving.
  Stream<List<ChatMessage>> streamConversation(String conversationId) {
    final myId = ref.read(authControllerProvider).userId;

    if (myId == null) {
      return const Stream.empty();
    }

    return _sb
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map(
          (rows) => rows
              .map(
                (r) => ChatMessage.fromSupabase(
                  row: Map<String, dynamic>.from(r),
                  myUserId: myId,
                ),
              )
              .toList(growable: false),
        );
  }

  Future<void> clearAll() async {
    state = <String, List<ChatMessage>>{};
    await HiveService.clearChats();
  }
}

final chatControllerProvider =
    NotifierProvider<ChatController, Map<String, List<ChatMessage>>>(
      ChatController.new,
    );

/// Local cached messages for a conversation (from state)
final chatMessagesProvider = Provider.family<List<ChatMessage>, String>((
  ref,
  conversationId,
) {
  final map = ref.watch(chatControllerProvider);
  return map[conversationId] ?? const [];
});

/// Realtime stream provider (optional usage in ChatPage)
final chatStreamProvider = StreamProvider.family<List<ChatMessage>, String>((
  ref,
  conversationId,
) {
  final controller = ref.read(chatControllerProvider.notifier);
  return controller.streamConversation(conversationId);
});
