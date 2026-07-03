import 'package:equatable/equatable.dart';
import '../../domain/entities/application.dart';

abstract class ApplicationState extends Equatable {
  const ApplicationState();
}

class ApplicationInitial extends ApplicationState {
  const ApplicationInitial();
  @override
  List<Object?> get props => [];
}

class ApplicationLoading extends ApplicationState {
  const ApplicationLoading();
  @override
  List<Object?> get props => [];
}

class ApplicationsLoaded extends ApplicationState {
  final List<Application> applications;
  const ApplicationsLoaded(this.applications);
  @override
  List<Object?> get props => [applications];
}

class ApplicationSubmitted extends ApplicationState {
  final Application application;
  const ApplicationSubmitted(this.application);
  @override
  List<Object?> get props => [application];
}

class ApplicationFailureState extends ApplicationState {
  final String message;
  const ApplicationFailureState(this.message);
  @override
  List<Object?> get props => [message];
}
