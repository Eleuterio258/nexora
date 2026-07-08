import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.token,
    this.refreshToken,
    this.code,
    this.cargo,
    this.modulos,
    this.expiresIn,
  });

  final String id;
  final String name;
  final String email;

  /// role normalizado: "aluno" | "professor" | "encarregado"
  final String role;
  final String token;
  final String? refreshToken;
  final String? code;
  final String? cargo;

  /// JSON string da lista de módulos (professor)
  final String? modulos;
  final int? expiresIn;

  bool get isProfessor   => role == 'professor';
  bool get isAluno       => role == 'aluno';
  bool get isEncarregado => role == 'encarregado';

  @override
  List<Object?> get props =>
      [id, name, email, role, token, refreshToken, code, cargo];
}
