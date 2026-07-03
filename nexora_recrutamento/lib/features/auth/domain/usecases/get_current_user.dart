import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUser extends UseCase<User, NoParams> {
  final AuthRepository repository;
  const GetCurrentUser(this.repository);

  @override
  Future<Either<Failure, User>> call(NoParams params) =>
      repository.getCurrentUser();
}
