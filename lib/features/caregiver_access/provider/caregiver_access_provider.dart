import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/caregiver.dart';

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
  Timer? _countdownTimer;

  CaregiverAccessNotifier()
    : super(
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
          activeSessions: [
            ActiveSession(
              id: '1',
              name: 'Grandma Rose',
              relationship: 'Grandmother',
              imageUrl:
                  'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=150&q=80',
              expiresAt: DateTime.now().add(const Duration(minutes: 12)),
              status: SessionStatus.expiring,
            ),
            ActiveSession(
              id: '2',
              name: 'Nanny Sarah',
              relationship: 'Nanny',
              imageUrl:
                  'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?auto=format&fit=crop&w=150&q=80',
              expiresAt: DateTime.now().add(
                const Duration(hours: 4, minutes: 20),
              ),
              status: SessionStatus.active,
            ),
            ActiveSession(
              id: '3',
              name: 'Babysitter Emma',
              relationship: 'Babysitter',
              imageUrl:
                  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80',
              expiresAt: DateTime.now().add(const Duration(hours: 24)),
              status: SessionStatus.active,
            ),
          ],
          accessHistory: [
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
            const AccessHistory(
              id: 'h3',
              name: 'Nanny Sarah',
              relationship: 'Nanny',
              date: 'Oct 22',
              timeRange: '12:00 PM – 2:00 PM',
              durationText: '2 Hours',
            ),
          ],
          qrToken: 'MAATRIVA_MOCK_SECURE_TOKEN_7F8D2E',
          isGeneratingQR: false,
        ),
      ) {
    _startTimer();
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateSessionStatuses();
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
    } else {
      // Force a trigger so the UI redraws time remaining text
      state = state.copyWith(activeSessions: [...state.activeSessions]);
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

  void _generateNewQR({required bool silent}) {
    if (!silent) {
      state = state.copyWith(isGeneratingQR: true);
    }

    // Simulate generation delay
    Future.delayed(Duration(milliseconds: silent ? 50 : 600), () {
      final random = Random();
      final hex = List.generate(
        6,
        (_) => random.nextInt(16).toRadixString(16).toUpperCase(),
      ).join();
      state = state.copyWith(
        qrToken: 'MAATRIVA_MOCK_SECURE_TOKEN_$hex',
        isGeneratingQR: false,
      );
    });
  }

  void revokeSession(String sessionId) {
    final sessionToRevoke = state.activeSessions.firstWhere(
      (s) => s.id == sessionId,
    );

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
    );

    state = state.copyWith(
      activeSessions: state.activeSessions
          .where((s) => s.id != sessionId)
          .toList(),
      accessHistory: [historyEntry, ...state.accessHistory],
    );
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
    Duration duration;
    switch (durationLabel.toLowerCase()) {
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
      case '12 hours':
      case '12 hrs':
        duration = const Duration(hours: 12);
        break;
      case '24 hours':
      case '24 hrs':
        duration = const Duration(hours: 24);
        break;
      default:
        duration = const Duration(hours: 2);
    }

    final expiresAt = DateTime.now().add(duration);
    final newSession = ActiveSession(
      id: 's_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      relationship: relationship,
      imageUrl: imageUrl.isNotEmpty
          ? imageUrl
          : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
      expiresAt: expiresAt,
      status: duration.inMinutes <= 15
          ? SessionStatus.expiring
          : SessionStatus.active,
    );

    state = state.copyWith(
      activeSessions: [newSession, ...state.activeSessions],
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}

final caregiverAccessProvider =
    StateNotifierProvider<CaregiverAccessNotifier, CaregiverAccessState>((ref) {
      return CaregiverAccessNotifier();
    });
