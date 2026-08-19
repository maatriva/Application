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
  Future<DateTime> getServerTime() async {
    final res = await _apiClient.get('/caregivers/server-time', requireAuth: true);
    final map = res as Map<String, dynamic>;
    final data = map['data'] as Map<String, dynamic>? ?? map;
    final raw = data['serverTime'] as String?;
    if (raw == null) throw const FormatException('Server time missing from response.');
    return DateTime.parse(raw).toLocal();
  }

  @override
  Future<List<ActiveSession>> getActiveSessions() async {
    try {
      final babyId = _cacheService.getCachedSelectedBabyId();
      if (babyId == null) return [];

      final res = await _apiClient.get('/caregivers?babyId=$babyId', requireAuth: true);
      final responseMap = res as Map<String, dynamic>;
      final dataMap = responseMap['data'] as Map<String, dynamic>? ?? {};
      final caregiversList = (dataMap['caregivers'] as List?) ?? [];
      final tempPermissionsList = (dataMap['temporaryPermissions'] as List?) ?? [];

      final List<ActiveSession> sessions = [];

      // Parse temporary permissions (Primary temporary access model)
      for (final json in tempPermissionsList) {
        final tp = json as Map<String, dynamic>;
        // A PENDING record is a QR invitation, not an active caregiver.
        if ((tp['status'] as String? ?? '').toUpperCase() != 'ACTIVE') continue;
        final String permId = tp['id'] as String? ?? '';
        final String name = tp['caregiverName'] as String? ?? tp['caregiverEmail'] as String? ?? 'Guest Caregiver';
        final String? expiresAtRaw = tp['expiresAt'] as String? ?? tp['expires_at'] as String? ?? tp['expiry'] as String? ?? tp['validUntil'] as String?;
        DateTime expiresAt;
        if (expiresAtRaw != null && expiresAtRaw.isNotEmpty) {
          expiresAt = DateTime.parse(expiresAtRaw);
        } else {
          final mins = (tp['durationMinutes'] as int?) ?? (tp['expiresInMinutes'] as int?) ?? 30;
          final String? createdAtRaw = tp['createdAt'] as String? ?? tp['created_at'] as String?;
          final DateTime start = createdAtRaw != null ? DateTime.parse(createdAtRaw) : DateTime.now();
          expiresAt = start.add(Duration(minutes: mins));
        }

        final String statusStr = tp['status'] as String? ?? 'ACTIVE';

        final now = DateTime.now();
        SessionStatus status = SessionStatus.active;
        if (statusStr == 'EXPIRED' || expiresAt.isBefore(now)) {
          status = SessionStatus.expired;
        } else if (expiresAt.difference(now).inMinutes <= 15) {
          status = SessionStatus.expiring;
        }

        final perms = _parsePermissionsMap(tp);

        sessions.add(ActiveSession(
          id: permId,
          name: name,
          relationship: tp['permission'] == 'LIVE_MONITOR_ONLY' ? 'Temporary Caregiver' : 'Caregiver',
          imageUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=150&q=80',
          expiresAt: expiresAt,
          status: status,
          permissions: perms,
        ));
      }

      // Parse legacy caregivers if no temporary permissions exist
      if (sessions.isEmpty) {
        final now = DateTime.now();
        for (final json in caregiversList) {
          final c = json as Map<String, dynamic>;
          final role = c['accessLevel'] as String? ?? 'BABYSITTER';
          final statusStr = (c['status'] as String? ?? 'accepted').toLowerCase();

          final String? expiresAtRaw = c['expiresAt'] as String? ?? c['expires_at'] as String? ?? c['expiry'] as String?;
          DateTime expiresAt;
          if (expiresAtRaw != null && expiresAtRaw.isNotEmpty) {
            expiresAt = DateTime.parse(expiresAtRaw);
          } else {
            final mins = (c['durationMinutes'] as int?) ?? (c['expiresInMinutes'] as int?) ?? 30;
            final String? createdAtRaw = c['createdAt'] as String? ?? c['created_at'] as String?;
            final DateTime start = createdAtRaw != null ? DateTime.parse(createdAtRaw) : DateTime.now();
            expiresAt = start.add(Duration(minutes: mins));
          }

          SessionStatus status = SessionStatus.active;
          if (statusStr == 'disabled' || statusStr == 'expired' || statusStr == 'revoked' || expiresAt.isBefore(now)) {
            status = SessionStatus.expired;
          } else if (expiresAt.difference(now).inMinutes <= 15) {
            status = SessionStatus.expiring;
          }

          sessions.add(ActiveSession(
            id: c['id'] as String,
            name: c['fullName'] as String? ?? c['email'] as String? ?? 'Caregiver',
            relationship: _mapRoleToRelationship(role),
            imageUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
            expiresAt: expiresAt,
            status: status,
            permissions: _parsePermissionsMap(c),
          ));
        }
      }


      return sessions;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<AccessHistory>> getAccessHistory() async {
    try {
      final babyId = _cacheService.getCachedSelectedBabyId();
      if (babyId == null) return [];

      final res = await _apiClient.get('/caregivers/history?babyId=$babyId', requireAuth: true);
      final responseMap = res as Map<String, dynamic>;
      final dataList = (responseMap['data'] as List?) ?? [];

      return dataList.map((item) {
        final map = item as Map<String, dynamic>;
        final String name = map['caregiverName'] as String? ?? map['caregiverEmail'] as String? ?? 'Caregiver';
        final String grantedAtStr = map['grantedAt'] as String? ?? map['createdAt'] as String? ?? DateTime.now().toIso8601String();
        final String expiresAtStr = map['expiresAt'] as String? ?? DateTime.now().toIso8601String();

        final grantedAt = DateTime.parse(grantedAtStr);
        final expiresAt = DateTime.parse(expiresAtStr);

        final startHour = grantedAt.hour > 12 ? grantedAt.hour - 12 : (grantedAt.hour == 0 ? 12 : grantedAt.hour);
        final startAmpm = grantedAt.hour >= 12 ? 'PM' : 'AM';
        final endHour = expiresAt.hour > 12 ? expiresAt.hour - 12 : (expiresAt.hour == 0 ? 12 : expiresAt.hour);
        final endAmpm = expiresAt.hour >= 12 ? 'PM' : 'AM';

        final timeRange = '${startHour.toString().padLeft(2, '0')}:${grantedAt.minute.toString().padLeft(2, '0')} $startAmpm – ${endHour.toString().padLeft(2, '0')}:${expiresAt.minute.toString().padLeft(2, '0')} $endAmpm';
        final dateLabel = '${grantedAt.day} ${_formatShortMonth(grantedAt.month)} ${grantedAt.year}';

        final statusStr = map['status'] as String? ?? 'EXPIRED';
        final isRevoked = statusStr.toUpperCase() == 'REVOKED';
        final isTimeExpired = expiresAt.isBefore(DateTime.now());
        final isExpired = isRevoked || statusStr.toUpperCase() == 'EXPIRED' || isTimeExpired;

        String displayStatus = 'Expired';
        if (isRevoked) {
          displayStatus = 'Revoked';
        } else if (!isExpired && statusStr.toUpperCase() == 'ACTIVE') {
          displayStatus = 'Active';
        } else {
          displayStatus = 'Expired';
        }

        return AccessHistory(
          id: map['id'] as String? ?? '',
          name: name,
          relationship: map['permission'] == 'LIVE_MONITOR_ONLY' ? 'Temporary Caregiver' : 'Caregiver',
          date: dateLabel,
          timeRange: timeRange,
          durationText: map['durationText'] as String? ?? '1 Hour',
          isExpired: isExpired,
          status: displayStatus,
        );
      }).toList().cast<AccessHistory>();
    } catch (_) {
      return [];
    }
  }

  String _formatShortMonth(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[(m - 1) % 12];
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
    if (expiresInMinutes <= 0) expiresInMinutes = 30;
    if (expiresInMinutes > 10080) expiresInMinutes = 10080; // Hard maximum 7 days

    final response = await _apiClient.post(
      '/caregivers/grant-temporary',
      body: {
        'babyId': babyId,
        'caregiverEmail': email == '*' ? null : email,
        'permission': role ?? 'LIVE_MONITOR_ONLY',
        'durationMinutes': expiresInMinutes,
        'permissions': permissions,
      },
      requireAuth: true,
    );

    final resMap = response as Map<String, dynamic>;
    final invitation = (resMap['data'] as Map<String, dynamic>?) ?? resMap;
    final token = (invitation['invitationToken'] as String?) ?? '';
    final expiresAt = invitation['invitationExpiresAt'] as String?;

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
    int sanitizedMinutes = durationMinutes;
    if (sanitizedMinutes <= 0) sanitizedMinutes = 30;
    if (sanitizedMinutes > 10080) sanitizedMinutes = 10080;

    final response = await _apiClient.post(
      '/caregivers/grant-temporary',
      body: {
        'babyId': babyId,
        'caregiverEmail': caregiverEmail,
        'durationMinutes': sanitizedMinutes,
        'expiresInMinutes': sanitizedMinutes,
        if (permission != null) 'permission': permission,
        if (permissions != null) 'permissions': permissions,
      },
      requireAuth: true,
    );
    final resMap = response as Map<String, dynamic>;
    return (resMap['data'] as Map<String, dynamic>?) ?? resMap;
  }

  @override
  Future<List<Map<String, dynamic>>> getActivePermissions() async {
    try {
      final res = await _apiClient.get('/caregivers/active-permissions', requireAuth: true);
      final resMap = res as Map<String, dynamic>;
      final list = (resMap['data'] as List?) ?? [];
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
    final babyId = _cacheService.getCachedSelectedBabyId();
    final payload = {
      if (babyId != null) 'babyId': babyId,
      'caregiverId': permissionId,
      'sessionId': permissionId,
      'permissionId': permissionId,
      'permissions': permissions,
      'permission': permissions.entries.where((e) => e.value).map((e) => e.key).join(','),
      'canViewLiveMonitoring': permissions['live_monitoring'] ?? true,
      'canViewTelemetry': permissions['health_data'] ?? false,
      'canViewCamera': permissions['camera_snapshot'] ?? false,
      'canReceiveAlerts': permissions['emergency_alerts'] ?? permissions['notifications'] ?? false,
      'canUseAi': permissions['ai_assistant'] ?? false,
      'canPlayMusic': permissions['custom_music'] ?? permissions['music'] ?? false,
      'canControlCradle': permissions['cradle_controls'] ?? false,
    };

    final candidateRoutes = [
      '/caregivers/permissions',
      '/caregivers/temporary-permissions/$permissionId/permissions',
      '/caregivers/temporary-permission/$permissionId/permissions',
      '/caregivers/$permissionId/permissions',
      '/caregivers/temporary-permissions/$permissionId',
      '/caregivers/$permissionId',
    ];

    dynamic response;
    for (final route in candidateRoutes) {
      try {
        response = await _apiClient.patch(route, body: payload, requireAuth: true);
        if (response != null) break;
      } catch (_) {
        try {
          response = await _apiClient.put(route, body: payload, requireAuth: true);
          if (response != null) break;
        } catch (_) {}
      }
    }


    if (response is Map<String, dynamic>) {
      if (response.containsKey('data') && response['data'] is Map<String, dynamic>) {
        return response['data'] as Map<String, dynamic>;
      }
      return response;
    }
    return {'success': true};
  }

  @override
  Future<Map<String, dynamic>> extendAccess(String permissionId, int extensionMinutes) async {
    final payload = {
      'extensionMinutes': extensionMinutes,
      'durationMinutes': extensionMinutes,
      'addMinutes': extensionMinutes,
    };

    dynamic response;
    try {
      response = await _apiClient.patch(
        '/caregivers/temporary-permission/$permissionId/extend',
        body: payload,
        requireAuth: true,
      );
    } catch (_) {
      response = await _apiClient.patch(
        '/caregivers/$permissionId/extend',
        body: payload,
        requireAuth: true,
      );
    }

    if (response is Map<String, dynamic>) {
      if (response.containsKey('data') && response['data'] is Map<String, dynamic>) {
        return response['data'] as Map<String, dynamic>;
      }
      return response;
    }
    return {'success': true};
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

  Map<String, bool> _parsePermissionsMap(Map<String, dynamic> json) {
    if (json['permissions'] is Map) {
      final Map map = json['permissions'] as Map;
      final Map<String, bool> res = {};
      map.forEach((k, v) {
        if (k is String) {
          res[k] = v == true || v == 'true' || v == 1;
        }
      });
      if (res.isNotEmpty) return res;
    }

    final Map<String, bool> res = {};
    if (json.containsKey('canViewLiveMonitoring') || json.containsKey('canViewCamera') || json.containsKey('canViewTelemetry')) {
      res['live_monitoring'] = json['canViewLiveMonitoring'] ?? true;
      res['camera_snapshot'] = json['canViewCamera'] ?? false;
      res['health_data'] = json['canViewTelemetry'] ?? false;
      res['emergency_alerts'] = json['canReceiveAlerts'] ?? false;
      res['notifications'] = json['canReceiveAlerts'] ?? false;
      res['ai_assistant'] = json['canUseAi'] ?? false;
      res['custom_music'] = json['canPlayMusic'] ?? false;
      res['cradle_controls'] = json['canControlCradle'] ?? false;
    }

    final permStr = json['permission'] as String?;
    if (permStr != null && permStr.isNotEmpty) {
      final tokens = permStr.split(',').map((s) => s.trim().toLowerCase()).toSet();
      if (tokens.contains('live_monitoring')) res['live_monitoring'] = true;
      if (tokens.contains('camera_snapshot') || tokens.contains('camera')) res['camera_snapshot'] = true;
      if (tokens.contains('health_data') || tokens.contains('telemetry')) res['health_data'] = true;
      if (tokens.contains('emergency_alerts') || tokens.contains('notifications') || tokens.contains('alerts')) {
        res['emergency_alerts'] = true;
        res['notifications'] = true;
      }
      if (tokens.contains('ai_assistant') || tokens.contains('ai')) res['ai_assistant'] = true;
      if (tokens.contains('custom_music') || tokens.contains('music')) res['custom_music'] = true;
      if (tokens.contains('cradle_controls') || tokens.contains('cradle')) res['cradle_controls'] = true;
    }

    return res.isNotEmpty
        ? res
        : {
            'live_monitoring': true,
            'health_data': false,
            'ai_assistant': false,
            'notifications': true,
            'emergency_alerts': true,
            'camera_snapshot': false,
            'custom_music': false,
          };
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
