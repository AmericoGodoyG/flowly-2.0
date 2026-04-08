import 'package:meu_app/src/core/network/api_client.dart';
import 'package:meu_app/src/models/project.dart';

class ProjectService {
  Future<List<Project>> listarProjetos(String equipeId) async {
    try {
      final response = await ApiClient.instance.dio.get<List<dynamic>>(
        '/api/projetos',
        queryParameters: {'equipe': equipeId},
      );
      final data = response.data ?? [];
      return data
          .map((json) => Project.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<Project> obterProjeto(String projetoId) async {
    try {
      final response = await ApiClient.instance.dio.get<Map<String, dynamic>>(
        '/api/projetos/$projetoId',
      );
      return Project.fromJson(response.data ?? {});
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<Project> criarProjeto({
    required String nome,
    required String descricao,
    required String equipeId,
  }) async {
    try {
      final response = await ApiClient.instance.dio.post<Map<String, dynamic>>(
        '/api/projetos',
        data: {
          'nome': nome,
          'descricao': descricao,
          'equipe': equipeId,
        },
      );
      return Project.fromJson(response.data ?? {});
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<Project> editarProjeto({
    required String projetoId,
    required String nome,
    required String descricao,
    required String equipeId,
  }) async {
    try {
      final response = await ApiClient.instance.dio.put<Map<String, dynamic>>(
        '/api/projetos/$projetoId',
        data: {
          'nome': nome,
          'descricao': descricao,
          'equipe': equipeId,
        },
      );
      return Project.fromJson(response.data ?? {});
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<void> excluirProjeto(String projetoId) async {
    try {
      await ApiClient.instance.dio.delete('/api/projetos/$projetoId');
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }
}
