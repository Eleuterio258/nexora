import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_student_mensagens_usecase.dart';
import 'student_mensagens_state.dart';

class StudentMensagensCubit extends Cubit<StudentMensagensState> {
  StudentMensagensCubit(this._useCase) : super(const StudentMensagensInitial());

  final GetStudentMensagensUseCase _useCase;

  Future<void> load() async {
    emit(const StudentMensagensLoading());
    try {
      final mensagens = await _useCase();
      emit(StudentMensagensLoaded(mensagens));
    } catch (e) {
      emit(StudentMensagensError(e.toString()));
    }
  }
}
