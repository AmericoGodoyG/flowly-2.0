class TaskComment {
  final String id;
  final String texto;
  final String userName;
  final DateTime? createdAt;

  const TaskComment({
    required this.id,
    required this.texto,
    required this.userName,
    this.createdAt,
  });

  factory TaskComment.fromJson(Map<String, dynamic> json) {
    final dynamic user = json['user'];
    final String nomeUsuario = user is Map<String, dynamic>
        ? (user['nome'] ?? '').toString()
        : '';

    return TaskComment(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      texto: (json['texto'] ?? '').toString(),
      userName: nomeUsuario,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),
    );
  }
}
