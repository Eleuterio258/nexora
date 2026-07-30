import 'package:equatable/equatable.dart';

import 'pedido_ferias_status.dart';

class PedidoFeriasEntity extends Equatable {
  final int id;
  final String? tipoNome;
  final DateTime dataInicio;
  final DateTime dataFim;
  final int? dias;
  final String? motivo;
  final PedidoFeriasStatus estado;
  final DateTime criadoEm;

  const PedidoFeriasEntity({
    required this.id,
    this.tipoNome,
    required this.dataInicio,
    required this.dataFim,
    this.dias,
    this.motivo,
    required this.estado,
    required this.criadoEm,
  });

  @override
  List<Object?> get props =>
      [id, tipoNome, dataInicio, dataFim, dias, motivo, estado, criadoEm];
}
