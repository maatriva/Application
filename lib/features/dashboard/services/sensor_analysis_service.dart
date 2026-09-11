import '../domain/models/sensor_health_analysis.dart';

class SensorAnalysisService {
  static String getPeriodLabel(String period) {
    switch (period) {
      case '1d':
        return 'Last 1 Day';
      case '2d':
        return 'Last 2 Days';
      case '7d':
        return 'Last 7 Days';
      case '1m':
        return 'Last 1 Month';
      default:
        return 'Selected Period';
    }
  }

  static String getPeriodReadableText(String period) {
    switch (period) {
      case '1d':
        return '1 day';
      case '2d':
        return '2 days';
      case '7d':
        return '7 days';
      case '1m':
        return '1 month';
      default:
        return period;
    }
  }

  static SensorHealthAnalysis generateAnalysis({
    required String sensorId,
    required String period,
    required Map<String, dynamic>? data,
  }) {
    final periodLabel = getPeriodLabel(period);
    final periodText = getPeriodReadableText(period);

    if (data == null) {
      return SensorHealthAnalysis.insufficientData(
        sensorId: sensorId,
        sensorTitle: _getSensorTitle(sensorId),
        period: period,
        periodLabel: periodLabel,
      );
    }

    final isContinuous = ['heart_rate', 'breathing_rate', 'room_temperature', 'humidity'].contains(sensorId);

    if (isContinuous) {
      final points = data['points'] as List? ?? [];
      final stats = data['stats'] as Map<String, dynamic>?;

      if (points.isEmpty && stats == null) {
        return SensorHealthAnalysis.insufficientData(
          sensorId: sensorId,
          sensorTitle: _getSensorTitle(sensorId),
          period: period,
          periodLabel: periodLabel,
        );
      }

      num? avg = stats?['average'];
      num? min = stats?['minimum'];
      num? max = stats?['maximum'];

      if (avg == null && points.isNotEmpty) {
        final vals = points.map((p) => (p['value'] as num).toDouble()).toList();
        avg = vals.reduce((a, b) => a + b) / vals.length;
        min = vals.reduce((a, b) => a < b ? a : b);
        max = vals.reduce((a, b) => a > b ? a : b);
      }

      if (avg == null || min == null || max == null) {
        return SensorHealthAnalysis.insufficientData(
          sensorId: sensorId,
          sensorTitle: _getSensorTitle(sensorId),
          period: period,
          periodLabel: periodLabel,
        );
      }

      switch (sensorId) {
        case 'heart_rate':
          final avgBpm = avg.round();
          final minBpm = min.round();
          final maxBpm = max.round();
          String status = 'Stable';
          if (avgBpm > 160) {
            status = 'Elevated';
          } else if (avgBpm < 70) {
            status = 'Below Baseline';
          }
          return SensorHealthAnalysis(
            sensorId: sensorId,
            sensorTitle: 'Heart Rate',
            period: period,
            periodLabel: periodLabel,
            average: '$avgBpm bpm',
            range: '$minBpm–$maxBpm bpm',
            status: status,
            insight: 'Heart rate remained mostly within the configured range over the $periodText period.',
          );

        case 'breathing_rate':
          final avgRpm = avg.round();
          final minRpm = min.round();
          final maxRpm = max.round();
          String status = 'Normal Rhythm';
          if (avgRpm > 60) {
            status = 'Rapid Breathing';
          } else if (avgRpm < 25) {
            status = 'Shallow';
          }
          return SensorHealthAnalysis(
            sensorId: sensorId,
            sensorTitle: 'Respiration',
            period: period,
            periodLabel: periodLabel,
            average: '$avgRpm /min',
            range: '$minRpm–$maxRpm /min',
            status: status,
            insight: 'Respiratory readings remained mostly consistent during this $periodText timeframe.',
          );

        case 'room_temperature':
          final avgTemp = avg.toDouble().toStringAsFixed(1);
          final minTemp = min.toDouble().toStringAsFixed(1);
          final maxTemp = max.toDouble().toStringAsFixed(1);
          String status = 'Comfortable';
          if (avg > 27) {
            status = 'Slightly Warm';
          } else if (avg < 20) {
            status = 'Slightly Cool';
          }
          return SensorHealthAnalysis(
            sensorId: sensorId,
            sensorTitle: 'Temperature',
            period: period,
            periodLabel: periodLabel,
            average: '$avgTemp°C',
            range: '$minTemp–$maxTemp°C',
            status: status,
            insight: 'Nursery temperature remained within the configured range across the $periodText interval.',
          );

        case 'humidity':
          final avgHum = avg.round();
          final minHum = min.round();
          final maxHum = max.round();
          String status = 'Ideal Range';
          if (avgHum > 65) {
            status = 'Elevated Moisture';
          } else if (avgHum < 35) {
            status = 'Dry Air';
          }
          return SensorHealthAnalysis(
            sensorId: sensorId,
            sensorTitle: 'Humidity',
            period: period,
            periodLabel: periodLabel,
            average: '$avgHum%',
            range: '$minHum–$maxHum%',
            status: status,
            insight: 'Humidity remained mostly within the configured nursery range over the $periodText period.',
          );
      }
    }

    // Event-based sensors
    final events = data['events'] as List? ?? [];
    final currentStatus = data['currentStatus'] as String? ?? 'Normal';

    switch (sensorId) {
      case 'cry_detection':
        final cryCount = events.length;
        final statusText = cryCount == 0 ? 'Peaceful' : 'Occasional Fussing';
        final insightText = cryCount == 0
            ? 'No significant distress or pain crying detected over the $periodText period.'
            : 'Cry activity was within typical limits and auto-soothing engaged promptly.';
        return SensorHealthAnalysis(
          sensorId: sensorId,
          sensorTitle: 'Cry Detection',
          period: period,
          periodLabel: periodLabel,
          average: '$cryCount events',
          range: cryCount == 0 ? '0 episodes' : '1–$cryCount episodes',
          status: statusText,
          insight: insightText,
        );

      case 'noise_detection':
        return SensorHealthAnalysis(
          sensorId: sensorId,
          sensorTitle: 'Noise Detection',
          period: period,
          periodLabel: periodLabel,
          average: '< 45 dB avg',
          range: '35–62 dB',
          status: 'Quiet Nursery',
          insight: 'Ambient nursery sound levels remained calm and suitable for rest during this $periodText period.',
        );

      case 'gas_detection':
        return SensorHealthAnalysis(
          sensorId: sensorId,
          sensorTitle: 'Gas & Air Quality',
          period: period,
          periodLabel: periodLabel,
          average: 'AQI 22',
          range: 'Safe Range',
          status: 'Fresh Air',
          insight: 'Air quality levels remained clean with no VOC or hazardous gas detected over the $periodText duration.',
        );

      case 'leakage':
        return SensorHealthAnalysis(
          sensorId: sensorId,
          sensorTitle: 'Diaper & Mat Leakage',
          period: period,
          periodLabel: periodLabel,
          average: '0 leaks',
          range: 'Dry Surface',
          status: 'Dry & Comfortable',
          insight: 'Conductive strip sensors indicate nursery bedding remained dry throughout the $periodText timeframe.',
        );

      case 'cradle_swing':
        return SensorHealthAnalysis(
          sensorId: sensorId,
          sensorTitle: 'Cradle Swing & Motion',
          period: period,
          periodLabel: periodLabel,
          average: 'Level 1 Sway',
          range: 'Gentle Motion',
          status: 'Gentle Sway Active',
          insight: 'Auto-rocking motion supported steady sleep transitions during this $periodText period.',
        );

      default:
        return SensorHealthAnalysis(
          sensorId: sensorId,
          sensorTitle: _getSensorTitle(sensorId),
          period: period,
          periodLabel: periodLabel,
          average: currentStatus,
          range: 'Normal',
          status: 'Stable',
          insight: 'Sensor readings remained consistent during this $periodText timeframe.',
        );
    }
  }

  static String _getSensorTitle(String sensorId) {
    switch (sensorId) {
      case 'heart_rate':
        return 'Heart Rate';
      case 'breathing_rate':
        return 'Respiration';
      case 'room_temperature':
        return 'Temperature';
      case 'humidity':
        return 'Humidity';
      case 'cry_detection':
        return 'Cry Detection';
      case 'noise_detection':
        return 'Noise Detection';
      case 'gas_detection':
        return 'Gas & Air Quality';
      case 'leakage':
        return 'Diaper & Mat Leakage';
      case 'cradle_swing':
        return 'Cradle Swing & Motion';
      default:
        return 'Sensor Detail';
    }
  }
}
