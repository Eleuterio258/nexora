import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/create_experience.dart';
import '../../domain/usecases/delete_experience.dart';
import '../../domain/usecases/get_experiences.dart';
import '../../domain/usecases/update_experience.dart';
import 'experience_event.dart';
import 'experience_state.dart';

export 'experience_event.dart';
export 'experience_state.dart';

class ExperienceBloc extends Bloc<ExperienceEvent, ExperienceState> {
  final GetExperiences _getExperiences;
  final CreateExperience _createExperience;
  final UpdateExperience _updateExperience;
  final DeleteExperience _deleteExperience;

  ExperienceBloc({
    required GetExperiences getExperiences,
    required CreateExperience createExperience,
    required UpdateExperience updateExperience,
    required DeleteExperience deleteExperience,
  })  : _getExperiences = getExperiences,
        _createExperience = createExperience,
        _updateExperience = updateExperience,
        _deleteExperience = deleteExperience,
        super(const ExperienceInitial()) {
    on<ExperiencesLoadRequested>(_onLoad);
    on<ExperienceCreated>(_onCreate);
    on<ExperienceUpdated>(_onUpdate);
    on<ExperienceDeleted>(_onDelete);
  }

  Future<void> _onLoad(
    ExperiencesLoadRequested event,
    Emitter<ExperienceState> emit,
  ) async {
    emit(const ExperienceLoading());
    final result = await _getExperiences(const NoParams());
    result.fold(
      (failure) => emit(ExperienceFailure(failure.message)),
      (experiences) => emit(ExperiencesLoaded(experiences)),
    );
  }

  Future<void> _onCreate(
    ExperienceCreated event,
    Emitter<ExperienceState> emit,
  ) async {
    emit(const ExperienceLoading());
    final result = await _createExperience(event.experience);
    await result.fold(
      (failure) async => emit(ExperienceFailure(failure.message)),
      (_) async => add(const ExperiencesLoadRequested()),
    );
  }

  Future<void> _onUpdate(
    ExperienceUpdated event,
    Emitter<ExperienceState> emit,
  ) async {
    emit(const ExperienceLoading());
    final result = await _updateExperience(
      UpdateExperienceParams(id: event.id, experience: event.experience),
    );
    await result.fold(
      (failure) async => emit(ExperienceFailure(failure.message)),
      (_) async => add(const ExperiencesLoadRequested()),
    );
  }

  Future<void> _onDelete(
    ExperienceDeleted event,
    Emitter<ExperienceState> emit,
  ) async {
    final currentState = state;
    if (currentState is ExperiencesLoaded) {
      final updated = currentState.experiences
          .where((e) => e.id != event.id)
          .toList();
      emit(ExperiencesLoaded(updated));
    }

    final result = await _deleteExperience(event.id);
    result.fold(
      (failure) => emit(ExperienceFailure(failure.message)),
      (_) {},
    );
  }
}
