import 'package:flutter_test/flutter_test.dart';
import 'package:maatriva/shared/enums/sensor_enums.dart';
import 'package:maatriva/shared/models/sensor_payload.dart';
import 'package:maatriva/shared/models/device_info.dart';
import 'package:maatriva/shared/models/alert_payload.dart';
import 'package:maatriva/shared/models/camera_payload.dart';
import 'package:maatriva/shared/models/environmental_payload.dart';
import 'package:maatriva/shared/models/health_payload.dart';

void main() {
  group('IoT Enums Serialization Tests', () {
    test('SensorType parse and format', () {
      expect(SensorType.fromJson('heart_rate'), SensorType.heartRate);
      expect(SensorType.fromJson('invalid_type'), SensorType.unknown);
      expect(SensorType.heartRate.toJson(), 'heart_rate');
    });

    test('SensorQuality parse and format', () {
      expect(SensorQuality.fromJson('good'), SensorQuality.good);
      expect(SensorQuality.fromJson('poor'), SensorQuality.poor);
      expect(SensorQuality.fromJson('unknown_quality'), SensorQuality.unknown);
      expect(SensorQuality.good.toJson(), 'good');
    });

    test('SensorStatus parse and format', () {
      expect(SensorStatus.fromJson('online'), SensorStatus.online);
      expect(SensorStatus.fromJson('offline'), SensorStatus.offline);
      expect(SensorStatus.fromJson('broken'), SensorStatus.unknown);
      expect(SensorStatus.online.toJson(), 'online');
    });
  });

  group('SensorPayload Serialization Tests', () {
    final mockJson = {
      'deviceId': 'HR-SOCK-02',
      'sensorId': 'PPG-V2-01',
      'type': 'heart_rate',
      'value': 122,
      'unit': 'bpm',
      'timestamp': '2026-07-21T12:10:30.000Z',
      'quality': 'good',
      'battery': 86,
      'signalStrength': -54,
      'status': 'online',
      'firmwareVersion': '1.1.0',
      'cradleId': 'CRDL001',
      'sequenceNumber': 4012,
      'metadata': {'opticalContact': true},
    };

    test('fromJson creates correct object', () {
      final payload = SensorPayload.fromJson(mockJson);
      expect(payload.deviceId, 'HR-SOCK-02');
      expect(payload.sensorId, 'PPG-V2-01');
      expect(payload.type, SensorType.heartRate);
      expect(payload.value, 122);
      expect(payload.unit, 'bpm');
      expect(payload.timestamp, DateTime.parse('2026-07-21T12:10:30.000Z'));
      expect(payload.quality, SensorQuality.good);
      expect(payload.battery, 86);
      expect(payload.signalStrength, -54);
      expect(payload.status, SensorStatus.online);
      expect(payload.firmwareVersion, '1.1.0');
      expect(payload.cradleId, 'CRDL001');
      expect(payload.sequenceNumber, 4012);
      expect(payload.metadata?['opticalContact'], true);
    });

    test('toJson creates correct map', () {
      final payload = SensorPayload.fromJson(mockJson);
      final json = payload.toJson();
      expect(json['deviceId'], 'HR-SOCK-02');
      expect(json['sensorId'], 'PPG-V2-01');
      expect(json['type'], 'heart_rate');
      expect(json['value'], 122);
      expect(json['battery'], 86);
      expect(json['metadata']['opticalContact'], true);
    });

    test('copyWith updates fields correctly', () {
      final payload = SensorPayload.fromJson(mockJson);
      final updated = payload.copyWith(value: 125, battery: 85);
      expect(updated.value, 125);
      expect(updated.battery, 85);
      expect(updated.deviceId, payload.deviceId);
    });
  });

  group('DeviceInfo Serialization Tests', () {
    final mockJson = {
      'deviceId': 'HR-SOCK-02',
      'deviceName': 'Heart Rate Smart Sock',
      'type': 'heart_rate_sensor',
      'firmwareVersion': '1.0.5',
      'protocol': 'BLE',
      'battery': 88,
      'paired': true,
      'lastSeen': '2026-07-21T08:24:17.000Z',
      'status': 'online',
    };

    test('fromJson and toJson cycles correctly', () {
      final device = DeviceInfo.fromJson(mockJson);
      expect(device.deviceId, 'HR-SOCK-02');
      expect(device.deviceName, 'Heart Rate Smart Sock');
      expect(device.paired, true);
      expect(device.status, SensorStatus.online);

      final json = device.toJson();
      expect(json['paired'], true);
      expect(json['battery'], 88);
    });
  });

  group('AlertPayload Serialization Tests', () {
    final mockJson = {
      'alertId': 'ALERT-001',
      'deviceId': 'HR-SOCK-02',
      'cradleId': 'CRDL001',
      'severity': 'danger',
      'type': 'high_heart_rate',
      'message': 'High heart rate detected!',
      'value': 185.0,
      'thresholdLimit': 180.0,
      'timestamp': '2026-07-21T12:10:30.000Z',
      'acknowledged': false,
    };

    test('fromJson and toJson cycles correctly', () {
      final alert = AlertPayload.fromJson(mockJson);
      expect(alert.alertId, 'ALERT-001');
      expect(alert.severity, 'danger');
      expect(alert.value, 185.0);
      expect(alert.thresholdLimit, 180.0);
      expect(alert.acknowledged, false);

      final json = alert.toJson();
      expect(json['severity'], 'danger');
      expect(json['value'], 185.0);
    });
  });

  group('CameraPayload Serialization Tests', () {
    final mockJson = {
      'deviceId': 'CAM-4K-01',
      'cradleId': 'CRDL001',
      'status': 'online',
      'rtspUrl': 'rtsp://192.168.1.124/live/stream0',
      'webrtcUrl': 'webrtc://stream',
      'hdReady': true,
      'isRecording': false,
      'isStreaming': true,
      'nightVisionActive': true,
      'motionDetected': false,
      'cryDetected': false,
      'frameRate': 30,
      'resolution': '4K',
      'bitrate': 1500000,
      'signalStrength': -54,
      'timestamp': '2026-07-21T12:10:30.000Z',
    };

    test('fromJson and toJson cycles correctly', () {
      final camera = CameraPayload.fromJson(mockJson);
      expect(camera.deviceId, 'CAM-4K-01');
      expect(camera.rtspUrl, 'rtsp://192.168.1.124/live/stream0');
      expect(camera.hdReady, true);
      expect(camera.nightVisionActive, true);
      expect(camera.resolution, '4K');
      expect(camera.bitrate, 1500000);

      final json = camera.toJson();
      expect(json['rtspUrl'], 'rtsp://192.168.1.124/live/stream0');
      expect(json['resolution'], '4K');
    });
  });

  group('EnvironmentalPayload Serialization Tests', () {
    final mockJson = {
      'deviceId': 'ESP32-948210',
      'cradleId': 'CRDL001',
      'roomTemperature': 24.2,
      'humidity': 45.5,
      'airQuality': 35,
      'gasLevel': 1.2,
      'heatingPadTemperature': 32.5,
      'quality': 'good',
      'battery': null,
      'signalStrength': -48,
      'status': 'online',
      'timestamp': '2026-07-21T12:10:30.000Z',
      'sequenceNumber': 10582,
    };

    test('fromJson and toJson cycles correctly', () {
      final env = EnvironmentalPayload.fromJson(mockJson);
      expect(env.deviceId, 'ESP32-948210');
      expect(env.roomTemperature, 24.2);
      expect(env.humidity, 45.5);
      expect(env.airQuality, 35);
      expect(env.heatingPadTemperature, 32.5);

      final json = env.toJson();
      expect(json['roomTemperature'], 24.2);
      expect(json['heatingPadTemperature'], 32.5);
    });
  });

  group('HealthPayload Serialization Tests', () {
    final mockJson = {
      'deviceId': 'HR-SOCK-02',
      'cradleId': 'CRDL001',
      'heartRate': 122,
      'breathingRate': 34,
      'bodyTemperature': 36.8,
      'spo2': 98,
      'sleepStage': 'rem',
      'babyPosition': 'supine',
      'quality': 'good',
      'battery': 86,
      'signalStrength': -54,
      'status': 'online',
      'timestamp': '2026-07-21T12:10:30.000Z',
      'sequenceNumber': 4012,
    };

    test('fromJson and toJson cycles correctly', () {
      final health = HealthPayload.fromJson(mockJson);
      expect(health.deviceId, 'HR-SOCK-02');
      expect(health.heartRate, 122);
      expect(health.breathingRate, 34);
      expect(health.bodyTemperature, 36.8);
      expect(health.spo2, 98);
      expect(health.sleepStage, 'rem');
      expect(health.babyPosition, 'supine');

      final json = health.toJson();
      expect(json['heartRate'], 122);
      expect(json['spo2'], 98);
      expect(json['babyPosition'], 'supine');
    });
  });
}
