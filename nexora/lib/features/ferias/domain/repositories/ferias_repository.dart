import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../entities/pedido_ferias_entity.dart';
import '../entities/tipo_ausencia_entity.dart';

class CriarPedidoFeriasParams extends Equatable {
  final int tipoId;
  final DateTime dataInicio;
  final DateTime dataFim;
  final String? motivo;

  const CriarPedidoFeriasParams({
    required this.tipoId,
    required this.dataInicio,
    required this.dataFim,
    this.motivo,
  });

  @override
  List<Object?> get props => [tipoId, dataInicio, dataFim, motivo];
}

abstract class FeriasRepository {
  Future<Either<Failure, List<TipoAusenciaEntity>>> getTiposAusencia();

  Future<Either<Failure, List<PedidoFeriasEntity>>> getMeusPedidos();

  Future<Either<Failure, int>> criarPedido(CriarPedidoFeriasParams params);

  Future<Either<Failure, void>> cancelarPedido(int id);
}
