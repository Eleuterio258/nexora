import 'dart:convert';

import '../../features/auth/data/models/module_access_model.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/auth/domain/entities/auth_result_entity.dart';
import '../local/local_storege/i_local_storege.dart';

class SessionManager {
  static const keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUser = 'user';
  static const _keyModules = 'modules';

  final ILocalSecureStorege _storage;

  String? _accessToken;
  String? _refreshToken;
  UserModel? _user;
  List<ModuleAccessModel> _modules = [];

  SessionManager._(this._storage);

  static Future<SessionManager> create(ILocalSecureStorege storage) async {
    final manager = SessionManager._(storage);
    await manager._load();
    return manager;
  }

  Future<void> _load() async {
    _accessToken = await _storage.read<String>(keyAccessToken);
    _refreshToken = await _storage.read<String>(_keyRefreshToken);

    final rawUser = await _storage.read<String>(_keyUser);
    if (rawUser != null) {
      try {
        _user = UserModel.fromJson(jsonDecode(rawUser) as Map<String, dynamic>);
      } catch (_) {
        _user = null;
      }
    }

    final rawModules = await _storage.read<String>(_keyModules);
    if (rawModules != null) {
      try {
        final list = jsonDecode(rawModules) as List<dynamic>;
        _modules = list
            .map((e) => ModuleAccessModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _modules = [];
      }
    }
  }

  bool get isLoggedIn => _accessToken != null;

  String? get accessToken => _accessToken;

  String? get refreshToken => _refreshToken;

  UserModel? get user => _user;

  List<ModuleAccessModel> get modules => _modules;

  Future<void> saveSession(AuthResultEntity result) async {
    _accessToken = result.accessToken;
    _refreshToken = result.refreshToken;
    _user = UserModel.fromEntity(result.user);
    _modules = result.modules.map(ModuleAccessModel.fromEntity).toList();

    await Future.wait([
      _storage.write(keyAccessToken, _accessToken!),
      _storage.write(_keyRefreshToken, _refreshToken!),
      _storage.write(_keyUser, jsonEncode(_user!.toJson())),
      _storage.write(
        _keyModules,
        jsonEncode(_modules.map((e) => e.toJson()).toList()),
      ),
    ]);
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _user = null;
    _modules = [];

    await Future.wait([
      _storage.remove(keyAccessToken),
      _storage.remove(_keyRefreshToken),
      _storage.remove(_keyUser),
      _storage.remove(_keyModules),
    ]);
  }
}
