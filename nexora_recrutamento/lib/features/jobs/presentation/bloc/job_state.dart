import 'package:equatable/equatable.dart';
import '../../domain/entities/job.dart';

abstract class JobState extends Equatable {
  const JobState();
}

class JobInitial extends JobState {
  const JobInitial();
  @override
  List<Object?> get props => [];
}

class JobLoading extends JobState {
  const JobLoading();
  @override
  List<Object?> get props => [];
}

class JobsLoaded extends JobState {
  final List<Job> jobs;
  final String? activeCategory;
  final int? tenantId;
  const JobsLoaded(this.jobs, {this.activeCategory, this.tenantId});
  @override
  List<Object?> get props => [jobs, activeCategory, tenantId];
}

class JobDetailLoaded extends JobState {
  final Job job;
  const JobDetailLoaded(this.job);
  @override
  List<Object?> get props => [job];
}

class JobFailureState extends JobState {
  final String message;
  const JobFailureState(this.message);
  @override
  List<Object?> get props => [message];
}
