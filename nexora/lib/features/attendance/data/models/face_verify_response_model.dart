class FaceVerifyResponseModel {
  final bool match;
  final String? userId;
  final double? confidenceScore;
  final double? livenessScore;
  final String? timestamp;
  final String? reason;

  FaceVerifyResponseModel({
    required this.match,
    this.userId,
    this.confidenceScore,
    this.livenessScore,
    this.timestamp,
    this.reason,
  });

  factory FaceVerifyResponseModel.fromJson(Map<String, dynamic> json) {
    return FaceVerifyResponseModel(
      match: json['match'] as bool? ?? false,
      userId: json['user_id']?.toString(),
      confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
      livenessScore: (json['liveness_score'] as num?)?.toDouble(),
      timestamp: json['timestamp'] as String?,
      reason: json['reason'] as String?,
    );
  }
}
