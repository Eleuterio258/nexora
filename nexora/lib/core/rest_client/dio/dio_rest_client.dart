import 'package:dio/dio.dart';

import '../rest_client.dart';
import '../rest_client_exception.dart';
import '../rest_client_response.dart';
import '../../local/local_storege/i_local_storege.dart';
import '../../constants/app_config.dart';
import 'auth_interceptor.dart';

class DioRestClient implements RestClient {
  late final Dio _dio;

  final _defaultOptions = BaseOptions(
    baseUrl: AppConfig.erpBaseUrl,
    connectTimeout: const Duration(milliseconds: 5000),
    receiveTimeout: const Duration(milliseconds: 3000),
  );

  DioRestClient(
      {required ILocalSecureStorege localStorege, BaseOptions? baseOptions}) {
    _dio = Dio(baseOptions ?? _defaultOptions);
    _dio.interceptors.add(
      AuthInterceptor(restClient: this, localStorege: localStorege),
    );
  }
  @override
  RestClient auth() {
    _defaultOptions.extra['auth_required'] = true;
    return this;
  }

  @override
  RestClient unauth() {
    _defaultOptions.extra['auth_required'] = false;
    return this;
  }

  @override
  Future<RestClientResponse<T>> delete<T>(String path,
      {data,
      Map<String, dynamic>? queryParameters,
      Map<String, dynamic>? header}) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: header),
      );
      return _dioResponseConverter(response);
    } on DioException catch (e) {
      _throwRestClientException(e);
    }
  }

  @override
  Future<RestClientResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? header,
  }) async {
    try {
      final response = await _dio.get(path,
          queryParameters: queryParameters,
          options: Options(
            headers: header,
          ));
      return _dioResponseConverter(response);
    } on DioException catch (e) {
      _throwRestClientException(e);
    }
  }

  @override
  Future<RestClientResponse<T>> patch<T>(
    String path, {
    data,
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
      return _dioResponseConverter(response);
    } on DioException catch (e) {
      _throwRestClientException(e);
    }
  }

  @override
  Future<RestClientResponse<T>> post<T>(String path,
      {data,
      Map<String, dynamic>? queryParameters,
      Map<String, dynamic>? header}) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: header),
      );
      return _dioResponseConverter(response);
    } on DioException catch (e) {
      _throwRestClientException(e);
    }
  }

  @override
  Future<RestClientResponse<T>> put<T>(String path,
      {data,
      Map<String, dynamic>? queryParameters,
      Map<String, dynamic>? header}) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: header),
      );
      return _dioResponseConverter(response);
    } on DioException catch (e) {
      _throwRestClientException(e);
    }
  }

  @override
  Future<RestClientResponse<T>> request<T>(
    String path, {
    required String method,
    data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? header,
  }) async {
    try {
      final response = await _dio.request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: header, method: method),
      );
      return _dioResponseConverter(response);
    } on DioException catch (e) {
      _throwRestClientException(e);
    }
  }

  Future<RestClientResponse<T>> _dioResponseConverter<T>(
      Response<dynamic> response) async {
    return RestClientResponse<T>(
      data: response.data,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
    );
  }

  Never _throwRestClientException(DioException dioException) {
    final response = dioException.response;
    final isTimeout = dioException.type == DioExceptionType.connectionTimeout ||
        dioException.type == DioExceptionType.sendTimeout ||
        dioException.type == DioExceptionType.receiveTimeout;

    throw RestClientException(
      error: dioException.error,
      message: response?.statusMessage,
      statusCode: response?.statusCode,
      isTimeout: isTimeout,
      response: RestClientResponse(
        data: response?.data,
        statusMessage: response?.statusMessage,
        statusCode: response?.statusCode,
      ),
    );
  }
}
