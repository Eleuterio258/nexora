import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/job.dart';
import '../../domain/repositories/job_repository.dart';
import '../datasources/job_remote_datasource.dart';

class JobRepositoryImpl implements JobRepository {
  final JobRemoteDataSource remote;
  final String? token;

  const JobRepositoryImpl({required this.remote, this.token});

  @override
  Future<Either<Failure, List<Job>>> getJobs(
      {String? category, String? query}) async {
    try {
      final jobs = await remote.getJobs(category: category, query: query);
      return Right(jobs);
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
      return Right(await remote.getJobById(id));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> saveJob(int jobId) async {
    try {
      await remote.saveJob(jobId, token ?? '');
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> unsaveJob(int jobId) async {
    try {
      await remote.unsaveJob(jobId, token ?? '');
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, List<Job>>> getSavedJobs() async {
    try {
      final jobs = await remote.getJobs(category: 'saved');
      return Right(jobs);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    }
  }
}
