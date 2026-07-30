import 'package:equatable/equatable.dart';

import '../../domain/entities/pedido_ferias_entity.dart';
import '../../domain/entities/tipo_ausencia_entity.dart';

abstract class FeriasState extends Equatable {
  const FeriasState();

  @override
  List<Object?> get props => [];
}

class FeriasInitial extends FeriasState {}

class FeriasLoading extends FeriasState {}

class TiposAusenciaLoaded extends FeriasState {
  final List<TipoAusenciaEntity> tipos;

  const TiposAusenciaLoaded({required this.tipos});

  @override
  List<Object?> get props => [tipos];
}

class MeusPedidosFeriasLoaded extends FeriasState {
  final List<PedidoFeriasEntity> pedidos;

  const MeusPedidosFeriasLoaded({required this.pedidos});

  @override
  List<Object?> get props => [pedidos];
}

class PedidoFeriasCriado extends FeriasState {
  final int id;

  const PedidoFeriasCriado({required this.id});

  @override
  List<Object?> get props => [id];
}

class PedidoFeriasCancelado extends FeriasState {}

class FeriasFailure extends FeriasState {
  final String message;

  const FeriasFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
