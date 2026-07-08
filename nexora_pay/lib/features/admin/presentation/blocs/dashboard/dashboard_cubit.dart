import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/dashboard_summary.dart';
import '../../../data/repositories/admin_repository.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._repository) : super(const DashboardLoading());

  final AdminRepository _repository;

  Future<void> load() async {
    emit(const DashboardLoading());
    try {
      final summary = await _repository.getDashboardSummary();
      emit(DashboardLoaded(summary));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
