import 'package:equatable/equatable.dart';

abstract class FeriasEvent extends Equatable {
  const FeriasEvent();

  @override
  List<Object?> get props => [];
}

class LoadTiposAusencia extends FeriasEvent {
  const LoadTiposAusencia();
}

class LoadMeusPedidosFerias extends FeriasEvent {
  const LoadMeusPedidosFerias();
}

class CriarPedidoFerias extends FeriasEvent {
  final int tipoId;
  final DateTime dataInicio;
  final DateTime dataFim;
  final String? motivo;

  const CriarPedidoFerias({
    required this.tipoId,
    required this.dataInicio,
    required this.dataFim,
    this.motivo,
  });

  @override
  List<Object?> get props => [tipoId, dataInicio, dataFim, motivo];
}

class CancelarPedidoFerias extends FeriasEvent {
  final int id;

  const CancelarPedidoFerias({required this.id});

  @override
  List<Object?> get props => [id];
}
