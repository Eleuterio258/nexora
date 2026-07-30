import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/attendance_record_entity.dart';
import '../repositories/attendance_repository.dart';

class RegisterAttendanceUseCase
    implements UseCase<AttendanceRecordEntity, RegisterAttendanceParams> {
  final AttendanceRepository repository;

  RegisterAttendanceUseCase(this.repository);

  @override
  Future<Either<Failure, AttendanceRecordEntity>> call(
    RegisterAttendanceParams params,
  ) async {
    return await repository.registerAttendance(params);
  }
}
