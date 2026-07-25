import '../../core/errors/api_exception.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/cache_service.dart';
import '../../domain/repositories/telemetry_repository.dart';
import '../../shared/models/telemetry_record.dart';

/// Concrete implementation of [TelemetryRepository] utilizing [ApiClient] and caching historical records.
class TelemetryRepositoryImpl implements TelemetryRepository {
  final ApiClient _apiClient;
  final CacheService _cacheService;

  const TelemetryRepositoryImpl({
    required ApiClient apiClient,
    required CacheService cacheService,
  })  : _apiClient = apiClient,
        _cacheService = cacheService;

  @override
  Future<List<TelemetryRecord>> getTelemetryHistory(
    String babyId, {
    DateTime? from,
    DateTime? to,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (from != null) {
        queryParams['from'] = from.toUtc().toIso8601String();
      }
      if (to != null) {
        queryParams['to'] = to.toUtc().toIso8601String();
      }
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }

      final res = await _apiClient.get(
        '/telemetry/history/$babyId',
        queryParameters: queryParams,
      );

      final responseMap = res as Map<String, dynamic>;
      final dataList = responseMap['data'] as List? ?? [];

      final history = dataList
          .map((json) => TelemetryRecord.fromJson(json as Map<String, dynamic>))
          .toList();

      // Cache the fetched history locally for fast future rendering
      final historyJsonList = history.map((e) => e.toJson()).toList();
      await _cacheService.cacheTelemetryHistory(babyId, historyJsonList);

      return history;
    } on ApiException {
      rethrow;
    } catch (_) {
      // Offline fallback: load history from CacheService
      final cachedList = _cacheService.getCachedTelemetryHistory(babyId);
      if (cachedList.isNotEmpty) {
        return cachedList
            .map((json) => TelemetryRecord.fromJson(json))
            .toList();
      }
      throw const ApiException(
        statusCode: 0,
        message: 'No internet connection or server unreachable.',
      );
    }
  }
}
