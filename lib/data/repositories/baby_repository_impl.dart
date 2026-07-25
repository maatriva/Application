import '../../core/errors/api_exception.dart';
import '../../core/network/api_client.dart';
import '../../domain/repositories/baby_repository.dart';
import '../../shared/models/baby_profile.dart';

/// Concrete implementation of [BabyRepository] managing infant profiles.
class BabyRepositoryImpl implements BabyRepository {
  final ApiClient _apiClient;

  const BabyRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

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
      return BabyProfile.fromJson(dataMap);
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
      final responseMap = res as Map<String, dynamic>;
      final dataList = responseMap['data'] as List? ?? [];
      return dataList
          .map((json) => BabyProfile.fromJson(json as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      print('BabyRepositoryImpl.getBabies error: $e');
      throw const ApiException(
        statusCode: 0,
        message: 'No internet connection or server unreachable.',
      );
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
