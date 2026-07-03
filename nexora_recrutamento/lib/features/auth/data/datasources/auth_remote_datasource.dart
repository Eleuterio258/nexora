import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String nome, String email, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient client;
  const AuthRemoteDataSourceImpl(this.client);

  @override
  Future<UserModel> login(String email, String password) async {
    final json = await client.post('/api/auth/login', {
      'email': email,
      'password': password,
    });
    final token = json['token'] as String? ?? '';
    final userJson = json['user'] as Map<String, dynamic>? ?? json;
    return UserModel.fromJson(userJson, token: token);
  }

  @override
  Future<UserModel> register(
      String nome, String email, String password) async {
    final json = await client.post('/api/auth/register', {
      'nome': nome,
      'email': email,
      'password': password,
    });
    final token = json['token'] as String? ?? '';
    final userJson = json['user'] as Map<String, dynamic>? ?? json;
    return UserModel.fromJson(userJson, token: token);
  }
}
