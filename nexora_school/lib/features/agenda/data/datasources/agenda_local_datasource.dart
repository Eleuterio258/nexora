import '../../domain/entities/aula_entity.dart';

abstract interface class AgendaLocalDatasource {
  List<AulaEntity> getAulasByWeekday(int weekday);
}

class AgendaLocalDatasourceImpl implements AgendaLocalDatasource {
  @override
  List<AulaEntity> getAulasByWeekday(int weekday) => const [];
}
