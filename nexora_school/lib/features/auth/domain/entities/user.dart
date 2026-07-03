import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.token,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String token;

  @override
  List<Object> get props => [id, name, email, role, token];
}
