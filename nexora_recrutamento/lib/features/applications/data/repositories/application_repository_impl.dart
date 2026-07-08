import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/application.dart';
import '../../domain/repositories/application_repository.dart';
import '../datasources/application_remote_datasource.dart';

class ApplicationRepositoryImpl implements ApplicationRepository {
  final ApplicationRemoteDataSource remote;

  const ApplicationRepositoryImpl({required this.remote});

  @override
  Future<Either<Failure, List<Application>>> getApplications() async {
    try {
      return Right(await remote.getApplications());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, Application>> getApplicationById(int id) async {
    try {
      return Right(await remote.getApplicationById(id));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, Application>> submitApplication({
    required int jobId,
    required String jobTitle,
    required String nome,
    required String email,
    String? telefone,
    required String coverLetter,
  }) async {
    try {
      return Right(
        await remote.submitApplication(
          jobId: jobId,
          jobTitle: jobTitle,
          nome: nome,
          email: email,
          telefone: telefone,
          coverLetter: coverLetter,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    }
  }
}
