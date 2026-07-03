import 'package:equatable/equatable.dart';

const kServerFailureMessage = 'Erro no servidor. Tente novamente mais tarde.';
const kOfflineFailureMessage = 'Sem conexão. Verifique a internet.';
const kInvalidCredentialsMessage = 'Email ou palavra-passe incorrectos.';
const kInvalidInputMessage = 'Dados inválidos. Verifique os campos.';
const kEmptyCacheMessage = 'Sem dados disponíveis.';
const kUnauthorizedMessage = 'Sessão expirada. Faça login novamente.';

sealed class Failure extends Equatable {
  @override
  List<Object?> get props => [];
}

class ServerFailure extends Failure {}

class OfflineFailure extends Failure {}

class InvalidCredentialsFailure extends Failure {}

class InvalidInputFailure extends Failure {}

class UnauthorizedFailure extends Failure {}

class EmptyCacheFailure extends Failure {}

class UnknownFailure extends Failure {
  UnknownFailure(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
