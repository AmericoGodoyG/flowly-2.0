import 'package:meu_app/src/core/network/api_client.dart';
import 'package:meu_app/src/models/auth_result.dart';

class FaceService {
  Future<AuthResult> enrollWithSession({
    required String faceSessionToken,
    required String imageBase64,
  }) async {
    return _postFaceAuth(
      '/api/face/enroll',
      faceSessionToken: faceSessionToken,
      imageBase64: imageBase64,
      successMessage: 'Verificação facial cadastrada com sucesso!',
    );
  }

  Future<AuthResult> verifyWithSession({
    required String faceSessionToken,
    required String imageBase64,
  }) async {
    return _postFaceAuth(
      '/api/face/verify',
      faceSessionToken: faceSessionToken,
      imageBase64: imageBase64,
      successMessage: 'Verificação facial concluída!',
    );
  }

  Future<AuthResult> skipEnrollment({
    required String faceSessionToken,
  }) async {
    return _postFaceAuth(
      '/api/face/skip-enrollment',
      faceSessionToken: faceSessionToken,
      successMessage: 'Cadastro facial ignorado.',
    );
  }

  Future<Map<String, dynamic>> getStatus() async {
    final response = await ApiClient.instance.dio.get<Map<String, dynamic>>(
      '/api/face/status',
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<AuthResult> enrollFromProfile({
    required String imageBase64,
  }) async {
    try {
      await ApiClient.instance.dio.post<Map<String, dynamic>>(
        '/api/face/enroll-profile',
        data: <String, String>{'imageBase64': imageBase64},
      );
      return const AuthResult(
        success: true,
        message: 'Verificação facial cadastrada com sucesso!',
      );
    } catch (error) {
      return AuthResult(
        success: false,
        message: ApiClient.mapError(error).message,
      );
    }
  }

  Future<AuthResult> _postFaceAuth(
    String endpoint, {
    required String faceSessionToken,
    String? imageBase64,
    required String successMessage,
  }) async {
    try {
      final Map<String, String> payload = <String, String>{
        'faceSessionToken': faceSessionToken,
      };
      if (imageBase64 != null) {
        payload['imageBase64'] = imageBase64;
      }

      final response = await ApiClient.instance.dio.post<Map<String, dynamic>>(
        endpoint,
        data: payload,
      );

      final Map<String, dynamic> data = response.data ?? <String, dynamic>{};
      final String token = (data['token'] ?? '').toString();
      final Map<String, dynamic> user = _extractUserMap(data);
      final String name = (user['nome'] ?? user['name'] ?? '').toString();
      final String userType = (user['tipo'] ?? 'user').toString();
      final String userId = (user['id'] ?? user['_id'] ?? '').toString();
      final String fotoPerfil = (user['fotoPerfil'] ?? '').toString();

      if (token.isEmpty) {
        return AuthResult(
          success: false,
          message: (data['erro'] ?? 'Token não retornado.').toString(),
        );
      }

      return AuthResult(
        success: true,
        message: (data['msg'] ?? successMessage).toString(),
        token: token,
        name: name,
        userType: userType,
        userId: userId,
        userPhoto: fotoPerfil,
      );
    } catch (error) {
      return AuthResult(
        success: false,
        message: ApiClient.mapError(error).message,
      );
    }
  }

  Map<String, dynamic> _extractUserMap(Map<String, dynamic> data) {
    if (data['user'] is Map<String, dynamic>) {
      return data['user'] as Map<String, dynamic>;
    }
    return <String, dynamic>{};
  }
}
