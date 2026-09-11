import 'api_exception.dart';

/// Centralized error mapper for caregiver access operations.
/// Converts technical exceptions, HTTP status codes, and network failures
/// into clean, friendly user-facing messages.
class CaregiverErrorMapper {
  CaregiverErrorMapper._();

  /// Maps an exception or error object to a clean user-facing string.
  static String map(Object error) {
    if (error is ApiException) {
      switch (error.statusCode) {
        case 409:
          return 'An active caregiver already has access to your baby profile. '
              'Only one active caregiver is permitted at a time. '
              'Please revoke the existing caregiver\'s access before generating a new QR code.';
        case 401:
        case 403:
          return 'Your session has expired or access was revoked. Please log in again.';
        case 400:
        case 422:
          return _cleanMessage(error.message) ??
              'Invalid caregiver access request. Please check selected duration and permissions.';
        case 500:
        case 502:
        case 503:
        case 504:
          return 'Something went wrong on our server. Please try again in a few moments.';
        case 0:
          return 'Unable to connect to Maatriva servers. Please check your internet connection and try again.';
        default:
          final msgLower = error.message.toLowerCase();
          if (msgLower.contains('already has access') ||
              msgLower.contains('active caregiver')) {
            return 'An active caregiver already has access to your baby profile. '
                'Only one active caregiver is permitted at a time. '
                'Please revoke the existing caregiver\'s access before generating a new QR code.';
          }
          return _cleanMessage(error.message) ??
              'Unable to generate QR code right now. Please try again.';
      }
    }

    if (error is AuthFailure) {
      return 'Your session has expired or access was revoked. Please log in again.';
    }

    if (error is NetworkFailure) {
      return 'Unable to connect to Maatriva servers. Please check your internet connection and try again.';
    }

    if (error is ValidationFailure) {
      return _cleanMessage(error.message) ??
          'Invalid caregiver access request. Please check selected duration and permissions.';
    }

    if (error is ServerFailure) {
      return 'Something went wrong on our server. Please try again in a few moments.';
    }

    final errStr = error.toString().toLowerCase();

    if (errStr.contains('409') ||
        errStr.contains('already has access') ||
        errStr.contains('active caregiver')) {
      return 'An active caregiver already has access to your baby profile. '
          'Only one active caregiver is permitted at a time. '
          'Please revoke the existing caregiver\'s access before generating a new QR code.';
    }

    if (errStr.contains('socketexception') ||
        errStr.contains('connection refused') ||
        errStr.contains('no internet') ||
        errStr.contains('network') ||
        errStr.contains('timeout')) {
      return 'Unable to connect to Maatriva servers. Please check your internet connection and try again.';
    }

    if (errStr.contains('401') || errStr.contains('unauthorized')) {
      return 'Your session has expired or access was revoked. Please log in again.';
    }

    return 'Unable to generate QR code right now. Please try again.';
  }

  /// Helper to check if an error string or object represents a single-caregiver 409 conflict.
  static bool isConflictError(Object error) {
    if (error is ApiException && error.statusCode == 409) return true;
    final errStr = error.toString().toLowerCase();
    return errStr.contains('409') ||
        errStr.contains('already has access') ||
        errStr.contains('active caregiver');
  }

  /// Strips technical class names and code patterns from messages.
  static String? _cleanMessage(String raw) {
    if (raw.trim().isEmpty) return null;
    var cleaned = raw
        .replaceAll(RegExp(r'^(ApiException\s*\[\d+\]:\s*|Exception:\s*|Error:\s*)', caseSensitive: false), '')
        .trim();
    if (cleaned.contains('Exception') || cleaned.contains('Stack trace') || cleaned.contains('{')) {
      return null;
    }
    return cleaned;
  }
}
