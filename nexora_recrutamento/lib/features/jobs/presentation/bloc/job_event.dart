import 'package:equatable/equatable.dart';

abstract class JobEvent extends Equatable {
  const JobEvent();
}

class JobsLoadRequested extends JobEvent {
  final String? category;
  final String? query;
  const JobsLoadRequested({this.category, this.query});
  @override
  List<Object?> get props => [category, query];
}

class JobRefreshRequested extends JobEvent {
  const JobRefreshRequested();
  @override
  List<Object?> get props => [];
}

class JobSaveToggled extends JobEvent {
  final int jobId;
  final bool save;
  const JobSaveToggled({required this.jobId, required this.save});
  @override
  List<Object> get props => [jobId, save];
}

class JobDetailRequested extends JobEvent {
  final int jobId;
  const JobDetailRequested(this.jobId);
  @override
  List<Object> get props => [jobId];
}
