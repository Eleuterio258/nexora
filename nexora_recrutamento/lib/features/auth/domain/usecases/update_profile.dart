import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class UpdateProfileParams {
  final String nome;
  final String? telefone;

  const UpdateProfileParams({required this.nome, this.telefone});
}

class UpdateProfile extends UseCase<User, UpdateProfileParams> {
  final AuthRepository repository;
  const UpdateProfile(this.repository);

  @override
  Future<Either<Failure, User>> call(UpdateProfileParams params) =>
      repository.updateProfile(nome: params.nome, telefone: params.telefone);
}
