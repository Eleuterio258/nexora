import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_result_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase implements UseCase<AuthResultEntity, LoginParams> {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  @override
  Future<Either<Failure, AuthResultEntity>> call(LoginParams params) async {
    return await repository.login(params.username, params.password);
  }
}

class LoginParams extends Equatable {
  final String username;
  final String password;

  const LoginParams({required this.username, required this.password});

  @override
  List<Object?> get props => [username, password];
}
