import '../../core/errors/api_exception.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/cache_service.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../shared/models/profile.dart';

/// Concrete implementation of [ProfileRepository] storing parent configs inside [CacheService].
class ProfileRepositoryImpl implements ProfileRepository {
  final ApiClient _apiClient;
  final CacheService _cacheService;

  const ProfileRepositoryImpl({
    required ApiClient apiClient,
    required CacheService cacheService,
  })  : _apiClient = apiClient,
        _cacheService = cacheService;

  @override
  Future<ProfileState> getProfile() async {
    try {
      final res = await _apiClient.get('/auth/profile', requireAuth: true);
      final responseMap = res as Map<String, dynamic>;
      final dataMap = responseMap['data'] as Map<String, dynamic>;
      final fullName = dataMap['fullName'] as String? ?? '';
      final email = dataMap['email'] as String? ?? '';

      final cachedMap = _cacheService.getCachedUserProfile();
      ProfileState profile;

      if (cachedMap != null) {
        profile = ProfileState.fromJson(cachedMap).copyWith(
          parentName: fullName,
          parentEmail: email,
        );
      } else {
        // Default Initial State matching profile notifier
        profile = ProfileState(
          parentName: fullName,
          parentEmail: email,
          parentPhone: '',
          parentAvatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=256',
          relationship: '',
          partnerName: '',
          partnerPhone: '',
          emergencyContactName: '',
          emergencyContactPhone: '',
          babyName: '',
          babyDob: '',
          babyGender: '',
          babyWeight: 0.0,
          babyHeight: 0.0,
          babyAvatar: '',
          allergies: '',
          pediatricianName: '',
          pediatricianPhone: '',
          vaccines: const [
            VaccineRecord(
              id: 'v1',
              name: 'Hepatitis B (HepB)',
              ageDue: 'Birth',
              status: 'Administered',
              dateAdministered: '10/12/2025',
            ),
            VaccineRecord(
              id: 'v2',
              name: 'Rotavirus (RV)',
              ageDue: '2 Months',
              status: 'Administered',
              dateAdministered: '12/15/2025',
            ),
            VaccineRecord(
              id: 'v3',
              name: 'DTaP (Diphtheria, Tetanus, Pertussis)',
              ageDue: '2 Months',
              status: 'Administered',
              dateAdministered: '12/15/2025',
            ),
            VaccineRecord(
              id: 'v4',
              name: 'Haemophilus influenzae type b (Hib)',
              ageDue: '4 Months',
              status: 'Administered',
              dateAdministered: '02/16/2026',
            ),
            VaccineRecord(
              id: 'v5',
              name: 'Pneumococcal Conjugate (PCV13)',
              ageDue: '6 Months',
              status: 'Pending',
              dateAdministered: '--',
            ),
            VaccineRecord(
              id: 'v6',
              name: 'Inactivated Poliovirus (IPV)',
              ageDue: '6 Months',
              status: 'Pending',
              dateAdministered: '--',
            ),
          ],
          devices: const [
            ConnectedDevice(
              id: 'd1',
              name: 'Maatriva Smart Cam 4K',
              type: 'Camera',
              isConnected: true,
              batteryLevel: -1,
            ),
            ConnectedDevice(
              id: 'd2',
              name: 'Maatriva Smart Sock V2',
              type: 'Smart Sock',
              isConnected: true,
              batteryLevel: 82,
            ),
            ConnectedDevice(
              id: 'd3',
              name: 'Maatriva Nursery Hub',
              type: 'Hub',
              isConnected: false,
              batteryLevel: -1,
            ),
          ],
          cryAlerts: true,
          tempAlerts: true,
          feedingReminders: false,
          sleepAnalysisWeekly: true,
          abnormalHeartRateAlerts: true,
          twoFactorAuth: false,
          biometricLogin: true,
          shareDataWithPediatrician: true,
        );
      }

      await _cacheService.cacheUserProfile(profile.toJson());
      return profile;
    } catch (e) {
      if (e is ApiException && e.statusCode != 0) {
        rethrow;
      }
      // Offline/local cached fallback
      final cachedMap = _cacheService.getCachedUserProfile();
      if (cachedMap != null) {
        return ProfileState.fromJson(cachedMap);
      }
      rethrow;
    }
  }

  @override
  Future<ProfileState> updateProfile(ProfileState profile) async {
    try {
      await _apiClient.patch(
        '/auth/profile',
        body: {
          'fullName': profile.parentName,
          'email': profile.parentEmail,
        },
        requireAuth: true,
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      // Offline fallback: allow local updates anyway
    } finally {
      await _cacheService.cacheUserProfile(profile.toJson());
    }
    return profile;
  }
}
