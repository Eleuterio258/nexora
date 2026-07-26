import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/models/education_model.dart';
import '../repositories/education_repository.dart';

class GetEducations implements UseCase<List<EducationModel>, NoParams> {
  final EducationRepository repository;

  const GetEducations(this.repository);

  @override
  Future<Either<Failure, List<EducationModel>>> call(NoParams params) {
    return repository.getEducations();
  }
}
