import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/auth_result_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, AuthResultEntity>> login(
    String username,
    String password,
  ) async {
    try {
      final result = await remoteDataSource.login(username, password);
      return Right(result.toEntity());
    } on TimeoutException catch (_) {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
