import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/education_repository.dart';
import '../datasources/education_remote_datasource.dart';
import '../models/education_model.dart';

class EducationRepositoryImpl implements EducationRepository {
  final EducationRemoteDataSource remote;

  const EducationRepositoryImpl({required this.remote});

  @override
  Future<Either<Failure, List<EducationModel>>> getEducations() async {
    try {
      final educations = await remote.getEducations();
      return Right(educations);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, EducationModel>> createEducation(
    EducationModel education,
  ) async {
    try {
      final created = await remote.createEducation(education);
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
  Future<Either<Failure, Unit>> updateEducation(
    int id,
    EducationModel education,
  ) async {
    try {
      await remote.updateEducation(id, education);
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
  Future<Either<Failure, Unit>> deleteEducation(int id) async {
    try {
      await remote.deleteEducation(id);
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
