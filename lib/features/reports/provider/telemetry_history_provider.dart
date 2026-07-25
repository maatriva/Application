import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/providers.dart';
import '../../../core/storage/cache_service.dart';
import '../../../domain/repositories/telemetry_repository.dart';
import '../../../shared/models/telemetry_record.dart';

/// The supported pre-set time ranges for inspecting historical telemetry.
enum HistoryTimeRange {
  lastHour('Last Hour'),
  last24Hours('Last 24 Hours'),
  last7Days('Last 7 Days'),
  last30Days('Last 30 Days'),
  custom('Custom Range');

  final String label;
  const HistoryTimeRange(this.label);
}

/// The state class representing the telemetry history list and filter queries.
class TelemetryHistoryState {
  final bool isLoading;
  final String? errorMessage;
  final List<TelemetryRecord> history;
  final HistoryTimeRange selectedRange;
  final DateTime? customFrom;
  final DateTime? customTo;

  const TelemetryHistoryState({
    required this.isLoading,
    this.errorMessage,
    required this.history,
    required this.selectedRange,
    this.customFrom,
    this.customTo,
  });

  factory TelemetryHistoryState.initial() {
    return const TelemetryHistoryState(
      isLoading: false,
      history: [],
      selectedRange: HistoryTimeRange.last24Hours,
    );
  }

  TelemetryHistoryState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<TelemetryRecord>? history,
    HistoryTimeRange? selectedRange,
    DateTime? customFrom,
    DateTime? customTo,
  }) {
    return TelemetryHistoryState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      history: history ?? this.history,
      selectedRange: selectedRange ?? this.selectedRange,
      customFrom: customFrom ?? this.customFrom,
      customTo: customTo ?? this.customTo,
    );
  }
}

/// Managing the lifecycle, local caching, and queries of historical sensor logs.
class TelemetryHistoryNotifier extends StateNotifier<TelemetryHistoryState> {
  final TelemetryRepository _telemetryRepo;
  final CacheService _cacheService;

  TelemetryHistoryNotifier({
    required TelemetryRepository telemetryRepo,
    required CacheService cacheService,
  })  : _telemetryRepo = telemetryRepo,
        _cacheService = cacheService,
        super(TelemetryHistoryState.initial());

  /// Triggers query retrieval from repository, utilizing local caching if requested.
  Future<void> fetchHistory(String babyId, {bool useCache = true}) async {
    // 1. Show cached values immediately for fast loading
    if (useCache && state.history.isEmpty) {
      final cachedJson = _cacheService.getCachedTelemetryHistory(babyId);
      if (cachedJson.isNotEmpty) {
        final cachedRecords = cachedJson
            .map((j) => TelemetryRecord.fromJson(j))
            .toList();
        state = state.copyWith(
          history: cachedRecords,
          isLoading: false,
        );
      }
    }

    state = state.copyWith(isLoading: state.history.isEmpty);

    try {
      DateTime? from;
      DateTime? to;
      final now = DateTime.now();

      switch (state.selectedRange) {
        case HistoryTimeRange.lastHour:
          from = now.subtract(const Duration(hours: 1));
          break;
        case HistoryTimeRange.last24Hours:
          from = now.subtract(const Duration(days: 1));
          break;
        case HistoryTimeRange.last7Days:
          from = now.subtract(const Duration(days: 7));
          break;
        case HistoryTimeRange.last30Days:
          from = now.subtract(const Duration(days: 30));
          break;
        case HistoryTimeRange.custom:
          from = state.customFrom;
          to = state.customTo;
          break;
      }

      final historyList = await _telemetryRepo.getTelemetryHistory(
        babyId,
        from: from,
        to: to,
      );

      state = state.copyWith(
        isLoading: false,
        history: historyList,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Change time range filters and trigger updates
  void changeRange(
    String babyId,
    HistoryTimeRange range, {
    DateTime? customFrom,
    DateTime? customTo,
  }) {
    state = state.copyWith(
      selectedRange: range,
      customFrom: customFrom,
      customTo: customTo,
    );
    fetchHistory(babyId, useCache: false);
  }
}

/// Global provider for checking historical vitals logs
final telemetryHistoryProvider =
    StateNotifierProvider<TelemetryHistoryNotifier, TelemetryHistoryState>((ref) {
  final telemetryRepo = ref.watch(telemetryRepositoryProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  return TelemetryHistoryNotifier(
    telemetryRepo: telemetryRepo,
    cacheService: cacheService,
  );
});
