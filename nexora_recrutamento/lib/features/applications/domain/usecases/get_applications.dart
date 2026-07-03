import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/application.dart';
import '../repositories/application_repository.dart';

class GetApplications extends UseCase<List<Application>, NoParams> {
  final ApplicationRepository repository;
  const GetApplications(this.repository);

  @override
  Future<Either<Failure, List<Application>>> call(NoParams params) =>
      repository.getApplications();
}
