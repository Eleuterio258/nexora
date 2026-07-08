import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    required super.token,
    super.refreshToken,
    super.code,
    super.cargo,
    super.modulos,
    super.expiresIn,
  });
}
