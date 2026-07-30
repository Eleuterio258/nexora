import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/session_manager.dart';
import 'package:nexora/features/auth/domain/usecases/login_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final SessionManager sessionManager;

  AuthBloc({required this.loginUseCase, required this.sessionManager})
      : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    if (sessionManager.isLoggedIn && sessionManager.user != null) {
      emit(AuthAuthenticated(user: sessionManager.user!.toEntity()));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await loginUseCase(
      LoginParams(username: event.username, password: event.password),
    );

    await result.fold(
      (failure) async => emit(AuthFailure(message: failure.message)),
      (authResult) async {
        await sessionManager.saveSession(authResult);
        emit(AuthAuthenticated(user: authResult.user));
      },
    );
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await sessionManager.clear();
    emit(AuthUnauthenticated());
  }
}
