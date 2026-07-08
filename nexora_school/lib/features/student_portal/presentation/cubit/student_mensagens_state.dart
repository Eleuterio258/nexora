import '../../domain/entities/student_mensagem.dart';

sealed class StudentMensagensState {
  const StudentMensagensState();
}

class StudentMensagensInitial extends StudentMensagensState {
  const StudentMensagensInitial();
}

class StudentMensagensLoading extends StudentMensagensState {
  const StudentMensagensLoading();
}

class StudentMensagensLoaded extends StudentMensagensState {
  const StudentMensagensLoaded(this.mensagens);
  final List<StudentMensagem> mensagens;
}

class StudentMensagensError extends StudentMensagensState {
  const StudentMensagensError(this.message);
  final String message;
}
