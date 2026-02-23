class Conversation {
  final String otherUserId;
  final String otherUserName;
  final String otherUserPhoto;
  final String lastMessage;
  final DateTime lastMessageAt;

  const Conversation({
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserPhoto,
    required this.lastMessage,
    required this.lastMessageAt,
  });
}
