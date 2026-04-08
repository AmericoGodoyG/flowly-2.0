import 'package:meu_app/src/core/network/api_client.dart';
import 'package:meu_app/src/models/team.dart';
import 'package:meu_app/src/models/user.dart';

class TeamService {
  Future<List<Team>> listarEquipes() async {
    try {
      final response = await ApiClient.instance.dio.get<List<dynamic>>(
        '/api/equipes',
      );
      final List<dynamic> rawList = response.data ?? <dynamic>[];
      return rawList
          .whereType<Map<String, dynamic>>()
          .map((Map<String, dynamic> item) => Team.fromJson(item))
          .toList();
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<Team> obterEquipe(String equipeId) async {
    try {
      final response = await ApiClient.instance.dio.get<Map<String, dynamic>>(
        '/api/equipes/$equipeId',
      );
      return Team.fromJson(response.data ?? {});
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<Team> criarEquipe({
    required String nome,
    List<String> membros = const <String>[],
  }) async {
    try {
      final response = await ApiClient.instance.dio.post<Map<String, dynamic>>(
        '/api/equipes',
        data: {'nome': nome, 'membros': membros},
      );
      return Team.fromJson(response.data ?? {});
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<Team> editarEquipe({
    required String equipeId,
    required String nome,
    List<String> membros = const <String>[],
  }) async {
    try {
      final response = await ApiClient.instance.dio.put<Map<String, dynamic>>(
        '/api/equipes/$equipeId',
        data: {'nome': nome, 'membros': membros},
      );
      return Team.fromJson(response.data ?? {});
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<void> excluirEquipe(String equipeId) async {
    try {
      await ApiClient.instance.dio.delete('/api/equipes/$equipeId');
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<List<Team>> listarMinhasEquipes() async {
    try {
      final response = await ApiClient.instance.dio.get<List<dynamic>>(
        '/api/equipes/minhas',
      );
      final List<dynamic> rawList = response.data ?? <dynamic>[];
      return rawList
          .whereType<Map<String, dynamic>>()
          .map((Map<String, dynamic> item) => Team.fromJson(item))
          .toList();
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<Team?> obterEquipePorCodigo(String codigo) async {
    try {
      final response = await ApiClient.instance.dio.get<Map<String, dynamic>>(
        '/api/equipes/by-code',
        queryParameters: <String, String>{'code': codigo},
      );
      final Map<String, dynamic>? data = response.data;
      return data == null ? null : Team.fromJson(data);
    } catch (_) {
      // Fallback: buscar em todas as equipes
      final List<Team> all = await listarEquipes();
      for (final Team team in all) {
        if (team.code.toLowerCase() == codigo.toLowerCase()) {
          return team;
        }
      }
      return null;
    }
  }

  Future<void> entrarNaEquipe(String equipeId) async {
    try {
      await ApiClient.instance.dio.post('/api/equipes/$equipeId/join');
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<List<User>> listarUsuarios() async {
    try {
      final response = await ApiClient.instance.dio.get<List<dynamic>>(
        '/api/users',
      );
      final List<dynamic> rawList = response.data ?? <dynamic>[];
      return rawList
          .whereType<Map<String, dynamic>>()
          .map((Map<String, dynamic> item) => User.fromJson(item))
          .toList();
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<List<TeamMember>> obterMembrosEquipe(String equipeId) async {
    try {
      final response = await ApiClient.instance.dio.get<List<dynamic>>(
        '/api/equipes/$equipeId/membros',
      );
      final data = response.data ?? [];
      return data
          .map((json) => TeamMember.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw ApiClient.mapError(error);
    }
  }
}
