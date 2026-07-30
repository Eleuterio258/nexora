import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexora/core/errors/failures.dart';
import 'package:nexora/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:nexora/features/auth/data/models/auth_result_model.dart';
import 'package:nexora/features/auth/data/models/module_access_model.dart';
import 'package:nexora/features/auth/data/models/user_model.dart';
import 'package:nexora/features/auth/data/repositories/auth_repository_impl.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource dataSource;

  setUp(() {
    dataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(remoteDataSource: dataSource);
  });

  const tUsername = 'user@example.com';
  const tPassword = 'secret';
  final tAuthResultModel = AuthResultModel(
    accessToken: 'access',
    refreshToken: 'refresh',
    user: UserModel(id: 1, name: 'User', email: tUsername),
    modules: [ModuleAccessModel(module: 'rh', actions: ['ver'])],
  );

  test('deve devolver AuthResultEntity quando o datasource tiver sucesso', () async {
    when(() => dataSource.login(tUsername, tPassword))
        .thenAnswer((_) async => tAuthResultModel);

    final result = await repository.login(tUsername, tPassword);

    expect(result.isRight(), true);
    result.fold(
      (_) => fail('esperado Right'),
      (entity) {
        expect(entity.accessToken, 'access');
        expect(entity.user.email, tUsername);
      },
    );
    verify(() => dataSource.login(tUsername, tPassword)).called(1);
  });

  test('deve devolver ServerFailure quando o datasource lançar excepção', () async {
    when(() => dataSource.login(tUsername, tPassword))
        .thenThrow(Exception('erro'));

    final result = await repository.login(tUsername, tPassword);

    expect(result, isA<Left<Failure, dynamic>>());
  });
}
