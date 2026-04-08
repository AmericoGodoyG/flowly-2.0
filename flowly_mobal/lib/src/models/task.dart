enum TaskDifficulty {
  facil('facil', 'Fácil'),
  media('media', 'Média'),
  dificil('dificil', 'Difícil'),
  definir('definir', 'Definir');

  const TaskDifficulty(this.value, this.label);

  final String value;
  final String label;

  static TaskDifficulty fromString(String? value) {
    return TaskDifficulty.values.firstWhere(
      (d) => d.value == value,
      orElse: () => TaskDifficulty.definir,
    );
  }
}

enum TaskPriority {
  alta('alta', 'Alta'),
  media('media', 'Média'),
  baixa('baixa', 'Baixa'),
  definir('definir', 'Definir');

  const TaskPriority(this.value, this.label);

  final String value;
  final String label;

  static TaskPriority fromString(String? value) {
    return TaskPriority.values.firstWhere(
      (p) => p.value == value,
      orElse: () => TaskPriority.definir,
    );
  }
}

enum TaskStatus {
  pendente('pendente', 'Pendente'),
  emAndamento('em_andamento', 'Em Andamento'),
  concluido('concluido', 'Concluído');

  const TaskStatus(this.value, this.label);

  final String value;
  final String label;

  static TaskStatus fromString(String? value) {
    return TaskStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => TaskStatus.pendente,
    );
  }
}

class Task {
  final String id;
  final String nome;
  final String descricao;
  final DateTime? prazo;
  final TaskDifficulty dificuldade;
  final TaskPriority prioridade;
  final String? associado;
  final TaskStatus status;
  final String projetoId;
  final bool visivelAtodos;
  final DateTime? criadoEm;
  final int? tempoEstimado;
  final int tempoGasto;
  final bool cronometroAtivo;
  final DateTime? ultimaAtualizacaoCronometro;
  final bool tempoExcedido;
  final String urgencia;
  final String? equipeNome;
  final List<TaskSubtask> subtarefas;
  final List<TaskAttachment> anexos;

  const Task({
    required this.id,
    required this.nome,
    required this.descricao,
    this.prazo,
    this.dificuldade = TaskDifficulty.definir,
    this.prioridade = TaskPriority.definir,
    this.associado,
    this.status = TaskStatus.pendente,
    required this.projetoId,
    this.visivelAtodos = false,
    this.criadoEm,
    this.tempoEstimado,
    this.tempoGasto = 0,
    this.cronometroAtivo = false,
    this.ultimaAtualizacaoCronometro,
    this.tempoExcedido = false,
    this.urgencia = 'baixa',
    this.equipeNome,
    this.subtarefas = const <TaskSubtask>[],
    this.anexos = const <TaskAttachment>[],
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    final dynamic projetoRaw = json['projeto'] ?? json['projetoId'];
    final String projetoId = projetoRaw is Map<String, dynamic>
        ? (projetoRaw['_id'] ?? '').toString()
        : (projetoRaw ?? '').toString();
    final String? prioridadeOuUrgencia =
        (json['prioridade'] ?? json['urgencia'])?.toString();

    return Task(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      nome: (json['nome'] ?? json['descricao'] ?? '').toString(),
      descricao: (json['descricao'] ?? '').toString(),
      prazo: json['prazo'] != null
          ? DateTime.tryParse(json['prazo'].toString())
          : (json['dataEntrega'] != null
                ? DateTime.tryParse(json['dataEntrega'].toString())
                : null),
      dificuldade: TaskDifficulty.fromString(json['dificuldade'] as String?),
      prioridade: TaskPriority.fromString(prioridadeOuUrgencia),
      associado: json['associado'] as String?,
      status: TaskStatus.fromString(json['status'] as String?),
      projetoId: projetoId,
      visivelAtodos: json['visivelAtodos'] == true,
      criadoEm: json['criadoEm'] != null
          ? DateTime.tryParse(json['criadoEm'].toString())
          : (json['createdAt'] != null
                ? DateTime.tryParse(json['createdAt'].toString())
                : null),
      tempoEstimado: (json['tempoEstimado'] is num)
          ? (json['tempoEstimado'] as num).toInt()
          : int.tryParse((json['tempoEstimado'] ?? '').toString()),
      tempoGasto: (json['tempoGasto'] is num)
          ? (json['tempoGasto'] as num).toInt()
          : int.tryParse((json['tempoGasto'] ?? '').toString()) ?? 0,
      cronometroAtivo: json['cronometroAtivo'] == true,
      ultimaAtualizacaoCronometro: json['ultimaAtualizacaoCronometro'] != null
          ? DateTime.tryParse(json['ultimaAtualizacaoCronometro'].toString())
          : null,
      tempoExcedido: json['tempoExcedido'] == true,
      urgencia: (json['urgencia'] ?? 'baixa').toString(),
      equipeNome: json['equipe'] is Map<String, dynamic>
          ? (json['equipe']['nome'] ?? '').toString()
          : null,
      subtarefas: (json['subtarefas'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(TaskSubtask.fromJson)
          .toList(),
      anexos: (json['anexos'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(TaskAttachment.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'nome': nome,
    'descricao': descricao,
    'prazo': prazo?.toIso8601String(),
    'dificuldade': dificuldade.value,
    'prioridade': prioridade.value,
    'associado': associado,
    'status': status.value,
    'projeto': projetoId,
    'visivelAtodos': visivelAtodos,
    'criadoEm': criadoEm?.toIso8601String(),
    'tempoEstimado': tempoEstimado,
    'tempoGasto': tempoGasto,
    'cronometroAtivo': cronometroAtivo,
    'ultimaAtualizacaoCronometro': ultimaAtualizacaoCronometro
        ?.toIso8601String(),
    'tempoExcedido': tempoExcedido,
    'urgencia': urgencia,
    'equipeNome': equipeNome,
    'subtarefas': subtarefas.map((TaskSubtask item) => item.toJson()).toList(),
    'anexos': anexos.map((TaskAttachment item) => item.toJson()).toList(),
  };

  Task copyWith({
    String? id,
    String? nome,
    String? descricao,
    DateTime? prazo,
    TaskDifficulty? dificuldade,
    TaskPriority? prioridade,
    String? associado,
    TaskStatus? status,
    String? projetoId,
    bool? visivelAtodos,
    DateTime? criadoEm,
    int? tempoEstimado,
    int? tempoGasto,
    bool? cronometroAtivo,
    DateTime? ultimaAtualizacaoCronometro,
    bool? tempoExcedido,
    String? urgencia,
    String? equipeNome,
    List<TaskSubtask>? subtarefas,
    List<TaskAttachment>? anexos,
  }) {
    return Task(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      prazo: prazo ?? this.prazo,
      dificuldade: dificuldade ?? this.dificuldade,
      prioridade: prioridade ?? this.prioridade,
      associado: associado ?? this.associado,
      status: status ?? this.status,
      projetoId: projetoId ?? this.projetoId,
      visivelAtodos: visivelAtodos ?? this.visivelAtodos,
      criadoEm: criadoEm ?? this.criadoEm,
      tempoEstimado: tempoEstimado ?? this.tempoEstimado,
      tempoGasto: tempoGasto ?? this.tempoGasto,
      cronometroAtivo: cronometroAtivo ?? this.cronometroAtivo,
      ultimaAtualizacaoCronometro:
          ultimaAtualizacaoCronometro ?? this.ultimaAtualizacaoCronometro,
      tempoExcedido: tempoExcedido ?? this.tempoExcedido,
      urgencia: urgencia ?? this.urgencia,
      equipeNome: equipeNome ?? this.equipeNome,
      subtarefas: subtarefas ?? this.subtarefas,
      anexos: anexos ?? this.anexos,
    );
  }
}

class TaskSubtask {
  final String id;
  final String descricao;
  final bool concluida;

  const TaskSubtask({
    required this.id,
    required this.descricao,
    required this.concluida,
  });

  factory TaskSubtask.fromJson(Map<String, dynamic> json) {
    return TaskSubtask(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      descricao: (json['descricao'] ?? '').toString(),
      concluida: json['concluida'] == true,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    '_id': id,
    'descricao': descricao,
    'concluida': concluida,
  };
}

class TaskAttachment {
  final String url;
  final String nomeOriginal;
  final String? mimetype;
  final int? size;

  const TaskAttachment({
    required this.url,
    required this.nomeOriginal,
    this.mimetype,
    this.size,
  });

  factory TaskAttachment.fromJson(Map<String, dynamic> json) {
    return TaskAttachment(
      url: (json['url'] ?? '').toString(),
      nomeOriginal: (json['nomeOriginal'] ?? json['nome'] ?? '').toString(),
      mimetype: json['mimetype']?.toString(),
      size:
          (json['size'] as num?)?.toInt() ??
          int.tryParse((json['tamanho'] ?? '').toString()),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'url': url,
    'nomeOriginal': nomeOriginal,
    'mimetype': mimetype,
    'size': size,
  };
}
