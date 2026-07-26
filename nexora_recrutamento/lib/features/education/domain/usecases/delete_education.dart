import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/education_repository.dart';

class DeleteEducation implements UseCase<Unit, int> {
  final EducationRepository repository;

  const DeleteEducation(this.repository);

  @override
  Future<Either<Failure, Unit>> call(int params) {
    return repository.deleteEducation(params);
  }
}
