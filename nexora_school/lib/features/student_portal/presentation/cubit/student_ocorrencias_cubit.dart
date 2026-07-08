import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_student_ocorrencias_usecase.dart';
import 'student_ocorrencias_state.dart';

class StudentOcorrenciasCubit extends Cubit<StudentOcorrenciasState> {
  StudentOcorrenciasCubit(this._useCase) : super(StudentOcorrenciasInitial());
  final GetStudentOcorrenciasUseCase _useCase;

  Future<void> load() async {
    emit(StudentOcorrenciasLoading());
    try {
      final data = await _useCase();
      emit(StudentOcorrenciasLoaded(data));
    } catch (_) {
      emit(StudentOcorrenciasError('Erro ao carregar ocorrências'));
    }
  }
}
