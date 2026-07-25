import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/providers.dart';
import '../../../../core/storage/cache_service.dart';
import '../../../../domain/repositories/alert_repository.dart';
import '../../../../shared/models/alarm_alert.dart';

class AlertsState {
  final List<AlarmAlert> alerts;
  final bool isLoading;
  final String? errorMessage;

  AlertsState({
    required this.alerts,
    required this.isLoading,
    this.errorMessage,
  });

  int get unreadCount => alerts.where((a) => !a.acknowledged).length;

  AlertsState copyWith({
    List<AlarmAlert>? alerts,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AlertsState(
      alerts: alerts ?? this.alerts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AlertsNotifier extends StateNotifier<AlertsState> {
  final AlertRepository _alertRepo;
  final CacheService _cacheService;
  final Ref _ref;
  StreamSubscription? _socketSubscription;

  // Stream for triggering in-app banners in the UI
  final _bannerController = StreamController<AlarmAlert>.broadcast();
  Stream<AlarmAlert> get bannerStream => _bannerController.stream;

  AlertsNotifier(this._alertRepo, this._cacheService, this._ref)
      : super(AlertsState(alerts: [], isLoading: true)) {
    _loadFromCache();
    fetchAlerts();
    _subscribeToSocketAlerts();
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _bannerController.close();
    super.dispose();
  }

  void _loadFromCache() {
    try {
      final cachedJson = _cacheService.getCachedAlerts();
      if (cachedJson.isNotEmpty) {
        final cachedAlerts = cachedJson
            .map((json) => AlarmAlert.fromJson(json))
            .toList();
        state = state.copyWith(alerts: cachedAlerts, isLoading: false);
      }
    } catch (_) {}
  }

  Future<void> fetchAlerts() async {
    try {
      final freshAlerts = await _alertRepo.getAlerts();
      state = state.copyWith(alerts: freshAlerts, isLoading: false, errorMessage: null);
      _persistToCache(freshAlerts);
    } catch (e) {
      if (state.alerts.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceAll('ApiException: ', ''),
        );
      }
    }
  }

  void _subscribeToSocketAlerts() {
    final wsService = _ref.read(webSocketServiceProvider);
    _socketSubscription = wsService.alertStream.listen((event) {
      final alertData = event['alert'];
      if (alertData != null) {
        try {
          final newAlert = AlarmAlert.fromJson(alertData as Map<String, dynamic>);
          
          // Avoid duplicate alerts by checking ID
          if (state.alerts.any((a) => a.id == newAlert.id)) return;

          // Insert new alert at the top of the list efficiently
          final updatedAlerts = [newAlert, ...state.alerts];
          state = state.copyWith(alerts: updatedAlerts);
          _persistToCache(updatedAlerts);

          // Emit banner to trigger in-app notification UI
          _bannerController.add(newAlert);
        } catch (_) {}
      }
    });
  }

  Future<void> markAlertAsRead(String alertId) async {
    // Optimistic UI update
    final updatedAlerts = state.alerts.map((a) {
      if (a.id == alertId) {
        return a.copyWith(acknowledged: true);
      }
      return a;
    }).toList();

    state = state.copyWith(alerts: updatedAlerts);
    _persistToCache(updatedAlerts);

    try {
      await _alertRepo.markAsRead(alertId);
    } catch (_) {
      // Revert or fetch fresh list if backend fails
      fetchAlerts();
    }
  }

  Future<void> markAllAsRead() async {
    // Optimistic UI update
    final updatedAlerts = state.alerts.map((a) {
      return a.copyWith(acknowledged: true);
    }).toList();

    state = state.copyWith(alerts: updatedAlerts);
    _persistToCache(updatedAlerts);

    try {
      await _alertRepo.markAsRead('all');
    } catch (_) {
      fetchAlerts();
    }
  }

  Future<void> deleteAlert(String alertId) async {
    // Optimistic UI update
    final updatedAlerts = state.alerts.where((a) => a.id != alertId).toList();
    state = state.copyWith(alerts: updatedAlerts);
    _persistToCache(updatedAlerts);

    try {
      await _alertRepo.deleteAlert(alertId);
    } catch (_) {
      fetchAlerts();
    }
  }

  Future<void> clearAllAlerts() async {
    // Optimistic UI update
    state = state.copyWith(alerts: []);
    _persistToCache([]);

    try {
      await _alertRepo.clearAllAlerts();
    } catch (_) {
      fetchAlerts();
    }
  }

  void _persistToCache(List<AlarmAlert> list) {
    final jsonList = list.map((a) => a.toJson()).toList();
    _cacheService.cacheAlerts(jsonList);
  }
}

final alertsProvider = StateNotifierProvider<AlertsNotifier, AlertsState>((ref) {
  final alertRepo = ref.watch(alertRepositoryProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  return AlertsNotifier(alertRepo, cacheService, ref);
});
