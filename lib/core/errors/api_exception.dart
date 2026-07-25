abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'No internet connection.']) : super(message);
}

class ServerFailure extends Failure {
  const ServerFailure([String message = 'An internal server error occurred.']) : super(message);
}

class AuthFailure extends Failure {
  const AuthFailure([String message = 'Session expired. Please log in again.']) : super(message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Failed to access local storage.']) : super(message);
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});

  Failure toFailure() {
    if (statusCode == 401) {
      return AuthFailure(message);
    } else if (statusCode == 400 || statusCode == 422) {
      return ValidationFailure(message);
    } else if (statusCode >= 500) {
      return ServerFailure(message);
    }
    return ServerFailure(message);
  }

  @override
  String toString() => 'ApiException [$statusCode]: $message';
}
