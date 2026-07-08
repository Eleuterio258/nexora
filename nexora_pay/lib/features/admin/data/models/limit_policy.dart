class LimitPolicy {
  const LimitPolicy({
    required this.id,
    required this.merchantId,
    required this.merchantName,
    required this.maxRequestsPerSecond,
    required this.maxRequestsPerDay,
    required this.updatedAt,
  });

  final String id;
  final String merchantId;
  final String merchantName;
  final int maxRequestsPerSecond;
  final int maxRequestsPerDay;
  final DateTime updatedAt;
}
