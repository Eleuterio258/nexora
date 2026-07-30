import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/tipo_ausencia_entity.dart';
import '../repositories/ferias_repository.dart';

class GetTiposAusenciaUseCase
    implements UseCase<List<TipoAusenciaEntity>, NoParams> {
  final FeriasRepository repository;

  GetTiposAusenciaUseCase(this.repository);

  @override
  Future<Either<Failure, List<TipoAusenciaEntity>>> call(NoParams params) {
    return repository.getTiposAusencia();
  }
}
