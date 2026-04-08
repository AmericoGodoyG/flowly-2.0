class Project {
  final String id;
  final String nome;
  final String descricao;
  final String equipeId;
  final DateTime? criadoEm;

  const Project({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.equipeId,
    this.criadoEm,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    final dynamic equipeRaw = json['equipe'] ?? json['equipeId'];
    final String equipeId = equipeRaw is Map<String, dynamic>
        ? (equipeRaw['_id'] ?? '').toString()
        : (equipeRaw ?? '').toString();

    return Project(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      nome: (json['nome'] ?? '').toString(),
      descricao: (json['descricao'] ?? '').toString(),
      equipeId: equipeId,
      criadoEm: json['criadoEm'] != null ? DateTime.tryParse(json['criadoEm'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'nome': nome,
    'descricao': descricao,
    'equipe': equipeId,
    'criadoEm': criadoEm?.toIso8601String(),
  };
}
