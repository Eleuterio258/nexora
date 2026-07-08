import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_student_turma_usecase.dart';
import 'student_turma_state.dart';

class StudentTurmaCubit extends Cubit<StudentTurmaState> {
  StudentTurmaCubit(this._useCase) : super(StudentTurmaInitial());
  final GetStudentTurmaUseCase _useCase;

  Future<void> load() async {
    emit(StudentTurmaLoading());
    try {
      final data = await _useCase();
      emit(StudentTurmaLoaded(data));
    } catch (_) {
      emit(StudentTurmaError('Erro ao carregar turma'));
    }
  }
}
