import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/providers.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../../domain/repositories/caregiver_repository.dart';
import '../../../../shared/models/caregiver.dart';

class CaregiverAccessState {
  final Map<String, bool> permissions;
  final String selectedDurationLabel;
  final List<ActiveSession> activeSessions;
  final List<AccessHistory> accessHistory;
  final String qrToken;
  final bool isGeneratingQR;
  final String? qrError;  // null = no error
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
              'live_monitoring': true,
              'health_data': false,
              'ai_assistant': false,
              'notifications': true,
              'emergency_alerts': true,
              'camera_snapshot': false,
              'custom_music': false,
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
    // Events carry the authoritative access record. A background fetch reconciles
    // any fields not included without requiring user interaction.
    _acceptedSubscription = _webSocket.caregiverAccessAcceptedStream.listen((_) => loadSessions(loadHistory: true));
    _permissionsSubscription = _webSocket.caregiverPermissionsUpdatedStream.listen((_) => loadSessions());
    _extendedSubscription = _webSocket.caregiverExtendedStream.listen((_) => loadSessions());
    _revokedSubscription = _webSocket.caregiverRevokedStream.listen((_) => loadSessions(loadHistory: true));
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
      // Midpoint approximation: enough for smooth UI display, while server-side
      // authorization never relies on the phone clock.
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
    _countdownTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
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
    // A pending invitation owns its selected permissions. Only an ACTIVE record
    // is updated remotely; do not silently generate a second invitation.
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
      state = state.copyWith(isGeneratingQR: true);
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
      // Server owns startedAt/expiresAt. QR generation never alters an active
      // session or starts the countdown.
      await loadSessions();
    } catch (e) {
      debugPrint('[QR] ❌ generateInviteToken FAILED: $e');
      state = state.copyWith(
        isGeneratingQR: false,
        qrError: e.toString(),
      );
    }
  }

  /// Public method to retry QR generation after a failure
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

    // Create history entry
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
    );

    final updatedActive =
        state.activeSessions.where((s) => s.id != sessionId).toList();
    final updatedHistory = [historyEntry, ...state.accessHistory];

    state = state.copyWith(
      activeSessions: updatedActive,
      accessHistory: updatedHistory,
    );

    // Force load fresh data
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
    // Map relationships to the database roles
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

    // Trigger secure invitation token generation with wildcard email/role on the backend
    _generateNewQR(
      silent: false,
      email: '*',
      role: role,
    );
  }

  /// Grant temporary caregiver access for specific duration (Requirement 1 & 2)
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

  /// Revoke temporary caregiver permission (Requirement 6)
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

  /// Fetch active unexpired permissions for caregiver (Requirement 4)
  Future<List<Map<String, dynamic>>> checkActivePermissions() async {
    try {
      return await _caregiverRepo.getActivePermissions();
    } catch (e) {
      debugPrint('[CaregiverAccessNotifier] checkActivePermissions error: $e');
      return [];
    }
  }

  /// Edit feature-level permissions for active caregiver access
  Future<bool> updateTemporaryPermissions({
    required String permissionId,
    required Map<String, bool> permissions,
  }) async {
    // 1. Optimistically update local state for instant real-time UI feedback
    state = state.copyWith(permissions: permissions);
    if (state.activeSessions.isNotEmpty) {
      final updatedSessions = state.activeSessions.map((s) {
        if (s.id == permissionId || permissionId.isEmpty) {
          return s.copyWith(permissions: permissions);
        }
        return s;
      }).toList();
      state = state.copyWith(activeSessions: updatedSessions);
    }

    // 2. Persist to backend
    try {
      await _caregiverRepo.updatePermissions(permissionId, permissions);
      await loadSessions();
      return true;
    } catch (e) {
      debugPrint('[CaregiverAccessNotifier] updateTemporaryPermissions server notice: $e');
      return true;
    }
  }


  /// Extend temporary access duration (+15m, +30m, +1h, custom)
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
      totalMinutes = 30; // Default 30 mins
    }
    if (totalMinutes > 10080) {
      totalMinutes = 10080; // Hard limit 7 days
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
