import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/create_education.dart';
import '../../domain/usecases/delete_education.dart';
import '../../domain/usecases/get_educations.dart';
import '../../domain/usecases/update_education.dart';
import 'education_event.dart';
import 'education_state.dart';

export 'education_event.dart';
export 'education_state.dart';

class EducationBloc extends Bloc<EducationEvent, EducationState> {
  final GetEducations _getEducations;
  final CreateEducation _createEducation;
  final UpdateEducation _updateEducation;
  final DeleteEducation _deleteEducation;

  EducationBloc({
    required GetEducations getEducations,
    required CreateEducation createEducation,
    required UpdateEducation updateEducation,
    required DeleteEducation deleteEducation,
  })  : _getEducations = getEducations,
        _createEducation = createEducation,
        _updateEducation = updateEducation,
        _deleteEducation = deleteEducation,
        super(const EducationInitial()) {
    on<EducationsLoadRequested>(_onLoad);
    on<EducationCreated>(_onCreate);
    on<EducationUpdated>(_onUpdate);
    on<EducationDeleted>(_onDelete);
  }

  Future<void> _onLoad(
    EducationsLoadRequested event,
    Emitter<EducationState> emit,
  ) async {
    emit(const EducationLoading());
    final result = await _getEducations(const NoParams());
    result.fold(
      (failure) => emit(EducationFailure(failure.message)),
      (educations) => emit(EducationsLoaded(educations)),
    );
  }

  Future<void> _onCreate(
    EducationCreated event,
    Emitter<EducationState> emit,
  ) async {
    emit(const EducationLoading());
    final result = await _createEducation(event.education);
    await result.fold(
      (failure) async => emit(EducationFailure(failure.message)),
      (_) async => add(const EducationsLoadRequested()),
    );
  }

  Future<void> _onUpdate(
    EducationUpdated event,
    Emitter<EducationState> emit,
  ) async {
    emit(const EducationLoading());
    final result = await _updateEducation(
      UpdateEducationParams(id: event.id, education: event.education),
    );
    await result.fold(
      (failure) async => emit(EducationFailure(failure.message)),
      (_) async => add(const EducationsLoadRequested()),
    );
  }

  Future<void> _onDelete(
    EducationDeleted event,
    Emitter<EducationState> emit,
  ) async {
    final currentState = state;
    if (currentState is EducationsLoaded) {
      final updated = currentState.educations
          .where((e) => e.id != event.id)
          .toList();
      emit(EducationsLoaded(updated));
    }

    final result = await _deleteEducation(event.id);
    result.fold(
      (failure) => emit(EducationFailure(failure.message)),
      (_) {},
    );
  }
}
