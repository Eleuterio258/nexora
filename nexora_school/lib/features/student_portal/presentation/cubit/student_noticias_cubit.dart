import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_student_noticias_usecase.dart';
import 'student_noticias_state.dart';

class StudentNoticiasCubit extends Cubit<StudentNoticiasState> {
  StudentNoticiasCubit(this._useCase) : super(StudentNoticiasInitial());
  final GetStudentNoticiasUseCase _useCase;

  Future<void> load() async {
    emit(StudentNoticiasLoading());
    try {
      final data = await _useCase();
      emit(StudentNoticiasLoaded(data));
    } catch (_) {
      emit(StudentNoticiasError('Erro ao carregar notícias'));
    }
  }
}
