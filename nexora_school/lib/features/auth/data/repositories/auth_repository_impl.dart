import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/local/local_storage/i_local_storage.dart';
import '../../../../core/local/storage_keys.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._datasource, this._storage);

  final AuthRemoteDatasource _datasource;
  final ILocalStorage _storage;

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _datasource.login(email: email, password: password);
      await _storage.write(StorageKeys.authToken, user.token);
      await _storage.write(StorageKeys.userId, user.id);
      await _storage.write(StorageKeys.userRole, user.role);
      return Right(user);
    } on UnauthorizedException {
      return Left(InvalidCredentialsFailure());
    } on InvalidInputException {
      return Left(InvalidInputFailure());
    } on NetworkException {
      return Left(OfflineFailure());
    } on OfflineException {
      return Left(OfflineFailure());
    } on ServerException {
      return Left(ServerFailure());
    }
  }
}
