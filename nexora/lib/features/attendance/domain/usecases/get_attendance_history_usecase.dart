import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/attendance_record_entity.dart';
import '../repositories/attendance_repository.dart';

class GetAttendanceHistoryParams extends Equatable {
  final DateTime start;
  final DateTime end;

  const GetAttendanceHistoryParams({required this.start, required this.end});

  @override
  List<Object?> get props => [start, end];
}

class GetAttendanceHistoryUseCase
    implements UseCase<List<AttendanceRecordEntity>, GetAttendanceHistoryParams> {
  final AttendanceRepository repository;

  GetAttendanceHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<AttendanceRecordEntity>>> call(
    GetAttendanceHistoryParams params,
  ) async {
    return await repository.getHistory(params.start, params.end);
  }
}
