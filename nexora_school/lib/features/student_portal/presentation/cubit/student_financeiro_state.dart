import '../../domain/entities/student_financeiro_data.dart';

sealed class StudentFinanceiroState {
  const StudentFinanceiroState();
}

class StudentFinanceiroInitial extends StudentFinanceiroState {
  const StudentFinanceiroInitial();
}

class StudentFinanceiroLoading extends StudentFinanceiroState {
  const StudentFinanceiroLoading();
}

class StudentFinanceiroLoaded extends StudentFinanceiroState {
  const StudentFinanceiroLoaded(this.data);

  final StudentFinanceiroData data;
}

class StudentFinanceiroError extends StudentFinanceiroState {
  const StudentFinanceiroError(this.message);

  final String message;
}
