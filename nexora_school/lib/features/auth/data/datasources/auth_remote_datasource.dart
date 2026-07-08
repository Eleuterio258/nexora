import 'dart:convert';
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

      // Determinar role pelo escopo (mais fiável que tipo)
      final escopos = (data['escopo'] as List?)?.map((e) => e.toString()).toList() ?? [];
      final role = _resolveRole(escopos, data['tipo']?.toString() ?? '');

      // Perfil varia por tipo de utilizador
      final aluno   = data['aluno'] as Map<String, dynamic>?;
      final userMap = data['user']  as Map<String, dynamic>?;
      final profile = aluno ?? userMap ?? const <String, dynamic>{};

      final nome          = (profile['nome'] ?? profile['name'] ?? '').toString();
      final id            = (profile['id']   ?? 0).toString();
      final code          = (profile['codigo'] ?? '').toString();
      final cargo         = (profile['cargo'] ?? '').toString();
      final resolvedEmail = (profile['email'] ?? email).toString();

      // Módulos do professor (serializar como JSON string)
      final modulosList = data['modulos'] as List?;
      final modulosJson = modulosList != null ? jsonEncode(modulosList) : null;

      return UserModel(
        id:           id,
        name:         nome,
        email:        resolvedEmail,
        role:         role,
        token:        data['access_token'] as String,
        refreshToken: data['refresh_token'] as String?,
        code:         code.isEmpty  ? null : code,
        cargo:        cargo.isEmpty ? null : cargo,
        modulos:      modulosJson,
        expiresIn:    data['expires_in'] as int?,
      );
    } on RestClientException catch (e) {
      if (e.statusCode == 401) throw const UnauthorizedException();
      if (e.statusCode == 422) throw const InvalidInputException();
      if (e.statusCode == null) throw const NetworkException();
      throw const ServerException();
    }
  }

  /// Mapeia escopo/tipo para role normalizado.
  static String _resolveRole(List<String> escopos, String tipo) {
    if (escopos.contains('portal_professor')) return 'professor';
    if (escopos.contains('portal_aluno'))     return 'aluno';
    // fallback pelo tipo
    if (tipo == 'aluno') return 'aluno';
    return 'professor';
  }
}
