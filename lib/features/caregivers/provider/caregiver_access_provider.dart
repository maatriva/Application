import 'dart:async';
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

  CaregiverAccessState({
    required this.permissions,
    required this.selectedDurationLabel,
    required this.activeSessions,
    required this.accessHistory,
    required this.qrToken,
    required this.isGeneratingQR,
  });

  CaregiverAccessState copyWith({
    Map<String, bool>? permissions,
    String? selectedDurationLabel,
    List<ActiveSession>? activeSessions,
    List<AccessHistory>? accessHistory,
    String? qrToken,
    bool? isGeneratingQR,
  }) {
    return CaregiverAccessState(
      permissions: permissions ?? this.permissions,
      selectedDurationLabel:
          selectedDurationLabel ?? this.selectedDurationLabel,
      activeSessions: activeSessions ?? this.activeSessions,
      accessHistory: accessHistory ?? this.accessHistory,
      qrToken: qrToken ?? this.qrToken,
      isGeneratingQR: isGeneratingQR ?? this.isGeneratingQR,
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
              'ai_assistant': true,
              'notifications': true,
              'emergency_alerts': true,
              'camera_snapshot': false,
            },
            selectedDurationLabel: '30 Mins',
            activeSessions: [],
            accessHistory: [],
            qrToken: 'MAATRIVA_MOCK_SECURE_TOKEN_7F8D2E',
            isGeneratingQR: false,
          ),
        ) {
    loadSessions();
    _startTimer();
    _startPolling();
  }

  Future<void> loadSessions() async {
    try {
      final sessions = await _caregiverRepo.getActiveSessions();
      final history = await _caregiverRepo.getAccessHistory();
      state = state.copyWith(
        activeSessions: sessions,
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

  void togglePermission(String key) {
    final updated = Map<String, bool>.from(state.permissions);
    updated[key] = !(updated[key] ?? false);
    state = state.copyWith(permissions: updated);
    _generateNewQR(silent: true);
  }

  void selectDuration(String label) {
    state = state.copyWith(selectedDurationLabel: label);
    _generateNewQR(silent: true);
  }

  void generateNewQR() {
    _generateNewQR(silent: false);
  }

  void _generateNewQR({
    required bool silent,
    String? email,
    String? role,
  }) async {
    if (!silent) {
      state = state.copyWith(isGeneratingQR: true);
    }

    Duration duration;
    switch (state.selectedDurationLabel.toLowerCase()) {
      case '30 mins':
      case '30 minutes':
        duration = const Duration(minutes: 30);
        break;
      case '1 hour':
      case '1 hr':
        duration = const Duration(hours: 1);
        break;
      case '4 hours':
      case '4 hrs':
        duration = const Duration(hours: 4);
        break;
      default:
        duration = const Duration(hours: 2);
    }

    try {
      final token = await _caregiverRepo.generateInviteToken(
        state.permissions,
        duration,
        email: email,
        role: role,
      );
      state = state.copyWith(
        qrToken: token,
        isGeneratingQR: false,
      );
      // Reload sessions list to show the new pending invitation immediately
      loadSessions();
    } catch (_) {
      state = state.copyWith(isGeneratingQR: false);
    }
  }

  void revokeSession(String sessionId) async {
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

    // Trigger secure invitation token generation with selected email/role on the backend
    _generateNewQR(
      silent: false,
      email: name.contains('@') ? name : null,
      role: role,
    );
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
