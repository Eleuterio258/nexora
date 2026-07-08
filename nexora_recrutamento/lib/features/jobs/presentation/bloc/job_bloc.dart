import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_jobs.dart';
import '../../domain/usecases/toggle_save_job.dart';
import 'job_event.dart';
import 'job_state.dart';

export 'job_event.dart';
export 'job_state.dart';

class JobBloc extends Bloc<JobEvent, JobState> {
  final GetJobs _getJobs;
  final ToggleSaveJob _toggleSave;

  JobBloc({required GetJobs getJobs, required ToggleSaveJob toggleSave})
      : _getJobs = getJobs,
        _toggleSave = toggleSave,
        super(const JobInitial()) {
    on<JobsLoadRequested>(_onLoad);
    on<JobRefreshRequested>(_onRefresh);
    on<JobSaveToggled>(_onSaveToggle);
  }

  Future<void> _onLoad(JobsLoadRequested event, Emitter<JobState> emit) async {
    emit(const JobLoading());
    final result = await _getJobs(GetJobsParams(
        category: event.category, query: event.query, tenantId: event.tenantId));
    result.fold(
      (f) => emit(JobFailureState(f.message)),
      (jobs) => emit(JobsLoaded(jobs,
          activeCategory: event.category, tenantId: event.tenantId)),
    );
  }

  Future<void> _onRefresh(
      JobRefreshRequested event, Emitter<JobState> emit) async {
    final current = state;
    final category = current is JobsLoaded ? current.activeCategory : null;
    final tenantId = current is JobsLoaded ? current.tenantId : null;
    add(JobsLoadRequested(category: category, tenantId: tenantId));
  }

  Future<void> _onSaveToggle(
      JobSaveToggled event, Emitter<JobState> emit) async {
    await _toggleSave(
        ToggleSaveJobParams(job: event.job, save: event.save));
    // Update the saved flag in the current list optimistically
    if (state is JobsLoaded) {
      final current = state as JobsLoaded;
      final updated = current.jobs
          .map((j) =>
              j.id == event.job.id ? j.copyWith(isSaved: event.save) : j)
          .toList();
      emit(JobsLoaded(updated, activeCategory: current.activeCategory));
    }
  }
}
