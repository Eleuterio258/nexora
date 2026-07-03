import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class Login extends UseCase<User, LoginParams> {
  final AuthRepository repository;
  const Login(this.repository);

  @override
  Future<Either<Failure, User>> call(LoginParams params) =>
      repository.login(params.email, params.password);
}

class LoginParams extends Equatable {
  final String email;
  final String password;
  const LoginParams({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}
