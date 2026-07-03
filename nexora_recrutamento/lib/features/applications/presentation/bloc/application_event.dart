import 'package:equatable/equatable.dart';

abstract class ApplicationEvent extends Equatable {
  const ApplicationEvent();
}

class ApplicationsLoadRequested extends ApplicationEvent {
  const ApplicationsLoadRequested();
  @override
  List<Object?> get props => [];
}

class ApplicationSubmitRequested extends ApplicationEvent {
  final int jobId;
  final String coverLetter;
  const ApplicationSubmitRequested({
    required this.jobId,
    required this.coverLetter,
  });
  @override
  List<Object> get props => [jobId, coverLetter];
}
