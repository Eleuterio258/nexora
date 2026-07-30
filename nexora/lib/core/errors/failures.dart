import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure({this.message = 'Ocorreu um erro inesperado.'});

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure({super.message});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'Sem ligação à rede.'});
}

class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Erro ao aceder aos dados locais.'});
}

class ValidationFailure extends Failure {
  const ValidationFailure({super.message});
}
