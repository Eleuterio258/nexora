import 'package:dio/dio.dart';
import '../../storage/local_store.dart';
import '../rest_client.dart';
import '../rest_client_exception.dart';
import '../rest_client_response.dart';
import 'auth_interceptor.dart';

class DioRestClient implements RestClient {
  late final Dio _dio;
  bool _authRequired = true;

  DioRestClient({
    required String baseUrl,
    required LocalStore store,
    BaseOptions? baseOptions,
    Duration connectTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(seconds: 30),
  }) {
    _dio = Dio(
      baseOptions ??
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: connectTimeout,
            receiveTimeout: receiveTimeout,
            contentType: 'application/json',
          ),
    )..interceptors.add(AuthInterceptor(store: store));
  }

  @override
  RestClient auth() {
    _authRequired = true;
    return this;
  }

  @override
  RestClient unauth() {
    _authRequired = false;
    return this;
  }

  Options _buildOptions(Map<String, dynamic>? headers) {
    final opts = Options(
      headers: headers,
      extra: {'auth_required': _authRequired},
    );
    _authRequired = true;
    return opts;
  }

  @override
  Future<RestClientResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: _buildOptions(headers),
      );
      return _convert(response);
    } on DioException catch (e) {
      _throw(e);
    }
  }

  @override
  Future<RestClientResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _buildOptions(headers),
      );
      return _convert(response);
    } on DioException catch (e) {
      _throw(e);
    }
  }

  @override
  Future<RestClientResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _buildOptions(headers),
      );
      return _convert(response);
    } on DioException catch (e) {
      _throw(e);
    }
  }

  @override
  Future<RestClientResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _buildOptions(headers),
      );
      return _convert(response);
    } on DioException catch (e) {
      _throw(e);
    }
  }

  @override
  Future<RestClientResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _buildOptions(headers),
      );
      return _convert(response);
    } on DioException catch (e) {
      _throw(e);
    }
  }

  @override
  Future<RestClientResponse<T>> request<T>(
    String path, {
    required String method,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.request<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _buildOptions(headers).copyWith(method: method),
      );
      return _convert(response);
    } on DioException catch (e) {
      _throw(e);
    }
  }

  RestClientResponse<T> _convert<T>(Response<T> response) =>
      RestClientResponse<T>(
        data: response.data,
        statusCode: response.statusCode,
        statusMessage: response.statusMessage,
      );

  Never _throw(DioException e) {
    final r = e.response;
    throw RestClientException(
      error: e.error,
      message: r?.statusMessage ?? e.message,
      statusCode: r?.statusCode,
      response: RestClientResponse(
        data: r?.data,
        statusCode: r?.statusCode,
        statusMessage: r?.statusMessage,
      ),
    );
  }
}
