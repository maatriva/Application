import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/providers.dart';
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

  CaregiverAccessState({
    required this.permissions,
    required this.selectedDurationLabel,
    required this.activeSessions,
    required this.accessHistory,
    required this.qrToken,
    required this.isGeneratingQR,
    this.qrError,
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
    );
  }
}

class CaregiverAccessNotifier extends StateNotifier<CaregiverAccessState> {
  final CaregiverRepository _caregiverRepo;
  Timer? _countdownTimer;
  Timer? _pollTimer;

  CaregiverAccessNotifier({required CaregiverRepository caregiverRepo})
      : _caregiverRepo = caregiverRepo,
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
    loadSessions();
    _startTimer();
    _startPolling();
  }

  Duration parseDuration(String label) {
    final lower = label.toLowerCase().trim();
    if (lower.contains('15 min') || lower == '15m' || lower == '15 mins') {
      return const Duration(minutes: 15);
    }
    if (lower.contains('30 min') || lower == '30m' || lower == '30 mins') {
      return const Duration(minutes: 30);
    }
    if (lower.contains('45 min') || lower == '45m' || lower == '45 mins') {
      return const Duration(minutes: 45);
    }
    if (lower.contains('1 hour') || lower == '1 hr' || lower == '1h') {
      return const Duration(hours: 1);
    }
    if (lower.contains('2 hour') || lower == '2 hrs' || lower == '2h') {
      return const Duration(hours: 2);
    }
    if (lower.contains('4 hour') || lower == '4 hrs' || lower == '4h') {
      return const Duration(hours: 4);
    }
    if (lower.contains('12 hour') || lower == '12 hrs' || lower == '12h') {
      return const Duration(hours: 12);
    }
    if (lower.contains('24 hour') || lower == '24 hrs' || lower == '24h') {
      return const Duration(hours: 24);
    }
    return parseCustomDuration(label);
  }

  Future<void> loadSessions() async {
    try {
      final sessions = await _caregiverRepo.getActiveSessions();
      final history = await _caregiverRepo.getAccessHistory();
      
      final now = DateTime.now();
      final selectedDuration = parseDuration(state.selectedDurationLabel);

      final updatedSessions = sessions.map((s) {
        return s.copyWith(expiresAt: now.add(selectedDuration));
      }).toList();

      state = state.copyWith(
        activeSessions: updatedSessions,
        accessHistory: history,
      );
    } catch (_) {}
  }

  void _startTimer() {
    if (AppConfig.isTesting) return;
    _countdownTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateSessionStatuses();
    });
  }

  void _startPolling() {
    if (AppConfig.isTesting) return;
    // Silently refresh caregiver list every 8 seconds to pick up accepted invites!
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      loadSessions();
    });
  }

  void _updateSessionStatuses() {
    final now = DateTime.now();
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
    _generateNewQR(silent: true);

    // Instantly sync updated permissions to all active caregiver sessions in real-time (milliseconds)!
    for (final session in state.activeSessions) {
      await updateTemporaryPermissions(
        permissionId: session.id,
        permissions: updated,
      );
    }
  }

  void selectDuration(String label) {
    state = state.copyWith(selectedDurationLabel: label);
    final duration = parseDuration(label);
    final now = DateTime.now();
    final updatedSessions = state.activeSessions.map((s) {
      return s.copyWith(expiresAt: now.add(duration));
    }).toList();
    state = state.copyWith(activeSessions: updatedSessions);
    _generateNewQR(silent: true);
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

  void _generateNewQR({
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
      
      final now = DateTime.now();
      final updatedSessions = state.activeSessions.map((s) {
        return s.copyWith(expiresAt: now.add(duration));
      }).toList();

      state = state.copyWith(
        qrToken: token,
        activeSessions: updatedSessions,
        isGeneratingQR: false,
        clearQrError: true,
      );
      // Reload sessions list to show the new pending invitation immediately
      loadSessions();
    } catch (e) {
      debugPrint('[QR] ❌ generateInviteToken FAILED: $e');
      state = state.copyWith(
        isGeneratingQR: false,
        qrError: e.toString(),
      );
    }
  }

  /// Public method to retry QR generation after a failure
  void retryGenerateQR() {
    _generateNewQR(silent: false);
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
      durationText: 'Revoked',
      isExpired: true,
    );

    state = state.copyWith(
      activeSessions: state.activeSessions
          .where((s) => s.id != sessionId)
          .toList(),
      accessHistory: [historyEntry, ...state.accessHistory],
    );

    // Automatically regenerate QR code for parent account
    _generateNewQR(silent: false);

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
    try {
      await _caregiverRepo.updatePermissions(permissionId, permissions);
      await loadSessions();
      return true;
    } catch (e) {
      debugPrint('[CaregiverAccessNotifier] updateTemporaryPermissions error: $e');
      return false;
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
    final lower = label.toLowerCase();
    final hoursMatch = RegExp(r'(\d+)\s*(?:hours|hour|hrs|hr|h)').firstMatch(lower);
    final minsMatch = RegExp(r'(\d+)\s*(?:minutes|minute|mins|min|m)').firstMatch(lower);

    int hours = 0;
    int minutes = 0;

    if (hoursMatch != null) {
      hours = int.tryParse(hoursMatch.group(1) ?? '0') ?? 0;
    }
    if (minsMatch != null) {
      minutes = int.tryParse(minsMatch.group(1) ?? '0') ?? 0;
    } else if (hoursMatch == null) {
      final numMatch = RegExp(r'(\d+)').firstMatch(lower);
      if (numMatch != null) {
        final val = int.tryParse(numMatch.group(1) ?? '120') ?? 120;
        if (val >= 60) {
          hours = val ~/ 60;
          minutes = val % 60;
        } else {
          minutes = val;
        }
      }
    }

    if (hours == 0 && minutes == 0) {
      return const Duration(hours: 2);
    }
    return Duration(hours: hours, minutes: minutes);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }
}

final caregiverAccessProvider =
    StateNotifierProvider<CaregiverAccessNotifier, CaregiverAccessState>((ref) {
  final caregiverRepo = ref.watch(caregiverRepositoryProvider);
  return CaregiverAccessNotifier(caregiverRepo: caregiverRepo);
});
