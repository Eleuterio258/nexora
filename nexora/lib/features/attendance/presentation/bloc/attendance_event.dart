import 'package:equatable/equatable.dart';

import '../../domain/entities/attendance_method.dart';
import '../../domain/entities/attendance_status.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

class LoadAttendanceHistory extends AttendanceEvent {
  final DateTime start;
  final DateTime end;

  const LoadAttendanceHistory({required this.start, required this.end});

  @override
  List<Object?> get props => [start, end];
}

class LoadTodayAttendanceStatus extends AttendanceEvent {
  const LoadTodayAttendanceStatus();
}

class RegisterAttendance extends AttendanceEvent {
  final AttendanceMethod method;
  final AttendanceType? type;
  final double? geoLat;
  final double? geoLng;
  final Map<String, dynamic>? payload;

  const RegisterAttendance({
    required this.method,
    this.type,
    this.geoLat,
    this.geoLng,
    this.payload,
  });

  @override
  List<Object?> get props => [method, type, geoLat, geoLng, payload];
}

class VerifyAttendancePin extends AttendanceEvent {
  final String pin;

  const VerifyAttendancePin({required this.pin});

  @override
  List<Object?> get props => [pin];
}

class ResetAttendanceResult extends AttendanceEvent {
  const ResetAttendanceResult();
}
