class ApiCall {
  const ApiCall({
    required this.id,
    required this.merchantId,
    required this.merchantName,
    required this.method,
    required this.endpoint,
    required this.statusCode,
    required this.timestamp,
    this.errorMessage,
  });

  final String id;
  final String merchantId;
  final String merchantName;
  final String method;
  final String endpoint;
  final int statusCode;
  final DateTime timestamp;
  final String? errorMessage;

  bool get isError => statusCode >= 400 || errorMessage != null;
}
