import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Requests Camera and Microphone permissions. Returns true if both are granted.
  static Future<bool> requestCameraAndMicrophone() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    return statuses[Permission.camera] == PermissionStatus.granted &&
           statuses[Permission.microphone] == PermissionStatus.granted;
  }

  /// Checks if both Camera and Microphone permissions are currently granted.
  static Future<bool> checkCameraAndMicrophone() async {
    final cameraGranted = await Permission.camera.isGranted;
    final micGranted = await Permission.microphone.isGranted;
    return cameraGranted && micGranted;
  }
}
