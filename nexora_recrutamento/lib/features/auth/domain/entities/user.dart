import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String nome;
  final String email;
  final String token;
  final List<String> permissoes;

  const User({
    required this.id,
    required this.nome,
    required this.email,
    required this.token,
    required this.permissoes,
  });

  @override
  List<Object> get props => [id, email];
}
