import 'dart:io';

import 'package:dio/dio.dart';
import 'package:meu_app/src/core/network/api_client.dart';
import 'package:meu_app/src/models/task.dart';
import 'package:meu_app/src/models/task_comment.dart';

class TaskService {
  Future<({Task task, List<TaskComment> comentarios})> obterDetalhesCompletos(
    String tarefaId,
  ) async {
    try {
      final response = await ApiClient.instance.dio.get<Map<String, dynamic>>(
        '/api/tarefas/$tarefaId/detalhes',
      );

      final Map<String, dynamic> data = response.data ?? <String, dynamic>{};
      final Map<String, dynamic> tarefaMap =
          (data['tarefa'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final List<dynamic> comentariosRaw =
          (data['comentarios'] as List<dynamic>?) ?? <dynamic>[];

      return (
        task: Task.fromJson(tarefaMap),
        comentarios: comentariosRaw
            .whereType<Map<String, dynamic>>()
            .map(TaskComment.fromJson)
            .toList(),
      );
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<List<Task>> listarMinhasTarefas() async {
    try {
      final response = await ApiClient.instance.dio.get<List<dynamic>>(
        '/api/tarefas/minhas',
      );
      final data = response.data ?? [];
      return data
          .map((json) => Task.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<List<Task>> listarBacklog() async {
    try {
      final response = await ApiClient.instance.dio.get<List<dynamic>>(
        '/api/tarefas/backlog',
      );
      final data = response.data ?? [];
      return data
          .map((json) => Task.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<Task> atribuirParaMim(String tarefaId) async {
    try {
      final response = await ApiClient.instance.dio.put<Map<String, dynamic>>(
        '/api/tarefas/$tarefaId/atribuir-para-mim',
      );
      final Map<String, dynamic> data = response.data ?? <String, dynamic>{};
      if (data['tarefa'] is Map<String, dynamic>) {
        return Task.fromJson(data['tarefa'] as Map<String, dynamic>);
      }
      return Task.fromJson(data);
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<List<Task>> listarTarefas({
    String? userId,
    String? equipeId,
    String? projetoId,
    bool? apenasPublicas,
  }) async {
    try {
      final response = await ApiClient.instance.dio.get<List<dynamic>>(
        '/api/tarefas',
        queryParameters: <String, dynamic>{
          if (userId != null && userId.isNotEmpty) 'user': userId,
          if (equipeId != null && equipeId.isNotEmpty) 'equipe': equipeId,
        },
      );
      final data = response.data ?? [];
      return data
          .map((json) => Task.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<Task> obterTarefa(String tarefaId) async {
    try {
      final response = await ApiClient.instance.dio.get<Map<String, dynamic>>(
        '/api/tarefas/$tarefaId/detalhes',
      );
      final Map<String, dynamic> data = response.data ?? <String, dynamic>{};
      final Map<String, dynamic> tarefa =
          (data['tarefa'] as Map<String, dynamic>?) ?? data;
      return Task.fromJson(tarefa);
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<Task> criarTarefa({
    String? nome,
    required String descricao,
    String detalhes = '',
    DateTime? dataEntrega,
    String? userId,
    String? equipeId,
    int? tempoEstimado,
    String urgencia = 'baixa',
    String? projetoId,
    DateTime? prazo,
    TaskDifficulty dificuldade = TaskDifficulty.definir,
    TaskPriority prioridade = TaskPriority.definir,
    bool visivelAtodos = false,
  }) async {
    try {
      final String descricaoFinal = descricao.trim().isEmpty
          ? (nome ?? '').trim()
          : descricao;
      final String? dataEntregaIso = (dataEntrega ?? prazo)?.toIso8601String();

      final response = await ApiClient.instance.dio.post<Map<String, dynamic>>(
        '/api/tarefas',
        data: <String, dynamic>{
          'descricao': descricaoFinal,
          'detalhes': detalhes,
          ...?dataEntregaIso == null
              ? null
              : <String, dynamic>{'dataEntrega': dataEntregaIso},
          if (userId != null && userId.isNotEmpty) 'user': userId,
          if (equipeId != null && equipeId.isNotEmpty) 'equipe': equipeId,
          ...?tempoEstimado == null
              ? null
              : <String, dynamic>{'tempoEstimado': tempoEstimado},
          'urgencia': urgencia,
        },
      );
      return Task.fromJson(response.data ?? {});
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<Task> editarTarefa({
    required String tarefaId,
    String? nome,
    required String descricao,
    String detalhes = '',
    DateTime? dataEntrega,
    String? userId,
    String? equipeId,
    int? tempoEstimado,
    String urgencia = 'baixa',
    DateTime? prazo,
    TaskDifficulty dificuldade = TaskDifficulty.definir,
    TaskPriority prioridade = TaskPriority.definir,
    bool visivelAtodos = false,
  }) async {
    try {
      final String descricaoFinal = descricao.trim().isEmpty
          ? (nome ?? '').trim()
          : descricao;
      final String? dataEntregaIso = (dataEntrega ?? prazo)?.toIso8601String();

      final response = await ApiClient.instance.dio.put<Map<String, dynamic>>(
        '/api/tarefas/$tarefaId',
        data: <String, dynamic>{
          'descricao': descricaoFinal,
          'detalhes': detalhes,
          ...?dataEntregaIso == null
              ? null
              : <String, dynamic>{'dataEntrega': dataEntregaIso},
          if (userId != null && userId.isNotEmpty) 'user': userId,
          if (equipeId != null && equipeId.isNotEmpty) 'equipe': equipeId,
          ...?tempoEstimado == null
              ? null
              : <String, dynamic>{'tempoEstimado': tempoEstimado},
          'urgencia': urgencia,
        },
      );
      return Task.fromJson(response.data ?? {});
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<void> excluirTarefa(String tarefaId) async {
    try {
      await ApiClient.instance.dio.delete('/api/tarefas/$tarefaId');
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<void> concluirTarefa(String tarefaId) async {
    try {
      await ApiClient.instance.dio.put(
        '/api/tarefas/$tarefaId/status',
        data: <String, String>{'status': TaskStatus.concluido.value},
      );
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<Task> atualizarStatusTarefa({
    required String tarefaId,
    required TaskStatus status,
  }) async {
    try {
      final response = await ApiClient.instance.dio.put<Map<String, dynamic>>(
        '/api/tarefas/$tarefaId/status',
        data: {'status': status.value},
      );
      final Map<String, dynamic> data = response.data ?? <String, dynamic>{};
      if (data['tarefa'] is Map<String, dynamic>) {
        return Task.fromJson(data['tarefa'] as Map<String, dynamic>);
      }
      return Task.fromJson(data);
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<Task> controlarCronometro({
    required String tarefaId,
    required bool iniciar,
  }) async {
    try {
      final response = await ApiClient.instance.dio.put<Map<String, dynamic>>(
        '/api/tarefas/$tarefaId/cronometro',
        data: {'acao': iniciar ? 'iniciar' : 'pausar'},
      );
      final Map<String, dynamic> data = response.data ?? <String, dynamic>{};
      if (data['tarefa'] is Map<String, dynamic>) {
        return Task.fromJson(data['tarefa'] as Map<String, dynamic>);
      }
      return Task.fromJson(data);
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<TaskComment> adicionarComentario({
    required String tarefaId,
    required String texto,
  }) async {
    try {
      final response = await ApiClient.instance.dio.post<Map<String, dynamic>>(
        '/api/tarefas/$tarefaId/comentarios',
        data: <String, String>{'texto': texto},
      );
      return TaskComment.fromJson(response.data ?? <String, dynamic>{});
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<Task> adicionarSubtarefa({
    required String tarefaId,
    required String descricao,
  }) async {
    try {
      final response = await ApiClient.instance.dio.post<Map<String, dynamic>>(
        '/api/tarefas/$tarefaId/subtarefas',
        data: <String, String>{'descricao': descricao},
      );
      return Task.fromJson(response.data ?? <String, dynamic>{});
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<Task> toggleSubtarefa({
    required String tarefaId,
    required String subId,
  }) async {
    try {
      final response = await ApiClient.instance.dio.put<Map<String, dynamic>>(
        '/api/tarefas/$tarefaId/subtarefas/$subId',
      );
      return Task.fromJson(response.data ?? <String, dynamic>{});
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<void> adicionarAnexo({
    required String tarefaId,
    required File file,
  }) async {
    try {
      final String fileName = file.path.split(Platform.pathSeparator).last;
      final FormData formData = FormData.fromMap(<String, dynamic>{
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      await ApiClient.instance.dio.post<void>(
        '/api/tarefas/$tarefaId/anexos',
        data: formData,
      );
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }
}
