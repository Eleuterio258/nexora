import 'dart:convert';
import '../../../../core/error/exceptions.dart';
import '../../../../core/storage/local_store.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel> getCachedUser();
  Future<void> clearUser();
  Future<String?> getToken();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final LocalStore store;
  static const _keyUser = 'cached_user';
  static const _keyToken = 'auth_token';
  static const _keyRefreshToken = 'refresh_token';

  const AuthLocalDataSourceImpl(this.store);

  @override
  Future<void> cacheUser(UserModel user) async {
    await store.write(_keyUser, jsonEncode(user.toJson()));
    await store.write(_keyToken, user.token);
    await store.write(_keyRefreshToken, user.refreshToken);
  }

  @override
  Future<UserModel> getCachedUser() async {
    final raw = await store.read(_keyUser);
    final token = await store.read(_keyToken);
    final refreshToken = await store.read(_keyRefreshToken);
    if (raw == null) {
      throw const CacheException('Utilizador não encontrado em cache.');
    }
    return UserModel.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
      token: token ?? '',
      refreshToken: refreshToken ?? '',
    );
  }

  @override
  Future<void> clearUser() async {
    await store.delete(_keyUser);
    await store.delete(_keyToken);
    await store.delete(_keyRefreshToken);
  }

  @override
  Future<String?> getToken() => store.read(_keyToken);
}
