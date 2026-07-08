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

      final expiresAt = DateTime.now()
          .add(Duration(seconds: user.expiresIn ?? 28800))
          .millisecondsSinceEpoch
          .toString();

      await Future.wait([
        _storage.write(StorageKeys.authToken,      user.token),
        _storage.write(StorageKeys.userId,         user.id),
        _storage.write(StorageKeys.userRole,       user.role),
        _storage.write(StorageKeys.userName,       user.name),
        _storage.write(StorageKeys.userEmail,      user.email),
        _storage.write(StorageKeys.tokenExpiresAt, expiresAt),
        if (user.refreshToken != null)
          _storage.write(StorageKeys.refreshToken, user.refreshToken!),
        if (user.code != null)
          _storage.write(StorageKeys.userCode,  user.code!),
        if (user.cargo != null)
          _storage.write(StorageKeys.userCargo, user.cargo!),
        if (user.modulos != null)
          _storage.write(StorageKeys.userModulos, user.modulos!),
      ]);

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
