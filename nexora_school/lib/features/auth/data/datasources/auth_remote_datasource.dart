import '../../../../core/errors/exceptions.dart';
import '../../../../core/rest_client/rest_client.dart';
import '../../../../core/rest_client/rest_client_exception.dart';
import '../models/user_model.dart';

abstract interface class AuthRemoteDatasource {
  Future<UserModel> login({required String email, required String password});
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  const AuthRemoteDatasourceImpl(this._client);

  final RestClient _client;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.unauth().post<Map<String, dynamic>>(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );
      final data = response.data!;
      final tipo = (data['tipo'] ?? 'aluno').toString();
      final aluno = data['aluno'] as Map<String, dynamic>?;
      final user = data['user'] as Map<String, dynamic>?;
      final profile = aluno ?? user ?? const <String, dynamic>{};
      return UserModel(
        id: (profile['id'] ?? '').toString(),
        name: (profile['nome'] ?? profile['name'] ?? '').toString(),
        email: email,
        role: tipo,
        token: data['access_token'] as String,
      );
    } on RestClientException catch (e) {
      if (e.statusCode == 401) throw const UnauthorizedException();
      if (e.statusCode == 422) throw const InvalidInputException();
      if (e.statusCode == null) throw const NetworkException();
      throw const ServerException();
    }
  }
}
