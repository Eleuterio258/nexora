import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_student_home_data_usecase.dart';
import 'student_home_state.dart';

class StudentHomeCubit extends Cubit<StudentHomeState> {
  StudentHomeCubit(this._useCase) : super(const StudentHomeInitial());

  final GetStudentHomeDataUseCase _useCase;

  Future<void> load() async {
    emit(const StudentHomeLoading());
    try {
      final data = await _useCase();
      emit(StudentHomeLoaded(data));
    } catch (e) {
      emit(StudentHomeError(e.toString()));
    }
  }
}
