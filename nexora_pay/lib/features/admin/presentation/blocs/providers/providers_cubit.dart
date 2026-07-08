import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/provider.dart';
import '../../../data/repositories/admin_repository.dart';

part 'providers_state.dart';

class ProvidersCubit extends Cubit<ProvidersState> {
  ProvidersCubit(this._repository) : super(const ProvidersLoading());

  final AdminRepository _repository;

  Future<void> load() async {
    emit(const ProvidersLoading());
    try {
      final providers = await _repository.getProviders();
      emit(ProvidersLoaded(providers));
    } catch (e) {
      emit(ProvidersError(e.toString()));
    }
  }

  Future<void> toggleStatus(String id) async {
    final current = state;
    if (current is! ProvidersLoaded) return;

    final provider = current.providers.firstWhere((p) => p.id == id);
    final newStatus = provider.status == ProviderStatus.active
        ? ProviderStatus.inactive
        : ProviderStatus.active;

    try {
      final updated = await _repository.updateProviderStatus(id, newStatus);
      final list = current.providers
          .map((p) => p.id == updated.id ? updated : p)
          .toList();
      emit(ProvidersLoaded(list));
    } catch (e) {
      emit(ProvidersError(e.toString()));
    }
  }
}
