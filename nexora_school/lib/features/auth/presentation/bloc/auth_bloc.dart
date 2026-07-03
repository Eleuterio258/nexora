import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/usecases/login_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required LoginUseCase loginUseCase})
      : _loginUseCase = loginUseCase,
        super(const AuthInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
  }

  final LoginUseCase _loginUseCase;

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _loginUseCase(
      LoginParams(email: event.email, password: event.password),
    );
    result.fold(
      (failure) => emit(AuthError(_failureMessage(failure))),
      (user) => emit(AuthSuccess(user)),
    );
  }

  String _failureMessage(Failure failure) => switch (failure) {
        InvalidCredentialsFailure() => kInvalidCredentialsMessage,
        InvalidInputFailure() => kInvalidInputMessage,
        OfflineFailure() => kOfflineFailureMessage,
        UnauthorizedFailure() => kUnauthorizedMessage,
        EmptyCacheFailure() => kEmptyCacheMessage,
        ServerFailure() => kServerFailureMessage,
        UnknownFailure(:final message) => message,
      };
}
