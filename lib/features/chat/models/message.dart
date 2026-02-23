// lib/features/messages/chat_message.dart

class ChatMessage {
  final String id;
  final String conversationId;
  final String text;
  final bool fromMe;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.text,
    required this.fromMe,
    required this.createdAt,
  });

  /// Convert to JSON (for local storage if needed)
  Map<String, dynamic> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'text': text,
    'fromMe': fromMe,
    'createdAt': createdAt.toIso8601String(),
  };

  /// Create from Supabase row
  factory ChatMessage.fromSupabase({
    required Map<String, dynamic> row,
    required String myUserId,
  }) {
    return ChatMessage(
      id: row['id'] as String,
      conversationId: row['conversation_id'] as String,
      text: row['body'] as String,
      fromMe: row['sender_id'] == myUserId,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  /// Create from locally stored JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      text: json['text'] as String,
      fromMe: json['fromMe'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
