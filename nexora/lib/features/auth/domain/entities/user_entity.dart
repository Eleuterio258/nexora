import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final int id;
  final String name;
  final String email;
  final int? tenantId;
  final int? roleId;
  final String? role;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.tenantId,
    this.roleId,
    this.role,
  });

  @override
  List<Object?> get props => [id, name, email, tenantId, roleId, role];
}
