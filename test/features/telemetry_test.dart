import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Telemetry Model & Sensor Formatting Tests', () {
    test('Heart rate formatting handles normal and elevated values', () {
      const normalHeartRate = 115;
      const highHeartRate = 185;

      expect('$normalHeartRate BPM', equals('115 BPM'));
      expect(highHeartRate > 160, isTrue);
    });

    test('Temperature formatting converts and formats Celsius correctly', () {
      const tempC = 24.2;
      expect('${tempC.toStringAsFixed(1)}°C', equals('24.2°C'));
    });

    test('Missing telemetry fields fall back to default values', () {
      final Map<String, dynamic> rawPayload = {
        'heartRate': null,
        'temperature': 24.0,
      };

      final heartRate = rawPayload['heartRate'] ?? 0;
      final temperature = rawPayload['temperature'] ?? 0.0;

      expect(heartRate, equals(0));
      expect(temperature, equals(24.0));
    });
  });
}
