part of 'providers_cubit.dart';

sealed class ProvidersState {
  const ProvidersState();
}

class ProvidersLoading extends ProvidersState {
  const ProvidersLoading();
}

class ProvidersLoaded extends ProvidersState {
  const ProvidersLoaded(this.providers);

  final List<PaymentProvider> providers;
}

class ProvidersError extends ProvidersState {
  const ProvidersError(this.message);

  final String message;
}
