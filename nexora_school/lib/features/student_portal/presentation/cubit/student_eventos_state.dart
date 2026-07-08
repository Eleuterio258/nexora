import '../../domain/entities/student_evento.dart';

sealed class StudentEventosState {}

class StudentEventosInitial extends StudentEventosState {}

class StudentEventosLoading extends StudentEventosState {}

class StudentEventosLoaded extends StudentEventosState {
  StudentEventosLoaded(this.eventos);
  final List<StudentEvento> eventos;
}

class StudentEventosError extends StudentEventosState {
  StudentEventosError(this.message);
  final String message;
}
