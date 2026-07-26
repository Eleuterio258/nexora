import 'package:equatable/equatable.dart';
import '../../data/models/experience_model.dart';

abstract class ExperienceState extends Equatable {
  const ExperienceState();

  @override
  List<Object?> get props => [];
}

class ExperienceInitial extends ExperienceState {
  const ExperienceInitial();
}

class ExperienceLoading extends ExperienceState {
  const ExperienceLoading();
}

class ExperiencesLoaded extends ExperienceState {
  final List<ExperienceModel> experiences;

  const ExperiencesLoaded(this.experiences);

  @override
  List<Object?> get props => [experiences];
}

class ExperienceFailure extends ExperienceState {
  final String message;

  const ExperienceFailure(this.message);

  @override
  List<Object?> get props => [message];
}
