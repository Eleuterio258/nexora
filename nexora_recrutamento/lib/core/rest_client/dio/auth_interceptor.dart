import 'package:dio/dio.dart';
import '../../storage/local_store.dart';

class AuthInterceptor extends Interceptor {
  final LocalStore store;
  final Dio dio;
  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';

  AuthInterceptor({required this.store, required this.dio});

  // Partilhada entre pedidos concorrentes para que um único 401 dispare
  // apenas um pedido de refresh, em vez de um por cada request em falha.
  Future<String?>? _refreshing;

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
    final isRefreshCall = err.requestOptions.extra['is_refresh_call'] == true;
    if (err.response?.statusCode != 401 || isRefreshCall) {
      handler.next(err);
      return;
    }

    final newToken = await (_refreshing ??= _refreshAccessToken());
    _refreshing = null;

    if (newToken == null) {
      await store.delete(_tokenKey);
      await store.delete(_refreshTokenKey);
      handler.next(err);
      return;
    }

    try {
      final retryOptions = err.requestOptions
        ..headers['Authorization'] = 'Bearer $newToken';
      handler.resolve(await dio.fetch(retryOptions));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<String?> _refreshAccessToken() async {
    final refreshToken = await store.read(_refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/api/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(
          extra: {'auth_required': false, 'is_refresh_call': true},
        ),
      );
      final newToken = response.data?['access_token'] as String?;
      if (newToken == null || newToken.isEmpty) return null;
      await store.write(_tokenKey, newToken);
      return newToken;
    } on DioException {
      return null;
    }
  }
}
