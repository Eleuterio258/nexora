import 'package:equatable/equatable.dart';
import '../../domain/entities/job.dart';

abstract class JobEvent extends Equatable {
  const JobEvent();
}

class JobsLoadRequested extends JobEvent {
  final String? category;
  final String? query;
  final int? tenantId;
  const JobsLoadRequested({this.category, this.query, this.tenantId});
  @override
  List<Object?> get props => [category, query, tenantId];
}

class JobRefreshRequested extends JobEvent {
  const JobRefreshRequested();
  @override
  List<Object?> get props => [];
}

class JobSaveToggled extends JobEvent {
  final Job job;
  final bool save;
  const JobSaveToggled({required this.job, required this.save});
  @override
  List<Object> get props => [job, save];
}

class JobDetailRequested extends JobEvent {
  final int jobId;
  const JobDetailRequested(this.jobId);
  @override
  List<Object> get props => [jobId];
}
