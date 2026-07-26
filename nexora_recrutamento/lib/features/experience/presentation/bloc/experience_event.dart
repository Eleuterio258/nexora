import 'package:equatable/equatable.dart';
import '../../data/models/experience_model.dart';

abstract class ExperienceEvent extends Equatable {
  const ExperienceEvent();

  @override
  List<Object?> get props => [];
}

class ExperiencesLoadRequested extends ExperienceEvent {
  const ExperiencesLoadRequested();
}

class ExperienceCreated extends ExperienceEvent {
  final ExperienceModel experience;

  const ExperienceCreated(this.experience);

  @override
  List<Object?> get props => [experience];
}

class ExperienceUpdated extends ExperienceEvent {
  final int id;
  final ExperienceModel experience;

  const ExperienceUpdated(this.id, this.experience);

  @override
  List<Object?> get props => [id, experience];
}

class ExperienceDeleted extends ExperienceEvent {
  final int id;

  const ExperienceDeleted(this.id);

  @override
  List<Object?> get props => [id];
}
