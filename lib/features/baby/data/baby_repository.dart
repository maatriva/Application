import '../../../shared/models/baby_profile.dart';
import '../../../core/services/api_client.dart';

class BabyRepository {
  final ApiClient _apiClient;

  const BabyRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Register baby profile.
  Future<BabyProfile> createBaby({
    required String name,
    required DateTime birthDate,
    required String gender,
  }) async {
    final res = await _apiClient.post(
      '/babies',
      body: {
        'name': name,
        'birthDate': birthDate.toIso8601String(),
        'gender': gender,
      },
    );
    return BabyProfile.fromJson(res as Map<String, dynamic>);
  }

  /// Lists all accessible babies for current session user.
  Future<List<BabyProfile>> getBabies() async {
    final res = await _apiClient.get('/babies') as List;
    return res
        .map((json) => BabyProfile.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Retrieves details of a specific baby profile.
  Future<BabyProfile> getBabyById(String id) async {
    final res = await _apiClient.get('/babies/$id');
    return BabyProfile.fromJson(res as Map<String, dynamic>);
  }

  /// Edits baby details.
  Future<BabyProfile> updateBaby(
    String id, {
    String? name,
    DateTime? birthDate,
    String? gender,
  }) async {
    final res = await _apiClient.patch(
      '/babies/$id',
      body: {
        if (name != null) 'name': name,
        if (birthDate != null) 'birthDate': birthDate.toIso8601String(),
        if (gender != null) 'gender': gender,
      },
    );
    return BabyProfile.fromJson(res as Map<String, dynamic>);
  }
}
