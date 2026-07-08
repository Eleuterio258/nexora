import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/api_key.dart';
import '../../../data/repositories/admin_repository.dart';

part 'api_keys_state.dart';

class ApiKeysCubit extends Cubit<ApiKeysState> {
  ApiKeysCubit(this._repository) : super(const ApiKeysLoading());

  final AdminRepository _repository;

  Future<void> load() async {
    emit(const ApiKeysLoading());
    try {
      final keys = await _repository.getApiKeys();
      emit(ApiKeysLoaded(keys));
    } catch (e) {
      emit(ApiKeysError(e.toString()));
    }
  }

  Future<void> generateKey({
    required String merchantId,
    required ApiKeyType type,
  }) async {
    final current = state;
    if (current is! ApiKeysLoaded) return;

    try {
      final key = await _repository.generateApiKey(
        merchantId: merchantId,
        type: type,
      );
      emit(ApiKeysLoaded([key, ...current.keys], newlyCreated: key));
    } catch (e) {
      emit(ApiKeysError(e.toString()));
    }
  }

  Future<void> revoke(String id) async {
    final current = state;
    if (current is! ApiKeysLoaded) return;

    try {
      await _repository.revokeApiKey(id);
      final keys = current.keys.map((k) {
        return k.id == id
            ? ApiKey(
                id: k.id,
                merchantId: k.merchantId,
                merchantName: k.merchantName,
                type: k.type,
                status: ApiKeyStatus.revoked,
                prefix: k.prefix,
                createdAt: k.createdAt,
                lastUsedAt: k.lastUsedAt,
              )
            : k;
      }).toList();
      emit(ApiKeysLoaded(keys));
    } catch (e) {
      emit(ApiKeysError(e.toString()));
    }
  }

  void clearNewlyCreated() {
    final current = state;
    if (current is! ApiKeysLoaded) return;
    emit(ApiKeysLoaded(current.keys));
  }
}
