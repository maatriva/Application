class SensorHealthAnalysis {
  final String sensorId;
  final String sensorTitle;
  final String period; // '1d', '2d', '7d', '1m'
  final String periodLabel; // 'Last 1 Day', 'Last 2 Days', 'Last 7 Days', 'Last 1 Month'
  final String? average;
  final String? range;
  final String status;
  final String insight;
  final bool hasSufficientData;

  const SensorHealthAnalysis({
    required this.sensorId,
    required this.sensorTitle,
    required this.period,
    required this.periodLabel,
    this.average,
    this.range,
    required this.status,
    required this.insight,
    this.hasSufficientData = true,
  });

  factory SensorHealthAnalysis.insufficientData({
    required String sensorId,
    required String sensorTitle,
    required String period,
    required String periodLabel,
  }) {
    return SensorHealthAnalysis(
      sensorId: sensorId,
      sensorTitle: sensorTitle,
      period: period,
      periodLabel: periodLabel,
      status: 'Insufficient Data',
      insight: "There isn't enough sensor data available for this period to generate a reliable analysis.",
      hasSufficientData: false,
    );
  }
}
