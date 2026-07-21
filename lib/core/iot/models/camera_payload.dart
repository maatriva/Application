import 'package:equatable/equatable.dart';
import 'enums.dart';

/// Represents the camera streaming status, feed metadata, and local analytics events.
class CameraPayload extends Equatable {
  /// Unique identifier of the camera hardware (e.g., "CAM-4K-01").
  final String deviceId;

  /// Cradle or room identifier where the camera is mounted.
  final String cradleId;

  /// Connection status of the camera.
  final SensorStatus status;

  /// RTSP streaming source URL for local playback.
  final String rtspUrl;

  /// Optional WebRTC endpoint URL for low-latency remote streaming.
  final String? webrtcUrl;

  /// Indicates if HD high-bitrate streaming is enabled.
  final bool hdReady;

  /// Indicates if the camera is actively recording video to local storage or cloud.
  final bool isRecording;

  /// Indicates if the live video feed is actively streaming.
  final bool isStreaming;

  /// Indicates if night vision (infrared LEDs) is currently active.
  final bool nightVisionActive;

  /// Real-time motion event flag from camera visual detection.
  final bool motionDetected;

  /// Real-time cry flag from camera acoustic stream.
  final bool cryDetected;

  /// Current frames per second (e.g. 30).
  final int frameRate;

  /// Video resolution ("4K", "1080p", "720p").
  final String resolution;

  /// Bitrate of the active video stream in bits per second (e.g., 1500000).
  final int bitrate;

  /// Wi-Fi RSSI signal strength (in dBm).
  final int signalStrength;

  /// Telemetry creation timestamp.
  final DateTime timestamp;

  const CameraPayload({
    required this.deviceId,
    required this.cradleId,
    required this.status,
    required this.rtspUrl,
    this.webrtcUrl,
    this.hdReady = false,
    this.isRecording = false,
    this.isStreaming = false,
    this.nightVisionActive = false,
    this.motionDetected = false,
    this.cryDetected = false,
    this.frameRate = 30,
    required this.resolution,
    required this.bitrate,
    required this.signalStrength,
    required this.timestamp,
  });

  /// Factory constructor to instantiate a camera payload from JSON.
  factory CameraPayload.fromJson(Map<String, dynamic> json) {
    return CameraPayload(
      deviceId: json['deviceId'] as String? ?? '',
      cradleId: json['cradleId'] as String? ?? json['roomId'] as String? ?? '',
      status: SensorStatus.fromJson(json['status'] as String? ?? ''),
      rtspUrl: json['rtspUrl'] as String? ?? '',
      webrtcUrl: json['webrtcUrl'] as String?,
      hdReady: json['hdReady'] as bool? ?? false,
      isRecording: json['isRecording'] as bool? ?? false,
      isStreaming: json['isStreaming'] as bool? ?? false,
      nightVisionActive: json['nightVisionActive'] as bool? ?? false,
      motionDetected: json['motionDetected'] as bool? ?? false,
      cryDetected: json['cryDetected'] as bool? ?? false,
      frameRate: json['frameRate'] as int? ?? 30,
      resolution: json['resolution'] as String? ?? '1080p',
      bitrate: json['bitrate'] as int? ?? 0,
      signalStrength: json['signalStrength'] as int? ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  /// Converts this model instance into a standard JSON dictionary.
  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'cradleId': cradleId,
      'status': status.toJson(),
      'rtspUrl': rtspUrl,
      if (webrtcUrl != null) 'webrtcUrl': webrtcUrl,
      'hdReady': hdReady,
      'isRecording': isRecording,
      'isStreaming': isStreaming,
      'nightVisionActive': nightVisionActive,
      'motionDetected': motionDetected,
      'cryDetected': cryDetected,
      'frameRate': frameRate,
      'resolution': resolution,
      'bitrate': bitrate,
      'signalStrength': signalStrength,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Creates a copy of this camera payload with modified parameters.
  CameraPayload copyWith({
    String? deviceId,
    String? cradleId,
    SensorStatus? status,
    String? rtspUrl,
    String? webrtcUrl,
    bool? hdReady,
    bool? isRecording,
    bool? isStreaming,
    bool? nightVisionActive,
    bool? motionDetected,
    bool? cryDetected,
    int? frameRate,
    String? resolution,
    int? bitrate,
    int? signalStrength,
    DateTime? timestamp,
  }) {
    return CameraPayload(
      deviceId: deviceId ?? this.deviceId,
      cradleId: cradleId ?? this.cradleId,
      status: status ?? this.status,
      rtspUrl: rtspUrl ?? this.rtspUrl,
      webrtcUrl: webrtcUrl ?? this.webrtcUrl,
      hdReady: hdReady ?? this.hdReady,
      isRecording: isRecording ?? this.isRecording,
      isStreaming: isStreaming ?? this.isStreaming,
      nightVisionActive: nightVisionActive ?? this.nightVisionActive,
      motionDetected: motionDetected ?? this.motionDetected,
      cryDetected: cryDetected ?? this.cryDetected,
      frameRate: frameRate ?? this.frameRate,
      resolution: resolution ?? this.resolution,
      bitrate: bitrate ?? this.bitrate,
      signalStrength: signalStrength ?? this.signalStrength,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [
        deviceId,
        cradleId,
        status,
        rtspUrl,
        webrtcUrl,
        hdReady,
        isRecording,
        isStreaming,
        nightVisionActive,
        motionDetected,
        cryDetected,
        frameRate,
        resolution,
        bitrate,
        signalStrength,
        timestamp,
      ];
}
