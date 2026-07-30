import '../../domain/entities/user_entity.dart';

class UserModel {
  final int id;
  final String name;
  final String email;
  final int? tenantId;
  final int? roleId;
  final String? role;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.tenantId,
    this.roleId,
    this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['nome'] as String,
      email: json['email'] as String,
      tenantId: json['tenant_id'] as int?,
      roleId: json['cargo_id'] as int?,
      role: json['cargo'] as String?,
    );
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      tenantId: entity.tenantId,
      roleId: entity.roleId,
      role: entity.role,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': name,
      'email': email,
      'tenant_id': tenantId,
      'cargo_id': roleId,
      'cargo': role,
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      name: name,
      email: email,
      tenantId: tenantId,
      roleId: roleId,
      role: role,
    );
  }
}
