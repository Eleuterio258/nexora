import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/ferias_repository.dart';

class CriarPedidoFeriasUseCase
    implements UseCase<int, CriarPedidoFeriasParams> {
  final FeriasRepository repository;

  CriarPedidoFeriasUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call(CriarPedidoFeriasParams params) {
    return repository.criarPedido(params);
  }
}
