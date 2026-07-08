import '../../domain/entities/student_noticia.dart';

sealed class StudentNoticiasState {}

class StudentNoticiasInitial extends StudentNoticiasState {}

class StudentNoticiasLoading extends StudentNoticiasState {}

class StudentNoticiasLoaded extends StudentNoticiasState {
  StudentNoticiasLoaded(this.data);
  final StudentNoticiasData data;
}

class StudentNoticiasError extends StudentNoticiasState {
  StudentNoticiasError(this.message);
  final String message;
}
