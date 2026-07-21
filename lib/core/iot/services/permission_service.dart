import 'package:permission_handler/permission_handler.dart';

/// Service managing application runtime permissions for iOS and Android.
class PermissionService {
  const PermissionService();

  /// Checks if all necessary permissions required for BLE scanning and hub setup are granted.
  Future<bool> hasAllCorePermissions() async {
    final statusMap = await Future.wait([
      Permission.bluetoothScan.isGranted,
      Permission.bluetoothConnect.isGranted,
      Permission.location.isGranted,
      Permission.camera.isGranted,
      Permission.microphone.isGranted,
      Permission.notification.isGranted,
    ]);
    return statusMap.every((granted) => granted);
  }

  /// Requests all core permissions in sequence. Returns true if all are granted.
  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
      Permission.camera,
      Permission.microphone,
      Permission.notification,
    ].request();

    return statuses;
  }

  /// Requests Bluetooth scanning and connection permissions.
  Future<bool> requestBluetooth() async {
    final scan = await Permission.bluetoothScan.request();
    final connect = await Permission.bluetoothConnect.request();
    return scan.isGranted && connect.isGranted;
  }

  /// Requests location permissions.
  Future<bool> requestLocation() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Requests camera permission.
  Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Requests microphone permission.
  Future<bool> requestMicrophone() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Requests notification permission.
  Future<bool> requestNotifications() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Directs the user to the OS settings screen to manually grant permanently denied permissions.
  Future<bool> openAppSettingsScreen() async {
    return openAppSettings();
  }
}
