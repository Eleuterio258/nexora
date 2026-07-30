import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/ferias_repository.dart';

class CancelarPedidoFeriasUseCase implements UseCase<void, int> {
  final FeriasRepository repository;

  CancelarPedidoFeriasUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(int id) {
    return repository.cancelarPedido(id);
  }
}
