import '../error/exceptions.dart';
import '../rest_client/rest_client.dart';
import '../rest_client/rest_client_exception.dart';
import '../rest_client/rest_client_response.dart';

class ApiClient {
  final RestClient _client;
  const ApiClient(this._client);

  Future<Map<String, dynamic>> get(String path) =>
      _exec(() => _client.auth().get<Map<String, dynamic>>(path));

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) =>
      _exec(() => _client.auth().post<Map<String, dynamic>>(path, data: body));

  Future<Map<String, dynamic>> postPublic(
          String path, Map<String, dynamic> body) =>
      _exec(
          () => _client.unauth().post<Map<String, dynamic>>(path, data: body));

  Future<List<dynamic>> getList(String path) async {
    try {
      final res = await _client.auth().get<List<dynamic>>(path);
      return res.data ?? [];
    } on RestClientException catch (e) {
      return _mapAndThrow(e);
    }
  }

  Future<T> _exec<T>(
      Future<RestClientResponse<T>> Function() fn) async {
    try {
      final res = await fn();
      return res.data!;
    } on RestClientException catch (e) {
      return _mapAndThrow(e);
    }
  }

  Never _mapAndThrow(RestClientException e) {
    if (e.statusCode == 401) {
      throw AuthException(e.message ?? 'Não autorizado.');
    }
    if (e.statusCode == 404) {
      throw ServerException('Recurso não encontrado.', statusCode: 404);
    }
    throw ServerException(
      e.message ?? 'Erro de servidor.',
      statusCode: e.statusCode,
    );
  }
}
