class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException(this.message, {this.statusCode});
}

class NetworkException implements Exception {
  const NetworkException();
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}

class CacheException implements Exception {
  final String message;
  const CacheException(this.message);
}
