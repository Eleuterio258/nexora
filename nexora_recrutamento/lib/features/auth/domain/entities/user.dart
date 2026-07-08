import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String nome;
  final String email;
  final String token;
  final String refreshToken;
  final List<String> permissoes;
  final int? tenantId;

  const User({
    required this.id,
    required this.nome,
    required this.email,
    required this.token,
    this.refreshToken = '',
    required this.permissoes,
    this.tenantId,
  });

  @override
  List<Object> get props => [id, email];
}
