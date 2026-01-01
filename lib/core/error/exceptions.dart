class ServerException implements Exception {
  final String message;
  final int? statusCode; // optional (API use ke liye)
  final dynamic error;   // optional raw error

  const ServerException({
    required this.message,
    this.statusCode,
    this.error,
  });

  @override
  String toString() {
    return 'ServerException(message: $message, statusCode: $statusCode)';
  }
}
class NetworkException extends ServerException {
  NetworkException({required super.message});
}

class UnauthorizedException extends ServerException {
  UnauthorizedException({required super.message});
}
