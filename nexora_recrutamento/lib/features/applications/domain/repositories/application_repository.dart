import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/application.dart';

abstract class ApplicationRepository {
  Future<Either<Failure, List<Application>>> getApplications();
  Future<Either<Failure, Application>> getApplicationById(int id);
  Future<Either<Failure, Application>> submitApplication({
    required int jobId,
    required String coverLetter,
  });
}
