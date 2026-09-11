import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/providers.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../../domain/repositories/caregiver_repository.dart';
import '../../../../shared/models/caregiver.dart';

import '../../../../core/errors/caregiver_error_mapper.dart';

class CaregiverAccessState {
  final Map<String, bool> permissions;
  final String selectedDurationLabel;
  final List<ActiveSession> activeSessions;
  final List<AccessHistory> accessHistory;
  final String qrToken;
  final bool isGeneratingQR;
  final String? qrError; // null = no error
  final Duration serverClockOffset;

  CaregiverAccessState({
    required this.permissions,
    required this.selectedDurationLabel,
    required this.activeSessions,
    required this.accessHistory,
    required this.qrToken,
    required this.isGeneratingQR,
    this.qrError,
    this.serverClockOffset = Duration.zero,
  });

  CaregiverAccessState copyWith({
    Map<String, bool>? permissions,
    String? selectedDurationLabel,
    List<ActiveSession>? activeSessions,
    List<AccessHistory>? accessHistory,
    String? qrToken,
    bool? isGeneratingQR,
    String? qrError,
    bool clearQrError = false,
    Duration? serverClockOffset,
  }) {
    return CaregiverAccessState(
      permissions: permissions ?? this.permissions,
      selectedDurationLabel:
          selectedDurationLabel ?? this.selectedDurationLabel,
      activeSessions: activeSessions ?? this.activeSessions,
      accessHistory: accessHistory ?? this.accessHistory,
      qrToken: qrToken ?? this.qrToken,
      isGeneratingQR: isGeneratingQR ?? this.isGeneratingQR,
      qrError: clearQrError ? null : (qrError ?? this.qrError),
      serverClockOffset: serverClockOffset ?? this.serverClockOffset,
    );
  }
}

class CaregiverAccessNotifier extends StateNotifier<CaregiverAccessState> {
  final CaregiverRepository _caregiverRepo;
  Timer? _countdownTimer;
  DateTime? _lastHistoryFetchTime;
  final WebSocketService? _webSocket;
  StreamSubscription<Map<String, dynamic>>? _acceptedSubscription;
  StreamSubscription<Map<String, dynamic>>? _permissionsSubscription;
  StreamSubscription<Map<String, dynamic>>? _extendedSubscription;
  StreamSubscription<String>? _revokedSubscription;
  StreamSubscription<WsConnectionState>? _connectionSubscription;

  CaregiverAccessNotifier({required CaregiverRepository caregiverRepo, WebSocketService? webSocket})
      : _caregiverRepo = caregiverRepo,
        _webSocket = webSocket,
        super(
          CaregiverAccessState(
            permissions: {
              'live_video': true,
              'health': true,
              'ai_monitoring': true,
              'ai_chatbot': true,
              'custom_parent_folder': true,
              'shop': true,
              'real_time_alerts': true,
              'camera_snapshot': true,
              'health_data': true,
              'ai_assistant': true,
              'custom_music': true,
              'emergency_alerts': true,
            },
            selectedDurationLabel: '30 Mins',
            activeSessions: [],
            accessHistory: [],
            qrToken: '',
            isGeneratingQR: false,
          ),
        ) {
    loadSessions(loadHistory: true);
    _startTimer();
    _listenForAccessEvents();
  }

  void _listenForAccessEvents() {
    if (_webSocket == null) return;

    _acceptedSubscription = _webSocket.caregiverAccessAcceptedStream.listen((data) {
      debugPrint('[CaregiverAccessNotifier] Real-time socket event caregiver.access.accepted: $data');
      final permId = data['accessId'] as String? ?? data['permissionId'] as String? ?? '';
      final caregiverName = data['caregiverName'] as String? ?? 'Caregiver';
      final expiresAtStr = data['expiresAt'] as String?;
      final expiresAt = expiresAtStr != null
          ? DateTime.tryParse(expiresAtStr) ?? DateTime.now().add(const Duration(minutes: 30))
          : DateTime.now().add(const Duration(minutes: 30));

      final Map<String, bool> perms = data['permissions'] is Map
          ? Map<String, bool>.from((data['permissions'] as Map).map((k, v) => MapEntry(k.toString(), v == true)))
          : state.permissions;

      final newSession = ActiveSession(
        id: permId,
        name: caregiverName,
        relationship: 'Caregiver',
        imageUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=150&q=80',
        expiresAt: expiresAt,
        status: SessionStatus.active,
        permissions: perms,
      );

      final updated = [newSession, ...state.activeSessions.where((s) => s.id != permId)];
      state = state.copyWith(
        activeSessions: updated,
        qrToken: '',
        isGeneratingQR: false,
        clearQrError: true,
      );
      loadSessions(loadHistory: true);
    });

    _permissionsSubscription = _webSocket.caregiverPermissionsUpdatedStream.listen((data) {
      final permId = data['accessId'] as String? ?? data['permissionId'] as String? ?? '';
      if (permId.isNotEmpty && data['permissions'] is Map) {
        final updatedPerms = Map<String, bool>.from((data['permissions'] as Map).map((k, v) => MapEntry(k.toString(), v == true)));
        final updatedSessions = state.activeSessions.map((s) {
          return s.id == permId ? s.copyWith(permissions: updatedPerms) : s;
        }).toList();
        state = state.copyWith(activeSessions: updatedSessions);
      }
      loadSessions();
    });

    _extendedSubscription = _webSocket.caregiverExtendedStream.listen((data) {
      final permId = data['accessId'] as String? ?? data['permissionId'] as String? ?? '';
      final newExpiresAtStr = data['expiresAt'] as String?;
      if (permId.isNotEmpty && newExpiresAtStr != null) {
        final newExpiresAt = DateTime.tryParse(newExpiresAtStr);
        if (newExpiresAt != null) {
          final updatedSessions = state.activeSessions.map((s) {
            return s.id == permId ? s.copyWith(expiresAt: newExpiresAt) : s;
          }).toList();
          state = state.copyWith(activeSessions: updatedSessions);
        }
      }
      loadSessions();
    });

    _revokedSubscription = _webSocket.caregiverRevokedStream.listen((revokedId) {
      if (revokedId.isNotEmpty) {
        final updated = state.activeSessions.where((s) => s.id != revokedId).toList();
        state = state.copyWith(activeSessions: updated);
      }
      loadSessions(loadHistory: true);
    });

    _connectionSubscription = _webSocket.stateStream.listen((connection) {
      if (connection == WsConnectionState.connected) loadSessions(loadHistory: true);
    });
  }

  Duration parseDuration(String label) {
    return parseCustomDuration(label);
  }

  Future<void> loadSessions({bool loadHistory = false}) async {
    try {
      final receivedAt = DateTime.now();
      final results = await Future.wait<dynamic>([
        _caregiverRepo.getActiveSessions(),
        _caregiverRepo.getServerTime(),
      ]);
      final sessions = results[0] as List<ActiveSession>;
      final serverTime = results[1] as DateTime;
      final offset = serverTime.difference(receivedAt);

      List<AccessHistory> history = state.accessHistory;
      final now = DateTime.now();
      if (loadHistory ||
          _lastHistoryFetchTime == null ||
          now.difference(_lastHistoryFetchTime!).inMinutes >= 5) {
        history = await _caregiverRepo.getAccessHistory();
        _lastHistoryFetchTime = now;
      }

      state = state.copyWith(
        activeSessions: sessions,
        accessHistory: history,
        serverClockOffset: offset,
      );
    } catch (_) {}
  }

  void _startTimer() {
    if (AppConfig.isTesting) return;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateSessionStatuses();
    });
  }

  void _updateSessionStatuses() {
    final now = DateTime.now().add(state.serverClockOffset);
    bool hasChanges = false;
    final updatedSessions = state.activeSessions.map((session) {
      final remaining = session.expiresAt.difference(now);
      SessionStatus targetStatus;
      if (remaining.isNegative) {
        targetStatus = SessionStatus.expired;
      } else if (remaining.inMinutes <= 15) {
        targetStatus = SessionStatus.expiring;
      } else {
        targetStatus = SessionStatus.active;
      }

      if (session.status != targetStatus) {
        hasChanges = true;
        return session.copyWith(status: targetStatus);
      }
      return session;
    }).toList();

    if (hasChanges) {
      state = state.copyWith(activeSessions: updatedSessions);
    }
  }

  Future<void> togglePermission(String key) async {
    final updated = Map<String, bool>.from(state.permissions);
    updated[key] = !(updated[key] ?? false);
    state = state.copyWith(permissions: updated);
    for (final session in state.activeSessions) {
      await updateTemporaryPermissions(
        permissionId: session.id,
        permissions: updated,
      );
    }
  }

  void selectDuration(String label) {
    state = state.copyWith(selectedDurationLabel: label);
  }

  Future<void> setDurationLabel(String label) async {
    state = state.copyWith(selectedDurationLabel: label);
  }

  Future<void> updatePermissionsConfig(Map<String, bool> perms) async {
    state = state.copyWith(permissions: perms);
  }

  void cancelPendingQR() {
    state = state.copyWith(qrToken: '', isGeneratingQR: false, clearQrError: true);
  }

  void generateNewQR() {
    _generateNewQR(silent: false);
  }

  void shareLiveMonitoring() {
    state = state.copyWith(selectedDurationLabel: '24 Hours');
    _generateNewQR(
      silent: false,
      email: '*',
      role: 'LIVE_MONITOR_ONLY',
    );
  }

  Future<void> _generateNewQR({
    required bool silent,
    String? email,
    String? role,
  }) async {
    if (!silent) {
      state = state.copyWith(isGeneratingQR: true, clearQrError: true);
    }

    final duration = parseDuration(state.selectedDurationLabel);

    try {
      final token = await _caregiverRepo.generateInviteToken(
        state.permissions,
        duration,
        email: email,
        role: role,
      );
      debugPrint('[QR] Token generated successfully with duration: ${duration.inMinutes}m. Data length: ${token.length}');
      
      state = state.copyWith(
        qrToken: token,
        isGeneratingQR: false,
        clearQrError: true,
      );
      await loadSessions();
    } catch (e, stackTrace) {
      debugPrint('[QR] ❌ generateInviteToken FAILED: $e\n$stackTrace');
      final userMessage = CaregiverErrorMapper.map(e);
      state = state.copyWith(
        isGeneratingQR: false,
        qrError: userMessage,
      );
    }
  }

  Future<void> retryGenerateQR() async {
    await _generateNewQR(silent: false);
  }

  Future<void> revokeSession(String sessionId) async {
    final sessionToRevoke = state.activeSessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => ActiveSession(
        id: sessionId,
        name: 'Caregiver',
        relationship: 'Caregiver',
        imageUrl: '',
        expiresAt: DateTime.now(),
        status: SessionStatus.expired,
      ),
    );

    try {
      await _caregiverRepo.revokeAccess(sessionId);
    } catch (_) {}

    final now = DateTime.now();
    final timeStr =
        "${_formatTime(now.subtract(const Duration(minutes: 30)))} – ${_formatTime(now)}";
    final historyEntry = AccessHistory(
      id: 'h_${now.millisecondsSinceEpoch}',
      name: sessionToRevoke.name,
      relationship: sessionToRevoke.relationship,
      date: 'Today',
      timeRange: timeStr,
      durationText: 'Expired',
      isExpired: true,
      status: 'REVOKED',
      timestamp: now,
    );

    final updatedActive =
        state.activeSessions.where((s) => s.id != sessionId).toList();
    final updatedHistory = [historyEntry, ...state.accessHistory];

    state = state.copyWith(
      activeSessions: updatedActive,
      accessHistory: updatedHistory,
      qrToken: '',
      isGeneratingQR: false,
    );

    loadSessions();
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $ampm';
  }

  void addCaregiverSession({
    required String name,
    required String relationship,
    required String durationLabel,
    required String imageUrl,
  }) {
    String role = 'BABYSITTER';
    final relLower = relationship.toLowerCase();
    if (relLower.contains('grand')) {
      role = 'GRANDPARENT';
    } else if (relLower.contains('nanny') ||
        relLower.contains('uncle') ||
        relLower.contains('aunt') ||
        relLower.contains('friend')) {
      role = 'SECONDARY_PARENT';
    }

    _generateNewQR(
      silent: false,
      email: '*',
      role: role,
    );
  }

  Future<bool> grantTemporaryAccess({
    required String babyId,
    required String caregiverEmail,
    required int durationMinutes,
    String? permission,
  }) async {
    try {
      await _caregiverRepo.grantTemporaryAccess(
        babyId: babyId,
        caregiverEmail: caregiverEmail,
        durationMinutes: durationMinutes,
        permission: permission,
      );
      await loadSessions();
      return true;
    } catch (e) {
      debugPrint('[CaregiverAccessNotifier] grantTemporaryAccess error: $e');
      return false;
    }
  }

  Future<bool> revokeTemporaryPermission(String permissionId) async {
    try {
      await _caregiverRepo.revokeTemporaryPermission(permissionId);
      await loadSessions();
      return true;
    } catch (e) {
      debugPrint('[CaregiverAccessNotifier] revokeTemporaryPermission error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> checkActivePermissions() async {
    try {
      return await _caregiverRepo.getActivePermissions();
    } catch (e) {
      debugPrint('[CaregiverAccessNotifier] checkActivePermissions error: $e');
      return [];
    }
  }

  Future<bool> updateTemporaryPermissions({
    required String permissionId,
    required Map<String, bool> permissions,
  }) async {
    debugPrint('[CaregiverAccessNotifier] Permission update requested for access $permissionId');
    state = state.copyWith(
      permissions: permissions,
      activeSessions: state.activeSessions.map((session) =>
          session.id == permissionId ? session.copyWith(permissions: permissions) : session).toList(),
    );

    if (permissionId.trim().isEmpty || permissionId.startsWith('h_')) {
      return true;
    }

    try {
      final updated = await _caregiverRepo.updatePermissions(permissionId, permissions);
      final persistedPermissions = updated['permissions'] is Map
          ? Map<String, bool>.from((updated['permissions'] as Map).map(
              (key, value) => MapEntry(key.toString(), value == true),
            ))
          : permissions;
      state = state.copyWith(
        permissions: persistedPermissions,
        activeSessions: state.activeSessions.map((session) =>
            session.id == permissionId ? session.copyWith(permissions: persistedPermissions) : session).toList(),
      );
      debugPrint('[CaregiverAccessNotifier] Permission update succeeded for access $permissionId');
      return true;
    } catch (e) {
      debugPrint('[CaregiverAccessNotifier] Remote permission sync notice: $e');
      return false;
    }
  }

  Future<bool> extendTemporaryAccess({
    required String permissionId,
    required int extensionMinutes,
  }) async {
    try {
      await _caregiverRepo.extendAccess(permissionId, extensionMinutes);
      await loadSessions();
      return true;
    } catch (e) {
      debugPrint('[CaregiverAccessNotifier] extendTemporaryAccess error: $e');
      return false;
    }
  }

  Duration parseCustomDuration(String label) {
    final lower = label.toLowerCase().trim();
    final daysMatch = RegExp(r'(\d+)\s*(?:days|day|d)\b').firstMatch(lower);
    final hoursMatch = RegExp(r'(\d+)\s*(?:hours|hour|hrs|hr|h)\b').firstMatch(lower);
    final minsMatch = RegExp(r'(\d+)\s*(?:minutes|minute|mins|min|m)\b').firstMatch(lower);

    int days = 0;
    int hours = 0;
    int minutes = 0;

    if (daysMatch != null) {
      days = int.tryParse(daysMatch.group(1) ?? '0') ?? 0;
    }
    if (hoursMatch != null) {
      hours = int.tryParse(hoursMatch.group(1) ?? '0') ?? 0;
    }
    if (minsMatch != null) {
      minutes = int.tryParse(minsMatch.group(1) ?? '0') ?? 0;
    } else if (daysMatch == null && hoursMatch == null) {
      final numMatch = RegExp(r'(\d+)').firstMatch(lower);
      if (numMatch != null) {
        final val = int.tryParse(numMatch.group(1) ?? '30') ?? 30;
        minutes = val;
      }
    }

    int totalMinutes = (days * 1440) + (hours * 60) + minutes;
    if (totalMinutes <= 0) {
      totalMinutes = 30;
    }
    if (totalMinutes > 10080) {
      totalMinutes = 10080;
    }

    return Duration(minutes: totalMinutes);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _acceptedSubscription?.cancel();
    _permissionsSubscription?.cancel();
    _extendedSubscription?.cancel();
    _revokedSubscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }
}

final caregiverAccessProvider =
    StateNotifierProvider<CaregiverAccessNotifier, CaregiverAccessState>((ref) {
  final caregiverRepo = ref.watch(caregiverRepositoryProvider);
  final webSocket = ref.watch(webSocketServiceProvider);
  return CaregiverAccessNotifier(caregiverRepo: caregiverRepo, webSocket: webSocket);
});
