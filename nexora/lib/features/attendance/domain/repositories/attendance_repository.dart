import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../entities/attendance_record_entity.dart';
import '../entities/attendance_method.dart';
import '../entities/attendance_status.dart';

class RegisterAttendanceParams extends Equatable {
  final AttendanceMethod method;
  final AttendanceType type;
  final double? geoLat;
  final double? geoLng;
  final Map<String, dynamic>? payload;

  const RegisterAttendanceParams({
    required this.method,
    required this.type,
    this.geoLat,
    this.geoLng,
    this.payload,
  });

  @override
  List<Object?> get props => [method, type, geoLat, geoLng, payload];
}

abstract class AttendanceRepository {
  Future<Either<Failure, AttendanceRecordEntity>> registerAttendance(
    RegisterAttendanceParams params,
  );

  Future<Either<Failure, bool>> verifyPin(String pin);

  Future<Either<Failure, List<AttendanceRecordEntity>>> getHistory(
    DateTime start,
    DateTime end,
  );

  Future<Either<Failure, List<AttendanceRecordEntity>>> getTodayStatus();
}
