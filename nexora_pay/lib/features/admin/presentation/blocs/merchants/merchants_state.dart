part of 'merchants_cubit.dart';

sealed class MerchantsState {
  const MerchantsState();
}

class MerchantsLoading extends MerchantsState {
  const MerchantsLoading();
}

class MerchantsLoaded extends MerchantsState {
  const MerchantsLoaded(
    this.merchants, {
    this.filtered,
    this.query = '',
  });

  final List<Merchant> merchants;
  final List<Merchant>? filtered;
  final String query;

  List<Merchant> get visible => filtered ?? merchants;
}

class MerchantsError extends MerchantsState {
  const MerchantsError(this.message);

  final String message;
}
