import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_student_eventos_usecase.dart';
import 'student_eventos_state.dart';

class StudentEventosCubit extends Cubit<StudentEventosState> {
  StudentEventosCubit(this._useCase) : super(StudentEventosInitial());
  final GetStudentEventosUseCase _useCase;

  Future<void> load() async {
    emit(StudentEventosLoading());
    try {
      final eventos = await _useCase();
      emit(StudentEventosLoaded(eventos));
    } catch (_) {
      emit(StudentEventosError('Erro ao carregar calendário'));
    }
  }
}
