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
  final String? estado;

  const AttendanceRegistrationResponseModel({
    required this.success,
    this.recordId,
    this.message,
    this.type,
    this.method,
    this.recordedAt,
    this.geoLat,
    this.geoLng,
    this.estado,
  });

  factory AttendanceRegistrationResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AttendanceRegistrationResponseModel(
      success: json['success'] == true || json['sucesso'] == true,
      recordId: json['record_id']?.toString() ??
          json['id']?.toString(),
      message: json['message']?.toString() ??
          json['mensagem']?.toString() ??
          json['detail']?.toString(),
      type: json['tipo_evento_codigo']?.toString() ??
          json['type']?.toString() ??
          json['tipo']?.toString(),
      method: json['metodo_codigo']?.toString() ??
          json['method']?.toString() ??
          json['metodo']?.toString(),
      recordedAt: json['ocorrido_em']?.toString() ??
          json['recorded_at']?.toString() ??
          json['data_hora']?.toString(),
      geoLat: _toDouble(json['latitude'] ?? json['geo_lat']),
      geoLng: _toDouble(json['longitude'] ?? json['geo_lng']),
      estado: json['estado']?.toString(),
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
      status: estado ?? (success ? 'ok' : 'erro'),
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
