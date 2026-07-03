import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/aula_entity.dart';
import '../repositories/agenda_repository.dart';

class GetAulasUseCase {
  const GetAulasUseCase(this._repository);

  final AgendaRepository _repository;

  Future<Either<Failure, List<AulaEntity>>> call(int weekday) =>
      _repository.getAulasByWeekday(weekday);
}
