import 'package:dio/dio.dart';
import '../../storage/local_store.dart';

class AuthInterceptor extends Interceptor {
  final LocalStore store;
  static const _tokenKey = 'auth_token';

  const AuthInterceptor({required this.store});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final authRequired = options.extra['auth_required'] as bool? ?? true;

    if (authRequired) {
      final token = await store.read(_tokenKey);
      if (token == null || token.isEmpty) {
        return handler.reject(
          DioException(
            requestOptions: options,
            error: 'Token ausente. Faca login novamente.',
            type: DioExceptionType.cancel,
          ),
        );
      }
      options.headers['Authorization'] = 'Bearer $token';
    } else {
      options.headers.remove('Authorization');
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await store.delete(_tokenKey);
    }
    handler.next(err);
  }
}
