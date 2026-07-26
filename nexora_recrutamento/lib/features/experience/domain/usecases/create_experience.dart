import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/models/experience_model.dart';
import '../repositories/experience_repository.dart';

class CreateExperience implements UseCase<ExperienceModel, ExperienceModel> {
  final ExperienceRepository repository;

  const CreateExperience(this.repository);

  @override
  Future<Either<Failure, ExperienceModel>> call(ExperienceModel params) {
    return repository.createExperience(params);
  }
}
