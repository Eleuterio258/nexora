import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/experience_repository.dart';
import '../datasources/experience_remote_datasource.dart';
import '../models/experience_model.dart';

class ExperienceRepositoryImpl implements ExperienceRepository {
  final ExperienceRemoteDataSource remote;

  const ExperienceRepositoryImpl({required this.remote});

  @override
  Future<Either<Failure, List<ExperienceModel>>> getExperiences() async {
    try {
      final experiences = await remote.getExperiences();
      return Right(experiences);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, ExperienceModel>> createExperience(
    ExperienceModel experience,
  ) async {
    try {
      final created = await remote.createExperience(experience);
      return Right(created);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> updateExperience(
    int id,
    ExperienceModel experience,
  ) async {
    try {
      await remote.updateExperience(id, experience);
      return const Right(unit);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteExperience(int id) async {
    try {
      await remote.deleteExperience(id);
      return const Right(unit);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    }
  }
}
