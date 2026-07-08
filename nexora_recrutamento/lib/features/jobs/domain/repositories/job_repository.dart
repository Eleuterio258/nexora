import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/job.dart';

abstract class JobRepository {
  Future<Either<Failure, List<Job>>> getJobs(
      {String? category, String? query, int? tenantId});
  Future<Either<Failure, Job>> getJobById(int id);
  Future<Either<Failure, Unit>> saveJob(Job job);
  Future<Either<Failure, Unit>> unsaveJob(int jobId);
  Future<Either<Failure, List<Job>>> getSavedJobs();
}
