import '../../core/errors/api_exception.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/cache_service.dart';
import '../../domain/repositories/baby_repository.dart';
import '../../shared/models/baby_profile.dart';

/// Concrete implementation of [BabyRepository] managing infant profiles.
class BabyRepositoryImpl implements BabyRepository {
  final ApiClient _apiClient;
  final CacheService? _cacheService;

  const BabyRepositoryImpl({
    required ApiClient apiClient,
    CacheService? cacheService,
  })  : _apiClient = apiClient,
        _cacheService = cacheService;

  @override
  Future<BabyProfile> createBaby({
    required String name,
    required DateTime birthDate,
    required String gender,
    String? bloodGroup,
    double? birthWeight,
    double? birthHeight,
    String? photoUrl,
  }) async {
    try {
      final res = await _apiClient.post(
        '/babies',
        body: {
          'name': name,
          'dateOfBirth': birthDate.toIso8601String().split('T')[0],
          'gender': gender,
          if (bloodGroup != null && bloodGroup.isNotEmpty) 'bloodGroup': bloodGroup,
          if (birthWeight != null) 'birthWeight': birthWeight,
          if (birthHeight != null) 'birthHeight': birthHeight,
          if (photoUrl != null && photoUrl.isNotEmpty) 'photoUrl': photoUrl,
        },
      );
      final responseMap = res as Map<String, dynamic>;
      final dataMap = responseMap['data'] as Map<String, dynamic>;
      final baby = BabyProfile.fromJson(dataMap);
      if (_cacheService != null) {
        await _cacheService.cacheSelectedBaby(baby.toJson());
        await _cacheService.cacheSelectedBabyId(baby.id);
      }
      return baby;
    } on ApiException {
      rethrow;
    } catch (e) {
      print('BabyRepositoryImpl.createBaby error: $e');
      throw const ApiException(
        statusCode: 0,
        message: 'No internet connection or server unreachable.',
      );
    }
  }

  @override
  Future<List<BabyProfile>> getBabies() async {
    try {
      final res = await _apiClient.get('/babies');
      List rawList = [];
      if (res is List) {
        rawList = res;
      } else if (res is Map) {
        final responseMap = Map<String, dynamic>.from(res);
        if (responseMap['data'] is List) {
          rawList = responseMap['data'] as List;
        }
      }
      final babies = rawList
          .whereType<Map>()
          .map((json) => BabyProfile.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      if (babies.isNotEmpty && _cacheService != null) {
        await _cacheService.cacheSelectedBaby(babies.first.toJson());
        await _cacheService.cacheSelectedBabyId(babies.first.id);
      }
      return babies;
    } catch (e) {
      print('BabyRepositoryImpl.getBabies error: $e');
      if (_cacheService != null) {
        final cachedMap = _cacheService.getCachedSelectedBaby();
        if (cachedMap != null) {
          return [BabyProfile.fromJson(cachedMap)];
        }
      }
      rethrow;
    }
  }

  @override
  Future<BabyProfile> getBabyById(String id) async {
    try {
      final res = await _apiClient.get('/babies/$id');
      final responseMap = res as Map<String, dynamic>;
      final dataMap = responseMap['data'] as Map<String, dynamic>;
      return BabyProfile.fromJson(dataMap);
    } on ApiException {
      rethrow;
    } catch (e) {
      print('BabyRepositoryImpl.getBabyById error: $e');
      throw const ApiException(
        statusCode: 0,
        message: 'No internet connection or server unreachable.',
      );
    }
  }

  @override
  Future<BabyProfile> updateBaby(
    String id, {
    String? name,
    DateTime? birthDate,
    String? gender,
    String? bloodGroup,
    double? birthWeight,
    double? birthHeight,
    String? photoUrl,
  }) async {
    try {
      final res = await _apiClient.put(
        '/babies/$id',
        body: {
          if (name != null) 'name': name,
          if (birthDate != null) 'dateOfBirth': birthDate.toIso8601String().split('T')[0],
          if (gender != null) 'gender': gender,
          if (bloodGroup != null) 'bloodGroup': bloodGroup,
          if (birthWeight != null) 'birthWeight': birthWeight,
          if (birthHeight != null) 'birthHeight': birthHeight,
          if (photoUrl != null) 'photoUrl': photoUrl,
        },
      );
      final responseMap = res as Map<String, dynamic>;
      final dataMap = responseMap['data'] as Map<String, dynamic>;
      return BabyProfile.fromJson(dataMap);
    } on ApiException {
      rethrow;
    } catch (e) {
      print('BabyRepositoryImpl.updateBaby error: $e');
      throw const ApiException(
        statusCode: 0,
        message: 'No internet connection or server unreachable.',
      );
    }
  }
}
