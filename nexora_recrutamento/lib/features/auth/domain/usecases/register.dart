import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class Register extends UseCase<User, RegisterParams> {
  final AuthRepository repository;
  const Register(this.repository);

  @override
  Future<Either<Failure, User>> call(RegisterParams params) =>
      repository.register(params.nome, params.email, params.password);
}

class RegisterParams extends Equatable {
  final String nome;
  final String email;
  final String password;
  const RegisterParams({
    required this.nome,
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [nome, email, password];
}
