import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({this.getToken});

  final Future<String?> Function()? getToken;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final authRequired = options.extra['auth_required'] ?? false;
    if (authRequired) {
      final token = await getToken?.call();
      if (token == null) {
        return handler.reject(
          DioException(
            requestOptions: options,
            error: 'TOKEN_EXPIRADO',
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
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}
