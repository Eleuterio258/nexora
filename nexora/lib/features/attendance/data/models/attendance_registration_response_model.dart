import '../../domain/entities/attendance_method.dart';
import '../../domain/entities/attendance_record_entity.dart';
import '../../domain/entities/attendance_status.dart';

class AttendanceRegistrationResponseModel {
  final bool success;
  final String? recordId;
  final String? message;
  final String? type;
  final String? method;
  final String? recordedAt;
  final double? geoLat;
  final double? geoLng;

  const AttendanceRegistrationResponseModel({
    required this.success,
    this.recordId,
    this.message,
    this.type,
    this.method,
    this.recordedAt,
    this.geoLat,
    this.geoLng,
  });

  factory AttendanceRegistrationResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AttendanceRegistrationResponseModel(
      success: json['success'] == true || json['sucesso'] == true,
      recordId: json['record_id']?.toString() ?? json['id']?.toString(),
      message: json['message']?.toString() ?? json['mensagem']?.toString(),
      type: json['type']?.toString() ?? json['tipo']?.toString(),
      method: json['method']?.toString() ?? json['metodo']?.toString(),
      recordedAt:
          json['recorded_at']?.toString() ?? json['data_hora']?.toString(),
      geoLat: _toDouble(json['geo_lat'] ?? json['geo_lat']),
      geoLng: _toDouble(json['geo_lng'] ?? json['geo_lng']),
    );
  }

  AttendanceRecordEntity toEntity() {
    return AttendanceRecordEntity(
      id: recordId ?? '',
      type: type != null
          ? AttendanceType.fromString(type!)
          : AttendanceType.entrada,
      method: method != null
          ? AttendanceMethod.fromString(method!)
          : AttendanceMethod.manual,
      recordedAt: recordedAt != null
          ? DateTime.tryParse(recordedAt!) ?? DateTime.now()
          : DateTime.now(),
      geoLat: geoLat,
      geoLng: geoLng,
      status: success ? 'ok' : 'erro',
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
