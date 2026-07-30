import 'package:dio/dio.dart';

import '../rest_client.dart';
import '../../local/local_storege/i_local_storege.dart';
import '../../services/session_manager.dart';

class AuthInterceptor extends Interceptor {
  final ILocalSecureStorege localStorege;
  final RestClient restClient;

  AuthInterceptor({required this.restClient, required this.localStorege});

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final authRequired = options.extra["auth_required"] ?? false;
    if (authRequired) {
      final token = await localStorege.read<String>(SessionManager.keyAccessToken);
      if (token == null) {
        return handler.reject(DioException(
            requestOptions: options,
            error: "EXPIRED  TOKEN",
            type: DioExceptionType.cancel));
      }
      options.headers["Authorization"] = "Bearer $token";
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {}
    return handler.next(err);
  }
}
