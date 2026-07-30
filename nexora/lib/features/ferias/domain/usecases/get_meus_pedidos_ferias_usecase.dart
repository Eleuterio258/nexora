import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/pedido_ferias_entity.dart';
import '../repositories/ferias_repository.dart';

class GetMeusPedidosFeriasUseCase
    implements UseCase<List<PedidoFeriasEntity>, NoParams> {
  final FeriasRepository repository;

  GetMeusPedidosFeriasUseCase(this.repository);

  @override
  Future<Either<Failure, List<PedidoFeriasEntity>>> call(NoParams params) {
    return repository.getMeusPedidos();
  }
}
