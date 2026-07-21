import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class LoginResult {
  final String accessToken;
  final String refreshToken;
  final String tipo;
  final Map<String, dynamic> user;

  LoginResult({
    required this.accessToken,
    required this.refreshToken,
    required this.tipo,
    required this.user,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tipo: json['tipo'] as String? ?? '',
      user: (json['user'] as Map<String, dynamic>?) ?? const {},
    );
  }
}

class AuthService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  // Réplica do comportamento de LoginActivity.kt (nexora_assiduidade):
  // timeout de 20s, 403 tratado à parte, e extracção de "error"/"detail"
  // do corpo de erro antes de cair na mensagem genérica.
  Future<LoginResult> login(String email, String password) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/login');

    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw AuthException(
        'O servidor demorou demasiado tempo a responder. Tenta novamente.',
      );
    } catch (_) {
      throw AuthException('Nao foi possivel ligar ao ERP.');
    }

    if (response.statusCode == 403) {
      throw AuthException('Sem permissão para este ecrã.');
    }

    Map<String, dynamic>? body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      body = null;
    }

    if (response.statusCode != 200) {
      final msg = (body?['detail'] ?? body?['error']) as String?;
      throw AuthException(msg ?? 'Falha na comunicacao com o servidor.');
    }

    final result = LoginResult.fromJson(body!);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, result.accessToken);
    await prefs.setString(_refreshTokenKey, result.refreshToken);

    return result;
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }
}
