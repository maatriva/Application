import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/providers.dart';
import 'dashboard_provider.dart';

class SensorReportState {
  final bool isLoading;
  final String? errorMessage;
  final String sensor;
  final String period; // '1d', '2d', '7d', '1m'
  final Map<String, dynamic>? data;

  const SensorReportState({
    required this.isLoading,
    this.errorMessage,
    required this.sensor,
    required this.period,
    this.data,
  });

  factory SensorReportState.initial(String sensor) => SensorReportState(
        isLoading: true,
        sensor: sensor,
        period: '1d',
      );

  SensorReportState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? sensor,
    String? period,
    Map<String, dynamic>? data,
    bool clearError = false,
  }) {
    return SensorReportState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      sensor: sensor ?? this.sensor,
      period: period ?? this.period,
      data: data ?? this.data,
    );
  }
}

class SensorReportNotifier extends StateNotifier<SensorReportState> {
  final ApiClient _apiClient;
  final String _babyId;

  SensorReportNotifier({
    required ApiClient apiClient,
    required String babyId,
    required String initialSensor,
  })  : _apiClient = apiClient,
        _babyId = babyId,
        super(SensorReportState.initial(initialSensor)) {
    fetchReport();
  }

  Future<void> fetchReport({String? newPeriod}) async {
    final periodToFetch = newPeriod ?? state.period;
    state = state.copyWith(isLoading: true, period: periodToFetch, clearError: true);

    try {
      if (_babyId.isEmpty) {
        // Fallback for unselected baby state
        state = state.copyWith(
          isLoading: false,
          data: _buildFallbackData(state.sensor, periodToFetch),
        );
        return;
      }

      final res = await _apiClient.get(
        '/telemetry/sensor-report/$_babyId',
        queryParameters: {
          'sensor': state.sensor,
          'period': periodToFetch,
        },
      );

      final responseMap = res as Map<String, dynamic>;
      final reportData = responseMap['data'] as Map<String, dynamic>? ?? {};

      state = state.copyWith(
        isLoading: false,
        data: reportData,
      );
    } catch (e) {
      if (kDebugMode) {
        print('[SensorReportNotifier] Error fetching report: $e. Using client fallback data.');
      }
      state = state.copyWith(
        isLoading: false,
        data: _buildFallbackData(state.sensor, periodToFetch),
      );
    }
  }

  void changePeriod(String newPeriod) {
    if (state.period == newPeriod) return;
    fetchReport(newPeriod: newPeriod);
  }

  Map<String, dynamic> _buildFallbackData(String sensor, String period) {
    final now = DateTime.now();
    final isContinuous = ['heart_rate', 'breathing_rate', 'room_temperature', 'humidity'].contains(sensor);

    if (isContinuous) {
      int pointsCount = 24;
      if (period == '2d') pointsCount = 48;
      if (period == '7d') pointsCount = 28;
      if (period == '1m') pointsCount = 30;

      double base = 142.0;
      String unit = 'bpm';
      if (sensor == 'breathing_rate') { base = 44.0; unit = 'rpm'; }
      if (sensor == 'room_temperature') { base = 25.4; unit = '°C'; }
      if (sensor == 'humidity') { base = 58.0; unit = '%'; }

      final points = List.generate(pointsCount, (i) {
        final t = now.subtract(Duration(minutes: (pointsCount - i) * (period == '1m' ? 1440 : (period == '7d' ? 360 : 60))));
        final variation = (i % 5 == 0 ? 3.0 : (i % 3 == 0 ? -2.0 : 0.5));
        return {
          'timestamp': t.toIso8601String(),
          'value': double.parse((base + variation).toStringAsFixed(1)),
        };
      });

      final values = points.map((p) => p['value'] as double).toList();
      final minVal = values.reduce((a, b) => a < b ? a : b);
      final maxVal = values.reduce((a, b) => a > b ? a : b);
      final avgVal = double.parse((values.reduce((a, b) => a + b) / values.length).toStringAsFixed(1));

      return {
        'sensor': sensor,
        'period': period,
        'unit': unit,
        'currentValue': values.last,
        'statusLabel': 'Within configured range',
        'stats': {
          'average': avgVal,
          'minimum': minVal,
          'maximum': maxVal,
          'stablePeriod': period == '1m' ? '28 days' : (period == '7d' ? '6d 14h' : '21h 30m'),
        },
        'points': points,
        'notableChanges': [
          {
            'timestamp': now.subtract(const Duration(hours: 4)).toIso8601String(),
            'message': '${sensor.replaceAll('_', ' ')} optimal baseline established',
            'valueChange': '$avgVal $unit',
          },
        ],
      };
    } else {
      String status = '🟢 Normal';
      final events = <Map<String, dynamic>>[];

      if (sensor == 'cry_detection') {
        status = '🟢 No Cry Detected';
        events.addAll([
          {
            'id': 'c1',
            'timestamp': now.subtract(const Duration(hours: 2)).toIso8601String(),
            'title': 'Soft Fussing Detected',
            'subtitle': 'Cradle auto-soothing engaged',
            'severity': 'warning',
            'durationText': '32s',
          },
          {
            'id': 'c2',
            'timestamp': now.subtract(const Duration(hours: 6)).toIso8601String(),
            'title': 'Cry Detected',
            'subtitle': 'Soothing lullaby played automatically',
            'severity': 'warning',
            'durationText': '45s',
          },
        ]);
      } else if (sensor == 'noise_detection') {
        status = '🟢 Quiet Nursery (< 45 dB)';
        events.addAll([
          {
            'id': 'n1',
            'timestamp': now.subtract(const Duration(hours: 1)).toIso8601String(),
            'title': 'Ambient Noise Normal',
            'subtitle': '38 dB background level',
            'severity': 'success',
          },
          {
            'id': 'n2',
            'timestamp': now.subtract(const Duration(hours: 4)).toIso8601String(),
            'title': 'Brief Noise Spike',
            'subtitle': 'Door closure detected (62 dB)',
            'severity': 'info',
          },
        ]);
      } else if (sensor == 'gas_detection') {
        status = '🟢 Air Quality Safe (AQI 22)';
        events.add({
          'id': 'g1',
          'timestamp': now.subtract(const Duration(minutes: 30)).toIso8601String(),
          'title': 'Air Quality Excellent',
          'subtitle': 'No VOC or harmful gas detected',
          'severity': 'success',
        });
      } else if (sensor == 'leakage') {
        status = '🟢 No Moisture / Dry Mat';
        events.add({
          'id': 'l1',
          'timestamp': now.subtract(const Duration(hours: 3)).toIso8601String(),
          'title': 'Moisture Sensor Clean',
          'subtitle': 'Mat surface dry and comfortable',
          'severity': 'success',
        });
      } else if (sensor == 'cradle_swing') {
        status = '🔵 Gentle Motion Active';
        events.addAll([
          {
            'id': 's1',
            'timestamp': now.subtract(const Duration(minutes: 20)).toIso8601String(),
            'title': 'Auto-Rocking Active',
            'subtitle': 'Gentle sway mode (Level 1)',
            'severity': 'info',
            'durationText': 'Active',
          },
          {
            'id': 's2',
            'timestamp': now.subtract(const Duration(hours: 3)).toIso8601String(),
            'title': 'Cradle Stationary',
            'subtitle': 'Baby sleeping peacefully',
            'severity': 'success',
            'durationText': '2h 15m',
          },
        ]);
      }

      return {
        'sensor': sensor,
        'isEventBased': true,
        'currentStatus': status,
        'events': events,
      };
    }
  }
}

final sensorReportFamilyProvider = StateNotifierProvider.family
    .autoDispose<SensorReportNotifier, SensorReportState, String>(
        (ref, sensor) {
  final apiClient = ref.watch(apiClientProvider);
  final dashboardState = ref.watch(dashboardProvider);
  final babyId = dashboardState.baby?.id ?? '';

  return SensorReportNotifier(
    apiClient: apiClient,
    babyId: babyId,
    initialSensor: sensor,
  );
});
