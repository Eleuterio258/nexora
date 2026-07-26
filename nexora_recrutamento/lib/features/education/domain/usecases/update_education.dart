import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/models/education_model.dart';
import '../repositories/education_repository.dart';

class UpdateEducationParams {
  final int id;
  final EducationModel education;

  const UpdateEducationParams({
    required this.id,
    required this.education,
  });
}

class UpdateEducation implements UseCase<Unit, UpdateEducationParams> {
  final EducationRepository repository;

  const UpdateEducation(this.repository);

  @override
  Future<Either<Failure, Unit>> call(UpdateEducationParams params) {
    return repository.updateEducation(params.id, params.education);
  }
}
