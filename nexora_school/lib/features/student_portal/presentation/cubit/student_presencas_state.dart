import '../../domain/entities/student_presencas_data.dart';

sealed class StudentPresencasState {
  const StudentPresencasState();
}

class StudentPresencasInitial extends StudentPresencasState {
  const StudentPresencasInitial();
}

class StudentPresencasLoading extends StudentPresencasState {
  const StudentPresencasLoading();
}

class StudentPresencasLoaded extends StudentPresencasState {
  const StudentPresencasLoaded(this.data);

  final StudentPresencasData data;
}

class StudentPresencasError extends StudentPresencasState {
  const StudentPresencasError(this.message);

  final String message;
}
