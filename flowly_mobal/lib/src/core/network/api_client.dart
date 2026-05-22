import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:meu_app/src/core/config/api_config.dart';
import 'package:meu_app/src/core/constants/storage_keys.dart';
import 'package:meu_app/src/core/network/api_exception.dart';

class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 12),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest:
            (RequestOptions options, RequestInterceptorHandler handler) async {
              final String? token = await _storage.read(
                key: StorageKeys.jwtToken,
              );
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              handler.next(options);
            },
      ),
    );
  }

  static final ApiClient instance = ApiClient._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final Dio _dio;

  Dio get dio => _dio;

  static ApiException mapError(Object error) {
    if (error is DioException) {
      final Object? data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final String? erro = data['erro']?.toString();
        final String? errorMsg = data['error']?.toString();
        final String? detalhe = data['detalhe']?.toString();
        final String? mensagem = data['mensagem']?.toString();
        final String? message = data['message']?.toString();
        return ApiException(
          erro ??
              errorMsg ??
              detalhe ??
              mensagem ??
              message ??
              'Erro de requisição.',
        );
      }
      if (data is String && data.trim().isNotEmpty) {
        return ApiException(data);
      }
      return ApiException('Falha de conexão com a API.');
    }
    return ApiException('Erro inesperado.');
  }
}
