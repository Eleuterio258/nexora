import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_student_presencas_usecase.dart';
import 'student_presencas_state.dart';

class StudentPresencasCubit extends Cubit<StudentPresencasState> {
  StudentPresencasCubit(this._useCase) : super(const StudentPresencasInitial());

  final GetStudentPresencasUseCase _useCase;

  Future<void> load({String? mes, int page = 1}) async {
    emit(const StudentPresencasLoading());
    try {
      final data = await _useCase(mes: mes, page: page);
      emit(StudentPresencasLoaded(data));
    } catch (e) {
      emit(StudentPresencasError(e.toString()));
    }
  }
}
