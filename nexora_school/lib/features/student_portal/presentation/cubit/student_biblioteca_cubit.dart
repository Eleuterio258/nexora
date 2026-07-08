import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_student_biblioteca_usecase.dart';
import 'student_biblioteca_state.dart';

class StudentBibliotecaCubit extends Cubit<StudentBibliotecaState> {
  StudentBibliotecaCubit(this._useCase) : super(StudentBibliotecaInitial());
  final GetStudentBibliotecaUseCase _useCase;

  Future<void> load() async {
    emit(StudentBibliotecaLoading());
    try {
      final data = await _useCase();
      final records = data['records'] as List<dynamic>? ?? [];
      final total = (data['total'] ?? records.length) as int;
      emit(StudentBibliotecaLoaded(records, total));
    } catch (_) {
      emit(StudentBibliotecaError('Erro ao carregar biblioteca'));
    }
  }
}
