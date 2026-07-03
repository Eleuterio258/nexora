import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_student_financeiro_usecase.dart';
import 'student_financeiro_state.dart';

class StudentFinanceiroCubit extends Cubit<StudentFinanceiroState> {
  StudentFinanceiroCubit(this._useCase) : super(const StudentFinanceiroInitial());

  final GetStudentFinanceiroUseCase _useCase;

  Future<void> load({String? status}) async {
    emit(const StudentFinanceiroLoading());
    try {
      final data = await _useCase(status: status);
      emit(StudentFinanceiroLoaded(data));
    } catch (e) {
      emit(StudentFinanceiroError(e.toString()));
    }
  }
}
