import 'package:equatable/equatable.dart';

import 'attendance_method.dart';
import 'attendance_status.dart';

class AttendanceRecordEntity extends Equatable {
  final String id;
  final AttendanceType type;
  final AttendanceMethod method;
  final DateTime recordedAt;
  final double? geoLat;
  final double? geoLng;
  final String? status;
  final String? message;

  const AttendanceRecordEntity({
    required this.id,
    required this.type,
    required this.method,
    required this.recordedAt,
    this.geoLat,
    this.geoLng,
    this.status,
    this.message,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        method,
        recordedAt,
        geoLat,
        geoLng,
        status,
        message,
      ];
}
