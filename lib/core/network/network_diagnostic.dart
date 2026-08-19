import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

enum DiagnosticResultType {
  success,
  invalidUrl,
  noInternet,
  dnsFailure,
  connectionRefused,
  corsError,
  timeout,
  serverError,
  unknown,
}

class NetworkDiagnosticResult {
  final DiagnosticResultType type;
  final String title;
  final String message;
  final int? statusCode;
  final String targetUrl;

  const NetworkDiagnosticResult({
    required this.type,
    required this.title,
    required this.message,
    required this.targetUrl,
    this.statusCode,
  });

  bool get isSuccess => type == DiagnosticResultType.success;

  @override
  String toString() => '[$title]: $message (URL: $targetUrl)';
}

class NetworkDiagnostic {
  /// Diagnoses a DioException and returns a detailed NetworkDiagnosticResult
  static NetworkDiagnosticResult diagnoseDioError(DioException err) {
    final baseUrl = (err.requestOptions.baseUrl.isNotEmpty)
        ? err.requestOptions.baseUrl
        : ApiConfig.baseUrl;
    final fullUrl = err.requestOptions.uri.toString();

    // 1. Response received from server
    if (err.response != null) {
      final status = err.response!.statusCode ?? 500;
      if (status >= 500) {
        return NetworkDiagnosticResult(
          type: DiagnosticResultType.serverError,
          title: 'Server Error ($status)',
          message: 'The server encountered an error while processing your request.',
          statusCode: status,
          targetUrl: fullUrl,
        );
      }
      
      String msg = 'Request failed with status $status.';
      if (err.response!.data is Map) {
        final map = err.response!.data as Map;
        if (map.containsKey('error')) {
          msg = map['error'].toString();
        } else if (map.containsKey('message')) {
          msg = map['message'].toString();
        }
      }

      return NetworkDiagnosticResult(
        type: DiagnosticResultType.unknown,
        title: 'API Error',
        message: msg,
        statusCode: status,
        targetUrl: fullUrl,
      );
    }

    // 2. Network exceptions with no response body
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkDiagnosticResult(
          type: DiagnosticResultType.timeout,
          title: 'Connection Timed Out',
          message: 'Unable to reach server at $baseUrl within timeout. Check if the server is running.',
          targetUrl: fullUrl,
        );

      case DioExceptionType.connectionError:
        if (kIsWeb) {
          return NetworkDiagnosticResult(
            type: DiagnosticResultType.corsError,
            title: 'Connection / CORS Error',
            message: 'Failed to connect to backend at $baseUrl. Ensure backend is running and CORS allows origins.',
            targetUrl: fullUrl,
          );
        }

        final errString = err.error?.toString().toLowerCase() ?? '';
        if (errString.contains('no route to host') || errString.contains('unreachable') || errString.contains('ehostunreach')) {
          return NetworkDiagnosticResult(
            type: DiagnosticResultType.connectionRefused,
            title: 'No Route to Host',
            message: 'Cannot reach $baseUrl. 1) Verify phone/device and PC are on the SAME Wi-Fi (disable mobile 4G/5G data). 2) Run "ipconfig" on PC to check if your IP changed. 3) Ensure Windows Firewall allows Node.js on Port 3000.',
            targetUrl: fullUrl,
          );
        } else if (errString.contains('refused') ||
            errString.contains('socketexception') ||
            errString.contains('os error') ||
            errString.contains('errno')) {
          return NetworkDiagnosticResult(
            type: DiagnosticResultType.connectionRefused,
            title: 'Connection Error (OS Error)',
            message: 'Unable to reach backend at $baseUrl. If testing on a phone or camera, tap the Server IP button on the Login screen and enter your PC\'s Wi-Fi IP (e.g. http://192.168.x.x:3000). On Android Emulator, use http://10.0.2.2:3000/api.',
            targetUrl: fullUrl,
          );
        } else if (errString.contains('dns') || errString.contains('lookup')) {
          return NetworkDiagnosticResult(
            type: DiagnosticResultType.dnsFailure,
            title: 'DNS Lookup Failed',
            message: 'Could not resolve host address for $baseUrl. Verify domain or IP address.',
            targetUrl: fullUrl,
          );
        }

        return NetworkDiagnosticResult(
          type: DiagnosticResultType.connectionRefused,
          title: 'Connection Failed',
          message: 'Unable to connect to $baseUrl (OS Error). Verify backend is running and server IP is configured correctly.',
          targetUrl: fullUrl,
        );

      case DioExceptionType.cancel:
        return NetworkDiagnosticResult(
          type: DiagnosticResultType.unknown,
          title: 'Request Cancelled',
          message: 'The network request was cancelled.',
          targetUrl: fullUrl,
        );

      default:
        return NetworkDiagnosticResult(
          type: DiagnosticResultType.unknown,
          title: 'Network Error',
          message: err.message ?? 'An unexpected network error occurred.',
          targetUrl: fullUrl,
        );
    }
  }

  /// Active diagnostic check pinging the backend health endpoint
  static Future<NetworkDiagnosticResult> runHealthCheck({String? overrideUrl}) async {
    final targetUrl = overrideUrl ?? ApiConfig.baseUrl;
    
    final uri = Uri.tryParse(targetUrl);
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      return NetworkDiagnosticResult(
        type: DiagnosticResultType.invalidUrl,
        title: 'Invalid URL',
        message: 'The URL "$targetUrl" is not a valid HTTP/HTTPS endpoint.',
        targetUrl: targetUrl,
      );
    }

    final testDio = Dio(BaseOptions(
      baseUrl: targetUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));

    try {
      final response = await testDio.get('/health');
      if (response.statusCode == 200) {
        return NetworkDiagnosticResult(
          type: DiagnosticResultType.success,
          title: 'Backend Reachable',
          message: 'Successfully connected to backend health endpoint at $targetUrl.',
          statusCode: 200,
          targetUrl: '$targetUrl/health',
        );
      } else {
        return NetworkDiagnosticResult(
          type: DiagnosticResultType.serverError,
          title: 'Health Check Failed',
          message: 'Server returned HTTP ${response.statusCode} on health endpoint.',
          statusCode: response.statusCode,
          targetUrl: '$targetUrl/health',
        );
      }
    } on DioException catch (e) {
      return diagnoseDioError(e);
    } catch (e) {
      return NetworkDiagnosticResult(
        type: DiagnosticResultType.unknown,
        title: 'Diagnostic Error',
        message: 'Unexpected failure testing $targetUrl: $e',
        targetUrl: targetUrl,
      );
    }
  }
}
