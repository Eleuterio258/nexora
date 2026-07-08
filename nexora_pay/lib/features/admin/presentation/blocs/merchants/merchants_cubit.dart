import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/merchant.dart';
import '../../../data/repositories/admin_repository.dart';

part 'merchants_state.dart';

class MerchantsCubit extends Cubit<MerchantsState> {
  MerchantsCubit(this._repository) : super(const MerchantsLoading());

  final AdminRepository _repository;

  Future<void> load() async {
    emit(const MerchantsLoading());
    try {
      final merchants = await _repository.getMerchants();
      emit(MerchantsLoaded(merchants));
    } catch (e) {
      emit(MerchantsError(e.toString()));
    }
  }

  Future<void> updateStatus(String id, MerchantStatus status) async {
    final current = state;
    if (current is! MerchantsLoaded) return;

    try {
      final updated = await _repository.updateMerchantStatus(id, status);
      final list = current.merchants
          .map((m) => m.id == updated.id ? updated : m)
          .toList();
      emit(MerchantsLoaded(list));
    } catch (e) {
      emit(MerchantsError(e.toString()));
    }
  }

  void filter(String query) {
    final current = state;
    if (current is! MerchantsLoaded) return;

    final normalized = query.toLowerCase().trim();
    final filtered = current.merchants.where((m) {
      return m.name.toLowerCase().contains(normalized) ||
          m.email.toLowerCase().contains(normalized);
    }).toList();

    emit(MerchantsLoaded(
      current.merchants,
      filtered: filtered,
      query: query,
    ));
  }
}
