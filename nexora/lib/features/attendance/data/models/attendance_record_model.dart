import '../../domain/entities/attendance_method.dart';
import '../../domain/entities/attendance_record_entity.dart';
import '../../domain/entities/attendance_status.dart';

class AttendanceRecordModel {
  final String id;
  final String type;
  final String method;
  final String recordedAt;
  final double? geoLat;
  final double? geoLng;
  final String? status;
  final String? message;

  const AttendanceRecordModel({
    required this.id,
    required this.type,
    required this.method,
    required this.recordedAt,
    this.geoLat,
    this.geoLng,
    this.status,
    this.message,
  });

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? json['tipo']?.toString() ?? 'entrada',
      method: json['method']?.toString() ??
          json['metodo']?.toString() ??
          'manual',
      recordedAt: json['recorded_at']?.toString() ??
          json['data_hora']?.toString() ??
          DateTime.now().toIso8601String(),
      geoLat: _toDouble(json['geo_lat'] ?? json['latitude']),
      geoLng: _toDouble(json['geo_lng'] ?? json['longitude']),
      status: json['status']?.toString(),
      message: json['message']?.toString() ?? json['mensagem']?.toString(),
    );
  }

  AttendanceRecordEntity toEntity() {
    return AttendanceRecordEntity(
      id: id,
      type: AttendanceType.fromString(type),
      method: AttendanceMethod.fromString(method),
      recordedAt: DateTime.tryParse(recordedAt) ?? DateTime.now(),
      geoLat: geoLat,
      geoLng: geoLng,
      status: status,
      message: message,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
