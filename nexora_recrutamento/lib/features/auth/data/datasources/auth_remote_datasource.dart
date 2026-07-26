import '../../../../core/error/exceptions.dart';
import '../../../../core/error/rest_exception_mapper.dart';
import '../../../../core/rest_client/rest_client.dart';
import '../../../../core/rest_client/rest_client_exception.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String nome, String email, String password);
  Future<UserModel> updateProfile({required String nome, String? telefone});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final RestClient client;

  const AuthRemoteDataSourceImpl(this.client);

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      // Login unificado do Nexora — não exige sessão prévia.
      final res = await client.unauth().post<Map<String, dynamic>>(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );
      final json = res.data ?? {};
      final token = json['access_token'] as String? ?? '';
      final refreshToken = json['refresh_token'] as String? ?? '';
      // Contas de candidato vêm em "candidato"; outros tipos em "user".
      final userJson =
          json['candidato'] as Map<String, dynamic>? ??
          json['user'] as Map<String, dynamic>? ??
          json;
      return UserModel.fromJson(userJson, token: token, refreshToken: refreshToken);
    } on RestClientException catch (e) {
      mapRestException(e);
    }
  }

  @override
  Future<UserModel> register(String nome, String email, String password) async {
    try {
      // O registo de candidato não devolve sessão (só cria a conta) —
      // por isso autenticamos logo a seguir com as mesmas credenciais.
      await client.unauth().post<Map<String, dynamic>>(
        '/api/public/recrutamento/candidatos/registar',
        data: {'nome': nome, 'email': email, 'password': password},
      );
      return login(email, password);
    } on RestClientException catch (e) {
      mapRestException(e);
    }
  }

  @override
  Future<UserModel> updateProfile({
    required String nome,
    String? telefone,
  }) async {
    try {
      // O PUT devolve 204 No Content (sem body).
      await client.auth().put<void>(
        '/api/public/recrutamento/candidatos/perfil',
        data: {
          'nome': nome,
          if (telefone != null && telefone.isNotEmpty) 'telefone': telefone,
        },
      );
      // Vamos buscar o perfil actualizado para manter o cache sincronizado.
      final res = await client.auth().get<Map<String, dynamic>>(
        '/api/public/recrutamento/candidatos/perfil',
      );
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        throw const ServerException('Resposta de perfil inválida');
      }
      return UserModel.fromJson(data);
    } on RestClientException catch (e) {
      mapRestException(e);
    }
  }
}
