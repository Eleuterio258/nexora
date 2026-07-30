import 'package:equatable/equatable.dart';

import 'module_access_entity.dart';
import 'user_entity.dart';

class AuthResultEntity extends Equatable {
  final UserEntity user;
  final List<ModuleAccessEntity> modules;
  final String accessToken;
  final String refreshToken;

  const AuthResultEntity({
    required this.user,
    required this.modules,
    required this.accessToken,
    required this.refreshToken,
  });

  @override
  List<Object?> get props => [user, modules, accessToken, refreshToken];
}
