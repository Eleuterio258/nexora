import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/experience_model.dart';

abstract class ExperienceRepository {
  Future<Either<Failure, List<ExperienceModel>>> getExperiences();
  Future<Either<Failure, ExperienceModel>> createExperience(
    ExperienceModel experience,
  );
  Future<Either<Failure, Unit>> updateExperience(
    int id,
    ExperienceModel experience,
  );
  Future<Either<Failure, Unit>> deleteExperience(int id);
}
