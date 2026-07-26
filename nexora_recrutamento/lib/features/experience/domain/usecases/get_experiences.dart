import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/models/experience_model.dart';
import '../repositories/experience_repository.dart';

class GetExperiences implements UseCase<List<ExperienceModel>, NoParams> {
  final ExperienceRepository repository;

  const GetExperiences(this.repository);

  @override
  Future<Either<Failure, List<ExperienceModel>>> call(NoParams params) {
    return repository.getExperiences();
  }
}
