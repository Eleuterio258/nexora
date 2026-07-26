import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/models/education_model.dart';
import '../repositories/education_repository.dart';

class CreateEducation implements UseCase<EducationModel, EducationModel> {
  final EducationRepository repository;

  const CreateEducation(this.repository);

  @override
  Future<Either<Failure, EducationModel>> call(EducationModel params) {
    return repository.createEducation(params);
  }
}
