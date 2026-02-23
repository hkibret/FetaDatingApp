class Message {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String text;
  final DateTime sentAt;

  const Message({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.text,
    required this.sentAt,
  });
}
