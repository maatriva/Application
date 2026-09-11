import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/providers.dart';
import '../../../core/storage/cache_service.dart';

class AiSubscriptionState {
  final bool isSubscribed;
  final String planName;
  final String priceText;
  final DateTime? subscribedAt;

  const AiSubscriptionState({
    required this.isSubscribed,
    this.planName = 'Maatriva AI Annual Pass',
    this.priceText = '₹10,000 / year',
    this.subscribedAt,
  });

  AiSubscriptionState copyWith({
    bool? isSubscribed,
    String? planName,
    String? priceText,
    DateTime? subscribedAt,
  }) {
    return AiSubscriptionState(
      isSubscribed: isSubscribed ?? this.isSubscribed,
      planName: planName ?? this.planName,
      priceText: priceText ?? this.priceText,
      subscribedAt: subscribedAt ?? this.subscribedAt,
    );
  }
}

class AiSubscriptionNotifier extends StateNotifier<AiSubscriptionState> {
  final CacheService _cacheService;
  static const String _aiSubKey = 'maatriva_cache_ai_subscription_v1';

  AiSubscriptionNotifier(this._cacheService)
      : super(const AiSubscriptionState(isSubscribed: false)) {
    _loadFromCache();
  }

  void _loadFromCache() {
    final isSubcribedCached = _cacheService.sharedPreferences.getBool(_aiSubKey) ?? false;
    state = state.copyWith(isSubscribed: isSubcribedCached);
  }

  Future<void> unlockSubscription() async {
    await _cacheService.sharedPreferences.setBool(_aiSubKey, true);
    state = state.copyWith(
      isSubscribed: true,
      subscribedAt: DateTime.now(),
    );
  }

  Future<void> resetSubscription() async {
    await _cacheService.sharedPreferences.setBool(_aiSubKey, false);
    state = state.copyWith(
      isSubscribed: false,
      subscribedAt: null,
    );
  }

  Future<void> toggleSubscription() async {
    if (state.isSubscribed) {
      await resetSubscription();
    } else {
      await unlockSubscription();
    }
  }
}

final aiSubscriptionProvider =
    StateNotifierProvider<AiSubscriptionNotifier, AiSubscriptionState>((ref) {
  final cache = ref.watch(cacheServiceProvider);
  return AiSubscriptionNotifier(cache);
});
