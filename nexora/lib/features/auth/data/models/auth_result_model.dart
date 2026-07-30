import '../../domain/entities/auth_result_entity.dart';
import 'module_access_model.dart';
import 'user_model.dart';

class AuthResultModel {
  final String accessToken;
  final String refreshToken;
  final UserModel user;
  final List<ModuleAccessModel> modules;

  AuthResultModel({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.modules,
  });

  AuthResultEntity toEntity() {
    return AuthResultEntity(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user.toEntity(),
      modules: modules.map((e) => e.toEntity()).toList(),
    );
  }
}
