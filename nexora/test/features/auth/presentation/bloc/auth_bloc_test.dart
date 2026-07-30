import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexora/core/errors/failures.dart';
import 'package:nexora/core/services/session_manager.dart';
import 'package:nexora/features/auth/domain/entities/auth_result_entity.dart';
import 'package:nexora/features/auth/domain/entities/module_access_entity.dart';
import 'package:nexora/features/auth/domain/entities/user_entity.dart';
import 'package:nexora/features/auth/domain/usecases/login_usecase.dart';
import 'package:nexora/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nexora/features/auth/presentation/bloc/auth_event.dart';
import 'package:nexora/features/auth/presentation/bloc/auth_state.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockSessionManager extends Mock implements SessionManager {}

void main() {
  late AuthBloc bloc;
  late MockLoginUseCase loginUseCase;
  late MockSessionManager sessionManager;

  setUp(() {
    loginUseCase = MockLoginUseCase();
    sessionManager = MockSessionManager();
    bloc = AuthBloc(loginUseCase: loginUseCase, sessionManager: sessionManager);
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

  tearDown(() => bloc.close());

  group('AppStarted', () {
    blocTest<AuthBloc, AuthState>(
      'emite AuthAuthenticated quando já existe sessão',
      setUp: () {
        when(() => sessionManager.isLoggedIn).thenReturn(true);
        when(() => sessionManager.user).thenReturn(null);
      },
      build: () => bloc,
      act: (bloc) => bloc.add(AppStarted()),
      expect: () => [AuthUnauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'emite AuthUnauthenticated quando não existe sessão',
      setUp: () {
        when(() => sessionManager.isLoggedIn).thenReturn(false);
      },
      build: () => bloc,
      act: (bloc) => bloc.add(AppStarted()),
      expect: () => [AuthUnauthenticated()],
    );
  });

  group('LoginSubmitted', () {
    blocTest<AuthBloc, AuthState>(
      'emite AuthAuthenticated quando o login é bem-sucedido',
      setUp: () {
        when(() => loginUseCase(const LoginParams(
              username: tUsername,
              password: tPassword,
            ))).thenAnswer((_) async => const Right(tAuthResult));
        when(() => sessionManager.saveSession(tAuthResult))
            .thenAnswer((_) async {});
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const LoginSubmitted(
        username: tUsername,
        password: tPassword,
      )),
      expect: () => [
        AuthLoading(),
        const AuthAuthenticated(user: tUser),
      ],
      verify: (_) {
        verify(() => sessionManager.saveSession(tAuthResult)).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emite AuthFailure quando o login falha',
      setUp: () {
        when(() => loginUseCase(const LoginParams(
              username: tUsername,
              password: tPassword,
            ))).thenAnswer((_) async => const Left(ServerFailure()));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const LoginSubmitted(
        username: tUsername,
        password: tPassword,
      )),
      expect: () => [
        AuthLoading(),
        const AuthFailure(message: 'Ocorreu um erro inesperado.'),
      ],
    );
  });

  group('LogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'limpa a sessão e emite AuthUnauthenticated',
      setUp: () {
        when(() => sessionManager.clear()).thenAnswer((_) async {});
      },
      build: () => bloc,
      act: (bloc) => bloc.add(LogoutRequested()),
      expect: () => [AuthUnauthenticated()],
      verify: (_) {
        verify(() => sessionManager.clear()).called(1);
      },
    );
  });
}
