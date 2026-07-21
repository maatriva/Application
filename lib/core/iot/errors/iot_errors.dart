import 'package:equatable/equatable.dart';

/// Enum representing the category of an IoT error.
enum IotErrorCode {
  deviceNotFound,
  connectionTimeout,
  authenticationFailure,
  subscriptionFailure,
  invalidPacket,
  unsupportedFirmware,
  lostConnection,
  weakSignal,
  lowBattery,
  brokerUnavailable,
  permissionDenied,
  unknown
}

/// Enum representing the urgency of an IoT error.
enum IotErrorSeverity {
  info,
  warning,
  critical
}

/// A structured error model that encapsulates hardware and network telemetry exceptions.
class IotError extends Equatable {
  /// Unique error identifier code.
  final IotErrorCode code;

  /// Severity level of the error.
  final IotErrorSeverity severity;

  /// Caregiver-friendly localized message.
  final String message;

  /// Clear, actionable recovery steps.
  final List<String> recoverySteps;

  /// Underlying raw error or stacktrace (for engineering debugging).
  final String? technicalDetails;

  const IotError({
    required this.code,
    required this.severity,
    required this.message,
    required this.recoverySteps,
    this.technicalDetails,
  });

  @override
  List<Object?> get props => [
        code,
        severity,
        message,
        recoverySteps,
        technicalDetails,
      ];

  /// Factory constructor to create permission denied errors.
  factory IotError.permissionDenied(String permissionName) {
    return IotError(
      code: IotErrorCode.permissionDenied,
      severity: IotErrorSeverity.critical,
      message: 'Required permission "$permissionName" was denied.',
      recoverySteps: const [
        'Open device settings.',
        'Navigate to Maatriva App Permissions.',
        'Enable the requested permission and restart the scan.'
      ],
    );
  }

  /// Factory constructor for device not found error.
  factory IotError.deviceNotFound(String deviceId) {
    return IotError(
      code: IotErrorCode.deviceNotFound,
      severity: IotErrorSeverity.warning,
      message: 'Could not locate device "$deviceId".',
      recoverySteps: const [
        'Check if the device is powered on.',
        'Ensure Bluetooth/Wi-Fi is active on your phone.',
        'Move the device closer to the hub or phone.'
      ],
    );
  }

  /// Factory constructor for lost connection error.
  factory IotError.lostConnection(String deviceId) {
    return IotError(
      code: IotErrorCode.lostConnection,
      severity: IotErrorSeverity.critical,
      message: 'Connection to "$deviceId" was lost.',
      recoverySteps: const [
        'Verify the device did not run out of battery.',
        'Ensure the device is within radio range.',
        'Wait a moment while Maatriva attempts to automatically reconnect.'
      ],
    );
  }
}
