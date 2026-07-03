import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/aula_entity.dart';
import '../../domain/repositories/agenda_repository.dart';
import '../datasources/agenda_remote_datasource.dart';

class AgendaRepositoryImpl implements AgendaRepository {
  const AgendaRepositoryImpl(this._datasource);

  final AgendaRemoteDatasource _datasource;

  @override
  Future<Either<Failure, List<AulaEntity>>> getAulasByWeekday(int weekday) async {
    try {
      final aulas = await _datasource.getHorario();
      return Right(aulas.where((a) => a.weekday == weekday).toList());
    } on UnauthorizedException {
      return Left(InvalidCredentialsFailure());
    } on NetworkException {
      return Left(OfflineFailure());
    } on ServerException {
      return Left(ServerFailure());
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
