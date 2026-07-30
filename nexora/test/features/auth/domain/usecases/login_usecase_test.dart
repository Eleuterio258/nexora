import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexora/core/errors/failures.dart';
import 'package:nexora/features/auth/domain/entities/auth_result_entity.dart';
import 'package:nexora/features/auth/domain/entities/module_access_entity.dart';
import 'package:nexora/features/auth/domain/entities/user_entity.dart';
import 'package:nexora/features/auth/domain/repositories/auth_repository.dart';
import 'package:nexora/features/auth/domain/usecases/login_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginUseCase useCase;
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
    useCase = LoginUseCase(repository);
  });

  const tUsername = 'user@example.com';
  const tPassword = 'secret';
  const tUser = UserEntity(id: 1, name: 'User', email: tUsername);
  const tAuthResult = AuthResultEntity(
    user: tUser,
    modules: [ModuleAccessEntity(module: 'rh', actions: ['ver'])],
    accessToken: 'access',
    refreshToken: 'refresh',
  );

  test('deve devolver AuthResultEntity quando o login for bem-sucedido', () async {
    when(() => repository.login(tUsername, tPassword))
        .thenAnswer((_) async => const Right(tAuthResult));

    final result = await useCase(
      const LoginParams(username: tUsername, password: tPassword),
    );

    expect(result, const Right(tAuthResult));
    verify(() => repository.login(tUsername, tPassword)).called(1);
  });

  test('deve devolver Failure quando o login falhar', () async {
    when(() => repository.login(tUsername, tPassword))
        .thenAnswer((_) async => const Left(ServerFailure()));

    final result = await useCase(
      const LoginParams(username: tUsername, password: tPassword),
    );

    expect(result, const Left(ServerFailure()));
    verify(() => repository.login(tUsername, tPassword)).called(1);
  });
}
