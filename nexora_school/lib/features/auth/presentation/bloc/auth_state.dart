import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

sealed class AuthState extends Equatable {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
  @override
  List<Object> get props => [];
}

class AuthLoading extends AuthState {
  const AuthLoading();
  @override
  List<Object> get props => [];
}

class AuthSuccess extends AuthState {
  const AuthSuccess(this.user);
  final User user;
  @override
  List<Object> get props => [user];
}

class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
  @override
  List<Object> get props => [message];
}
