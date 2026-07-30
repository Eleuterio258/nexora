

import 'rest_client_response.dart';

class RestClientException implements Exception {
  String? message;
  int? statusCode;
  dynamic error;
  RestClientResponse response;
  bool isTimeout;

  RestClientException(
      {this.message,
      this.statusCode,
      required this.error,
      required this.response,
      this.isTimeout = false});

  @override
  String toString() {
    return 'RestClientException: $message\nStatus Code: $statusCode\nError: $error';
  }
}
