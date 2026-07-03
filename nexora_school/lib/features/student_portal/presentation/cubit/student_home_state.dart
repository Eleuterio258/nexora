import '../../domain/entities/student_home_data.dart';

sealed class StudentHomeState {
  const StudentHomeState();
}

class StudentHomeInitial extends StudentHomeState {
  const StudentHomeInitial();
}

class StudentHomeLoading extends StudentHomeState {
  const StudentHomeLoading();
}

class StudentHomeLoaded extends StudentHomeState {
  const StudentHomeLoaded(this.data);

  final StudentHomeData data;
}

class StudentHomeError extends StudentHomeState {
  const StudentHomeError(this.message);

  final String message;
}
