import 'package:equatable/equatable.dart';
import '../../data/models/education_model.dart';

abstract class EducationState extends Equatable {
  const EducationState();

  @override
  List<Object?> get props => [];
}

class EducationInitial extends EducationState {
  const EducationInitial();
}

class EducationLoading extends EducationState {
  const EducationLoading();
}

class EducationsLoaded extends EducationState {
  final List<EducationModel> educations;

  const EducationsLoaded(this.educations);

  @override
  List<Object?> get props => [educations];
}

class EducationFailure extends EducationState {
  final String message;

  const EducationFailure(this.message);

  @override
  List<Object?> get props => [message];
}
