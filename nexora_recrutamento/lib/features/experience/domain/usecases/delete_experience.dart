import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/experience_repository.dart';

class DeleteExperience implements UseCase<Unit, int> {
  final ExperienceRepository repository;

  const DeleteExperience(this.repository);

  @override
  Future<Either<Failure, Unit>> call(int params) {
    return repository.deleteExperience(params);
  }
}
