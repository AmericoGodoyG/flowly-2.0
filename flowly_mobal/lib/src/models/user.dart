class User {
  final String id;
  final String nome;
  final String email;
  final String? tipo;

  const User({
    required this.id,
    required this.nome,
    required this.email,
    this.tipo,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      nome: (json['nome'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      tipo: json['tipo']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'nome': nome,
    'email': email,
    if (tipo != null) 'tipo': tipo,
  };
}
