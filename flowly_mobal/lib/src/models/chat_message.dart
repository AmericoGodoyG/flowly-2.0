class ChatMessage {
  final String id;
  final String texto;
  final String userId;
  final String userName;
  final DateTime? createdAt;

  const ChatMessage({
    required this.id,
    required this.texto,
    required this.userId,
    required this.userName,
    this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final dynamic user = json['user'];
    final String resolvedUserId = user is Map<String, dynamic>
        ? (user['_id'] ?? '').toString()
        : (json['user'] ?? '').toString();
    final String resolvedUserName = user is Map<String, dynamic>
        ? (user['nome'] ?? '').toString()
        : '';

    return ChatMessage(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      texto: (json['texto'] ?? '').toString(),
      userId: resolvedUserId,
      userName: resolvedUserName,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),
    );
  }
}
