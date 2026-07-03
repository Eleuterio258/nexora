import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_student_boletim_usecase.dart';
import 'student_boletim_state.dart';

class StudentBoletimCubit extends Cubit<StudentBoletimState> {
  StudentBoletimCubit(this._useCase) : super(const StudentBoletimInitial());

  final GetStudentBoletimUseCase _useCase;

  Future<void> load({int? termId}) async {
    emit(const StudentBoletimLoading());
    try {
      final data = await _useCase(termId: termId);
      emit(StudentBoletimLoaded(data));
    } catch (e) {
      emit(StudentBoletimError(e.toString()));
    }
  }
}
