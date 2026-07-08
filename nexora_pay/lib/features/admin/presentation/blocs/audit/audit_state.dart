part of 'audit_cubit.dart';

sealed class AuditState {
  const AuditState();
}

class AuditLoading extends AuditState {
  const AuditLoading();
}

class AuditLoaded extends AuditState {
  const AuditLoaded(
    this.logs, {
    this.filtered,
    this.query = '',
  });

  final List<AuditLog> logs;
  final List<AuditLog>? filtered;
  final String query;

  List<AuditLog> get visible => filtered ?? logs;
}

class AuditError extends AuditState {
  const AuditError(this.message);

  final String message;
}
