import '../../domain/entities/student_boletim_data.dart';

sealed class StudentBoletimState {
  const StudentBoletimState();
}

class StudentBoletimInitial extends StudentBoletimState {
  const StudentBoletimInitial();
}

class StudentBoletimLoading extends StudentBoletimState {
  const StudentBoletimLoading();
}

class StudentBoletimLoaded extends StudentBoletimState {
  const StudentBoletimLoaded(this.data);

  final StudentBoletimData data;
}

class StudentBoletimError extends StudentBoletimState {
  const StudentBoletimError(this.message);

  final String message;
}
