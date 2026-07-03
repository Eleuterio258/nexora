import 'package:dio/dio.dart';
import '../../config/app_config.dart';
import '../rest_client.dart';
import '../rest_client_exception.dart';
import '../rest_client_response.dart';
import 'auth_interceptor.dart';

class DioRestClient implements RestClient {
  DioRestClient({
    BaseOptions? baseOptions,
    Future<String?> Function()? getToken,
  }) {
    _dio = Dio(baseOptions ?? _defaultOptions);
    _dio.interceptors.add(AuthInterceptor(getToken: getToken));
  }

  static final _defaultOptions = BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  );

  late final Dio _dio;

  @override
  RestClient auth() {
    _dio.options.extra['auth_required'] = true;
    return this;
  }

  @override
  RestClient unauth() {
    _dio.options.extra['auth_required'] = false;
    return this;
  }

  @override
  Future<RestClientResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? header,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: Options(headers: header),
      );
      return _toResponse(response);
    } on DioException catch (e) {
      _throwException(e);
    }
  }

  @override
  Future<RestClientResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? header,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: header),
      );
      return _toResponse(response);
    } on DioException catch (e) {
      _throwException(e);
    }
  }

  @override
  Future<RestClientResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? header,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: header),
      );
      return _toResponse(response);
    } on DioException catch (e) {
      _throwException(e);
    }
  }

  @override
  Future<RestClientResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? header,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: header),
      );
      return _toResponse(response);
    } on DioException catch (e) {
      _throwException(e);
    }
  }

  @override
  Future<RestClientResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? header,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: header),
      );
      return _toResponse(response);
    } on DioException catch (e) {
      _throwException(e);
    }
  }

  @override
  Future<RestClientResponse<T>> request<T>(
    String path, {
    required String method,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? header,
  }) async {
    try {
      final response = await _dio.request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method, headers: header),
      );
      return _toResponse(response);
    } on DioException catch (e) {
      _throwException(e);
    }
  }

  RestClientResponse<T> _toResponse<T>(Response response) {
    return RestClientResponse<T>(
      data: response.data,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
    );
  }

  Never _throwException(DioException e) {
    throw RestClientException(
      error: e.error,
      message: e.response?.statusMessage,
      statusCode: e.response?.statusCode,
      response: RestClientResponse(
        data: e.response?.data,
        statusCode: e.response?.statusCode,
        statusMessage: e.response?.statusMessage,
      ),
    );
  }
}
