import '../../../../core/rest_client/rest_client.dart';
import '../../../../core/rest_client/rest_client_exception.dart';
import '../models/attendance_record_model.dart';
import '../models/attendance_registration_response_model.dart';
import '../models/face_verify_response_model.dart';

abstract class AttendanceRemoteDataSource {
  Future<FaceVerifyResponseModel> verifyFacial({
    required String deviceId,
    required String imageBase64,
    double? geoLat,
    double? geoLng,
  });

  Future<AttendanceRegistrationResponseModel> registerAttendance({
    required String deviceId,
    required String method,
    required String type,
    double? geoLat,
    double? geoLng,
    Map<String, dynamic>? payload,
  });

  Future<bool> verifyPin({
    required String deviceId,
    required String pin,
  });

  Future<List<AttendanceRecordModel>> getHistory({
    required DateTime start,
    required DateTime end,
  });

  Future<List<AttendanceRecordModel>> getTodayStatus();
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final RestClient restClient;

  AttendanceRemoteDataSourceImpl({required this.restClient});

  @override
  Future<FaceVerifyResponseModel> verifyFacial({
    required String deviceId,
    required String imageBase64,
    double? geoLat,
    double? geoLng,
  }) async {
    try {
      final response = await restClient.auth().post<Map<String, dynamic>>(
        '/api/self-service/assiduidade/biometria/facial/verificar',
        data: {
          'device_id': deviceId,
          'image_base64': imageBase64,
          'geo_lat': geoLat,
          'geo_lng': geoLng,
        },
      );

      return FaceVerifyResponseModel.fromJson(response.data ?? {});
    } on RestClientException catch (e) {
      if (e.isTimeout) {
        throw Exception(
          'O servidor demorou demasiado tempo a responder. Tenta novamente.',
        );
      }

      final data = e.response.data;
      final message = data is Map ? (data['detail'] ?? data['error']) : null;
      throw Exception(message?.toString() ?? 'Falha na verificação facial.');
    }
  }

  @override
  Future<AttendanceRegistrationResponseModel> registerAttendance({
    required String deviceId,
    required String method,
    required String type,
    double? geoLat,
    double? geoLng,
    Map<String, dynamic>? payload,
  }) async {
    try {
      final response = await restClient.auth().post<Map<String, dynamic>>(
        '/api/self-service/assiduidade/registar',
        data: {
          'device_id': deviceId,
          'method': method,
          'type': type,
          'geo_lat': geoLat,
          'geo_lng': geoLng,
          'payload': ?payload,
        },
      );

      return AttendanceRegistrationResponseModel.fromJson(
        response.data ?? {},
      );
    } on RestClientException catch (e) {
      _handleError(e, 'Falha ao registar presença.');
    }
  }

  @override
  Future<bool> verifyPin({
    required String deviceId,
    required String pin,
  }) async {
    try {
      final response = await restClient.auth().post<Map<String, dynamic>>(
        '/api/self-service/assiduidade/verificar-pin',
        data: {
          'device_id': deviceId,
          'pin': pin,
        },
      );

      final data = response.data ?? {};
      return data['valido'] == true || data['valid'] == true;
    } on RestClientException catch (e) {
      _handleError(e, 'Falha ao verificar PIN.');
    }
  }

  @override
  Future<List<AttendanceRecordModel>> getHistory({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final response = await restClient.auth().get<Map<String, dynamic>>(
        '/api/self-service/assiduidade/historico',
        queryParameters: {
          'inicio': start.toIso8601String(),
          'fim': end.toIso8601String(),
        },
      );

      final data = response.data ?? {};
      final records = data['registos'] ?? data['records'] ?? data['data'] ?? [];
      if (records is List) {
        return records
            .whereType<Map<String, dynamic>>()
            .map(AttendanceRecordModel.fromJson)
            .toList();
      }
      return [];
    } on RestClientException catch (e) {
      _handleError(e, 'Falha ao carregar histórico.');
    }
  }

  @override
  Future<List<AttendanceRecordModel>> getTodayStatus() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return getHistory(start: start, end: end);
  }

  Never _handleError(RestClientException e, String fallback) {
    if (e.isTimeout) {
      throw Exception(
        'O servidor demorou demasiado tempo a responder. Tenta novamente.',
      );
    }

    final data = e.response.data;
    final message = data is Map
        ? (data['detail'] ?? data['error'] ?? data['mensagem'])
        : null;
    throw Exception(message?.toString() ?? fallback);
  }
}
