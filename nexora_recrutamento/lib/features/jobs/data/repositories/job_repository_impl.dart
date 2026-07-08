import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/job.dart';
import '../../domain/repositories/job_repository.dart';
import '../datasources/job_local_datasource.dart';
import '../datasources/job_remote_datasource.dart';
import '../models/job_model.dart';

class JobRepositoryImpl implements JobRepository {
  final JobRemoteDataSource remote;
  final JobLocalDataSource local;

  const JobRepositoryImpl({required this.remote, required this.local});

  @override
  Future<Either<Failure, List<Job>>> getJobs({
    String? category,
    String? query,
    int? tenantId,
  }) async {
    try {
      final jobs = await remote.getJobs(
        category: category,
        query: query,
        tenantId: tenantId,
      );
      final savedIds = await local.getSavedJobIds();
      return Right(_withSavedFlag(jobs, savedIds));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, Job>> getJobById(int id) async {
    try {
      final job = await remote.getJobById(id);
      final savedIds = await local.getSavedJobIds();
      return Right(job.copyWith(isSaved: savedIds.contains(job.id)));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> saveJob(Job job) async {
    await local.saveJob(
      job is JobModel
          ? job
          : JobModel(
              id: job.id,
              title: job.title,
              company: job.company,
              location: job.location,
              type: job.type,
              category: job.category,
              description: job.description,
              salary: job.salary,
              logoUrl: job.logoUrl,
              postedAt: job.postedAt,
            ),
    );
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> unsaveJob(int jobId) async {
    await local.unsaveJob(jobId);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, List<Job>>> getSavedJobs() async {
    return Right(await local.getSavedJobs());
  }

  List<Job> _withSavedFlag(List<Job> jobs, Set<int> savedIds) => jobs
      .map((j) => savedIds.contains(j.id) ? j.copyWith(isSaved: true) : j)
      .toList();
}
