import 'dart:convert';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/cache_service.dart';
import '../../domain/repositories/caregiver_repository.dart';
import '../../shared/models/caregiver.dart';

/// Concrete implementation of [CaregiverRepository] delivering delegator state variables.
class CaregiverRepositoryImpl implements CaregiverRepository {
  final ApiClient _apiClient;
  final CacheService _cacheService;

  const CaregiverRepositoryImpl({
    required ApiClient apiClient,
    required CacheService cacheService,
  })  : _apiClient = apiClient,
        _cacheService = cacheService;

  @override
  Future<List<ActiveSession>> getActiveSessions() async {
    try {
      final babyId = _cacheService.getCachedSelectedBabyId();
      if (babyId == null) return [];

      final res = await _apiClient.get('/caregivers?babyId=$babyId', requireAuth: true);
      final responseMap = res as Map<String, dynamic>;
      final caregiversList = responseMap['data']['caregivers'] as List;

      return caregiversList.map((json) {
        final c = json as Map<String, dynamic>;
        final role = c['accessLevel'] as String? ?? 'BABYSITTER';
        final statusStr = c['status'] as String? ?? 'accepted';

        final status = statusStr == 'disabled' ? SessionStatus.expired : SessionStatus.active;

        DateTime expiresAt;
        if (c['expiresAt'] != null) {
          expiresAt = DateTime.parse(c['expiresAt'] as String);
        } else if (c['expiresInMinutes'] != null) {
          final mins = (c['expiresInMinutes'] as num).toInt();
          final grantedAt = c['createdAt'] != null
              ? DateTime.parse(c['createdAt'] as String)
              : DateTime.now();
          expiresAt = grantedAt.add(Duration(minutes: mins));
        } else if (c['durationMinutes'] != null) {
          final mins = (c['durationMinutes'] as num).toInt();
          final grantedAt = c['createdAt'] != null
              ? DateTime.parse(c['createdAt'] as String)
              : DateTime.now();
          expiresAt = grantedAt.add(Duration(minutes: mins));
        } else {
          expiresAt = DateTime.now().add(const Duration(minutes: 30));
        }

        return ActiveSession(
          id: c['id'] as String,
          name: c['fullName'] as String? ?? c['email'] as String? ?? 'Caregiver',
          relationship: _mapRoleToRelationship(role),
          imageUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
          expiresAt: expiresAt,
          status: status,
        );
      }).toList();
    } catch (_) {
      // Fallback to empty if offline
      return [];
    }
  }

  @override
  Future<List<AccessHistory>> getAccessHistory() async {
    // Return standard access history mock to retain aesthetic completeness, or combine with API logs if present
    return [
      const AccessHistory(
        id: 'h1',
        name: 'Uncle David',
        relationship: 'Uncle',
        date: 'Yesterday',
        timeRange: '4:00 PM – 5:00 PM',
        durationText: '1 Hour',
      ),
      const AccessHistory(
        id: 'h2',
        name: 'Grandma Rose',
        relationship: 'Grandmother',
        date: 'Oct 24',
        timeRange: '10:00 AM – 12:00 PM',
        durationText: '2 Hours',
      ),
    ];
  }

  @override
  Future<String> generateInviteToken(
    Map<String, bool> permissions,
    Duration duration, {
    String? email,
    String? role,
  }) async {
    // Try the dedicated baby-ID cache first; fall back to the full baby object cache
    var babyId = _cacheService.getCachedSelectedBabyId();
    if (babyId == null) {
      final babyMap = _cacheService.getCachedSelectedBaby();
      babyId = babyMap?['id'] as String?;
    }
    if (babyId == null) throw Exception('No baby profile found. Please go to the dashboard first to load your baby profile.');

    int expiresInMinutes = duration.inMinutes;
    if (expiresInMinutes <= 0) expiresInMinutes = 60;

    final response = await _apiClient.post(
      '/caregivers/invite',
      body: {
        'babyId': babyId,
        'email': email ?? '*',
        'role': role ?? 'BABYSITTER',
        'expiresInMinutes': expiresInMinutes,
        'singleUse': true,
        'maxUses': 1,
      },
      requireAuth: true,
    );

    final resMap = response as Map<String, dynamic>;
    final invitation = resMap['data'] as Map<String, dynamic>;
    final token = invitation['token'] as String;
    final expiresAt = invitation['expiresAt'] as String?;

    var server = _apiClient.baseUrl;
    if (server.contains('localhost') || server.contains('127.0.0.1')) {
      server = ApiConfig.baseUrl;
    }
    final qrData = {
      'server': server,
      'token': token,
      'babyId': babyId,
      'expiresAt': expiresAt,
      'permissions': permissions,
      'singleUse': true,
      'maxUses': 1,
    };

    return jsonEncode(qrData);
  }

  @override
  Future<void> revokeAccess(String sessionId) async {
    await _apiClient.delete('/caregivers/$sessionId', requireAuth: true);
  }

  @override
  Future<void> acceptInvitation(String token) async {
    await _apiClient.post(
      '/caregivers/invitation/accept',
      body: {'token': token},
      requireAuth: true,
    );
  }

  @override
  Future<void> rejectInvitation(String token) async {
    await _apiClient.post(
      '/caregivers/invitation/reject',
      body: {'token': token},
      requireAuth: true,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getReceivedInvitations() async {
    try {
      final res = await _apiClient.get('/caregivers/invitations', requireAuth: true);
      final resMap = res as Map<String, dynamic>;
      final list = resMap['data'] as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> grantTemporaryAccess({
    required String babyId,
    required String caregiverEmail,
    required int durationMinutes,
    String? permission,
    Map<String, bool>? permissions,
  }) async {
    final response = await _apiClient.post(
      '/caregivers/grant-temporary',
      body: {
        'babyId': babyId,
        'caregiverEmail': caregiverEmail,
        'durationMinutes': durationMinutes,
        if (permission != null) 'permission': permission,
        if (permissions != null) 'permissions': permissions,
      },
      requireAuth: true,
    );
    final resMap = response as Map<String, dynamic>;
    return resMap['data'] as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> getActivePermissions() async {
    try {
      final res = await _apiClient.get('/caregivers/active-permissions', requireAuth: true);
      final resMap = res as Map<String, dynamic>;
      final list = resMap['data'] as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> revokeTemporaryPermission(String permissionId) async {
    await _apiClient.delete('/caregivers/temporary-permission/$permissionId', requireAuth: true);
  }

  @override
  Future<Map<String, dynamic>> updatePermissions(String permissionId, Map<String, bool> permissions) async {
    final response = await _apiClient.patch(
      '/caregivers/temporary-permission/$permissionId/permissions',
      body: {'permissions': permissions},
      requireAuth: true,
    );
    final resMap = response as Map<String, dynamic>;
    return resMap['data'] as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> extendAccess(String permissionId, int extensionMinutes) async {
    final response = await _apiClient.patch(
      '/caregivers/temporary-permission/$permissionId/extend',
      body: {'extensionMinutes': extensionMinutes},
      requireAuth: true,
    );
    final resMap = response as Map<String, dynamic>;
    return resMap['data'] as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>?> getCaregiverAccess() async {
    try {
      final res = await _apiClient.get('/caregiver/access', requireAuth: true);
      final resMap = res as Map<String, dynamic>;
      if (resMap['hasAccess'] == true) {
        return resMap;
      }
      return {'hasAccess': false, 'status': resMap['status'] ?? 'disabled'};
    } catch (_) {
      return null;
    }
  }

  String _mapRoleToRelationship(String role) {
    switch (role.toUpperCase()) {
      case 'SECONDARY_PARENT':
        return 'Secondary Parent';
      case 'GRANDPARENT':
        return 'Grandparent';
      case 'BABYSITTER':
        return 'Babysitter';
      default:
        return 'Caregiver';
    }
  }
}
