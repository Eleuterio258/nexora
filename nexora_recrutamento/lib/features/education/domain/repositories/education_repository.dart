import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/education_model.dart';

abstract class EducationRepository {
  Future<Either<Failure, List<EducationModel>>> getEducations();
  Future<Either<Failure, EducationModel>> createEducation(
    EducationModel education,
  );
  Future<Either<Failure, Unit>> updateEducation(
    int id,
    EducationModel education,
  );
  Future<Either<Failure, Unit>> deleteEducation(int id);
}
