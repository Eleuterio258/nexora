import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_applications.dart';
import '../../domain/usecases/submit_application.dart';
import '../../../../core/usecases/usecase.dart';
import 'application_event.dart';
import 'application_state.dart';

export 'application_event.dart';
export 'application_state.dart';

class ApplicationBloc extends Bloc<ApplicationEvent, ApplicationState> {
  final GetApplications _getApplications;
  final SubmitApplication _submitApplication;

  ApplicationBloc({
    required GetApplications getApplications,
    required SubmitApplication submitApplication,
  })  : _getApplications = getApplications,
        _submitApplication = submitApplication,
        super(const ApplicationInitial()) {
    on<ApplicationsLoadRequested>(_onLoad);
    on<ApplicationSubmitRequested>(_onSubmit);
  }

  Future<void> _onLoad(
      ApplicationsLoadRequested event, Emitter<ApplicationState> emit) async {
    emit(const ApplicationLoading());
    final result = await _getApplications(const NoParams());
    result.fold(
      (f) => emit(ApplicationFailureState(f.message)),
      (apps) => emit(ApplicationsLoaded(apps)),
    );
  }

  Future<void> _onSubmit(
      ApplicationSubmitRequested event, Emitter<ApplicationState> emit) async {
    emit(const ApplicationLoading());
    final result = await _submitApplication(
      SubmitApplicationParams(
        jobId: event.jobId,
        coverLetter: event.coverLetter,
      ),
    );
    result.fold(
      (f) => emit(ApplicationFailureState(f.message)),
      (app) => emit(ApplicationSubmitted(app)),
    );
  }
}
