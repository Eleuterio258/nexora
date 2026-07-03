class NetworkException implements Exception {
  const NetworkException({this.message});
  final String? message;
  @override
  String toString() => message ?? 'NetworkException';
}

class UnauthorizedException implements Exception {
  const UnauthorizedException({this.message});
  final String? message;
  @override
  String toString() => message ?? 'UnauthorizedException';
}

class InvalidInputException implements Exception {
  const InvalidInputException({this.message});
  final String? message;
  @override
  String toString() => message ?? 'InvalidInputException';
}

class ServerException implements Exception {
  const ServerException({this.message});
  final String? message;
  @override
  String toString() => message ?? 'ServerException';
}

class EmptyCacheException implements Exception {}

class OfflineException implements Exception {}
