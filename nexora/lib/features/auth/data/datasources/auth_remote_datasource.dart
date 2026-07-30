import '../../../../core/constants/app_config.dart';
import '../../../../core/rest_client/rest_client.dart';
import '../../../../core/rest_client/rest_client_exception.dart';
import '../models/access_response_model.dart';
import '../models/auth_result_model.dart';
import '../models/module_access_model.dart';
import '../models/oauth_token_response_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResultModel> login(String username, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final RestClient restClient;

  AuthRemoteDataSourceImpl({required this.restClient});

  @override
  Future<AuthResultModel> login(String username, String password) async {
    final token = await _fetchToken(username, password);
    final bearer = 'Bearer ${token.accessToken}';

    final me = await _fetchMe(bearer);
    if (me == null) {
      throw Exception('Não foi possível obter os dados da conta.');
    }

    final modules = await _fetchModules(bearer);

    return AuthResultModel(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
      user: me,
      modules: modules,
    );
  }

  Future<OAuthTokenResponseModel> _fetchToken(
    String username,
    String password,
  ) async {
    final body = Uri(queryParameters: {
      'grant_type': 'password',
      'client_id': AppConfig.oauthClientId,
      'username': username,
      'password': password,
    }).query;

    try {
      final response = await restClient.unauth().post<Map<String, dynamic>>(
            '/oauth/token',
            data: body,
            header: const {
              'Content-Type': 'application/x-www-form-urlencoded',
            },
          );

      return OAuthTokenResponseModel.fromJson(response.data ?? {});
    } on RestClientException catch (e) {
      if (e.isTimeout) {
        throw Exception(
          'O servidor demorou demasiado tempo a responder. Tenta novamente.',
        );
      }

      final data = e.response.data;
      final error = data is Map
          ? (data['error_description'] ?? data['error'])
          : null;
      throw Exception(
        error?.toString() ?? 'Credenciais inválidas ou servidor indisponível.',
      );
    }
  }

  Future<UserModel?> _fetchMe(String bearer) async {
    try {
      final response = await restClient.unauth().get<Map<String, dynamic>>(
            '/api/auth/me',
            header: {'Authorization': bearer},
          );

      if (response.statusCode != 200 || response.data == null) return null;
      return UserModel.fromJson(response.data!);
    } catch (_) {
      return null;
    }
  }

  Future<List<ModuleAccessModel>> _fetchModules(String bearer) async {
    try {
      final response = await restClient.unauth().get<Map<String, dynamic>>(
            '/api/auth/me/acesso',
            header: {'Authorization': bearer},
          );

      if (response.statusCode != 200 || response.data == null) return [];
      return AccessResponseModel.fromJson(response.data!).modules;
    } catch (_) {
      return [];
    }
  }
}
