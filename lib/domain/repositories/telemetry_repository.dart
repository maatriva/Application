import '../../shared/models/telemetry_record.dart';

/// Contract definition for retrieving historical TimescaleDB telemetry logs.
abstract class TelemetryRepository {
  Future<List<TelemetryRecord>> getTelemetryHistory(
    String babyId, {
    DateTime? from,
    DateTime? to,
    int? limit,
  });
}
