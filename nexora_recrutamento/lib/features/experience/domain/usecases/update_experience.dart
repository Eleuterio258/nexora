import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/models/experience_model.dart';
import '../repositories/experience_repository.dart';

class UpdateExperienceParams {
  final int id;
  final ExperienceModel experience;

  const UpdateExperienceParams({
    required this.id,
    required this.experience,
  });
}

class UpdateExperience implements UseCase<Unit, UpdateExperienceParams> {
  final ExperienceRepository repository;

  const UpdateExperience(this.repository);

  @override
  Future<Either<Failure, Unit>> call(UpdateExperienceParams params) {
    return repository.updateExperience(params.id, params.experience);
  }
}
