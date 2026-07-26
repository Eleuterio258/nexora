import 'package:equatable/equatable.dart';
import '../../data/models/education_model.dart';

abstract class EducationEvent extends Equatable {
  const EducationEvent();

  @override
  List<Object?> get props => [];
}

class EducationsLoadRequested extends EducationEvent {
  const EducationsLoadRequested();
}

class EducationCreated extends EducationEvent {
  final EducationModel education;

  const EducationCreated(this.education);

  @override
  List<Object?> get props => [education];
}

class EducationUpdated extends EducationEvent {
  final int id;
  final EducationModel education;

  const EducationUpdated(this.id, this.education);

  @override
  List<Object?> get props => [id, education];
}

class EducationDeleted extends EducationEvent {
  final int id;

  const EducationDeleted(this.id);

  @override
  List<Object?> get props => [id];
}
