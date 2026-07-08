part of 'api_keys_cubit.dart';

sealed class ApiKeysState {
  const ApiKeysState();
}

class ApiKeysLoading extends ApiKeysState {
  const ApiKeysLoading();
}

class ApiKeysLoaded extends ApiKeysState {
  const ApiKeysLoaded(this.keys, {this.newlyCreated});

  final List<ApiKey> keys;
  final ApiKey? newlyCreated;
}

class ApiKeysError extends ApiKeysState {
  const ApiKeysError(this.message);

  final String message;
}
