import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/aula_entity.dart';

abstract interface class AgendaRepository {
  Future<Either<Failure, List<AulaEntity>>> getAulasByWeekday(int weekday);
}
