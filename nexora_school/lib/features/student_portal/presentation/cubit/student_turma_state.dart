import '../../domain/entities/student_turma_data.dart';

sealed class StudentTurmaState {}

class StudentTurmaInitial extends StudentTurmaState {}

class StudentTurmaLoading extends StudentTurmaState {}

class StudentTurmaLoaded extends StudentTurmaState {
  StudentTurmaLoaded(this.data);
  final StudentTurmaData data;
}

class StudentTurmaError extends StudentTurmaState {
  StudentTurmaError(this.message);
  final String message;
}
