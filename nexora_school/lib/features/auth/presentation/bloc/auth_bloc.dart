import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../../branding/presentation/controllers/branding_controller.dart';
import '../../domain/usecases/login_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required LoginUseCase loginUseCase,
    required BrandingController brandingController,
  })  : _loginUseCase = loginUseCase,
        _brandingController = brandingController,
        super(const AuthInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
  }

  final LoginUseCase _loginUseCase;
  final BrandingController _brandingController;

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _loginUseCase(
      LoginParams(email: event.email, password: event.password),
    );
    await result.fold(
      (failure) async => emit(AuthError(_failureMessage(failure))),
      (user) async {
        // Actualiza o branding em background logo após autenticação.
        await _brandingController.refreshOrCache();
        emit(AuthSuccess(user));
      },
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
