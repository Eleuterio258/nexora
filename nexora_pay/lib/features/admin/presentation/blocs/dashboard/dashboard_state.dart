part of 'dashboard_cubit.dart';

sealed class DashboardState {
  const DashboardState();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  const DashboardLoaded(this.summary);

  final DashboardSummary summary;
}

class DashboardError extends DashboardState {
  const DashboardError(this.message);

  final String message;
}
