import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/attendance_record_entity.dart';
import '../repositories/attendance_repository.dart';

class GetTodayStatusUseCase
    implements UseCase<List<AttendanceRecordEntity>, NoParams> {
  final AttendanceRepository repository;

  GetTodayStatusUseCase(this.repository);

  @override
  Future<Either<Failure, List<AttendanceRecordEntity>>> call(NoParams params) async {
    return await repository.getTodayStatus();
  }
}
