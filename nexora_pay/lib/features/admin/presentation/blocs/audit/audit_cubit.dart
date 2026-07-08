import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/audit_log.dart';
import '../../../data/repositories/admin_repository.dart';

part 'audit_state.dart';

class AuditCubit extends Cubit<AuditState> {
  AuditCubit(this._repository) : super(const AuditLoading());

  final AdminRepository _repository;

  Future<void> load() async {
    emit(const AuditLoading());
    try {
      final logs = await _repository.getAuditLogs();
      emit(AuditLoaded(logs));
    } catch (e) {
      emit(AuditError(e.toString()));
    }
  }

  void filter(String query) {
    final current = state;
    if (current is! AuditLoaded) return;

    final normalized = query.toLowerCase().trim();
    final filtered = current.logs.where((log) {
      return log.userName.toLowerCase().contains(normalized) ||
          log.action.toLowerCase().contains(normalized) ||
          log.target.toLowerCase().contains(normalized);
    }).toList();

    emit(AuditLoaded(current.logs, filtered: filtered, query: query));
  }
}
