import 'package:flutter_test/flutter_test.dart';
import 'package:maatriva/core/config/app_config.dart';
import 'package:maatriva/features/caregivers/provider/caregiver_access_provider.dart';
import 'package:maatriva/domain/repositories/caregiver_repository.dart';
import 'package:maatriva/shared/models/caregiver.dart';

class MockCaregiverRepository implements CaregiverRepository {
  List<ActiveSession> sessions = [];
  List<AccessHistory> history = [];
  String nextToken = "MOCK_TOKEN_XYZ";
  bool shouldFail = false;

  @override
  Future<List<ActiveSession>> getActiveSessions() async {
    return sessions;
  }

  @override
  Future<DateTime> getServerTime() async => DateTime.now();

  @override
  Future<List<AccessHistory>> getAccessHistory() async {
    return history;
  }

  @override
  Future<String> generateInviteToken(
    Map<String, bool> permissions,
    Duration duration, {
    String? email,
    String? role,
  }) async {
    if (shouldFail) {
      throw Exception("Generation failed");
    }
    return nextToken;
  }

  @override
  Future<void> revokeAccess(String sessionId) async {
    sessions.removeWhere((s) => s.id == sessionId);
  }

  @override
  Future<void> acceptInvitation(String token) async {}

  @override
  Future<void> rejectInvitation(String token) async {}

  @override
  Future<List<Map<String, dynamic>>> getReceivedInvitations() async {
    return [];
  }

  @override
  Future<Map<String, dynamic>> grantTemporaryAccess({
    required String babyId,
    required String caregiverEmail,
    required int durationMinutes,
    String? permission,
    Map<String, bool>? permissions,
  }) async {
    return {
      'id': 'temp_123',
      'parentId': 'parent_1',
      'caregiverId': 'cg_1',
      'babyId': babyId,
      'permission': permission ?? 'LIVE_MONITOR_ONLY',
      'permissions': permissions,
      'expiresAt': DateTime.now().add(Duration(minutes: durationMinutes)).toIso8601String(),
      'revoked': false,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getActivePermissions() async {
    return [];
  }

  @override
  Future<void> revokeTemporaryPermission(String permissionId) async {}

  @override
  Future<Map<String, dynamic>> updatePermissions(String permissionId, Map<String, bool> permissions) async {
    return {'id': permissionId, 'permissions': permissions};
  }

  @override
  Future<Map<String, dynamic>> extendAccess(String permissionId, int extensionMinutes) async {
    return {
      'id': permissionId,
      'expiresAt': DateTime.now().add(Duration(minutes: extensionMinutes)).toIso8601String(),
    };
  }

  @override
  Future<Map<String, dynamic>?> getCaregiverAccess() async {
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCaregiverRepository mockRepo;

  setUp(() {
    AppConfig.isTesting = true;
    mockRepo = MockCaregiverRepository();
  });

  group('CaregiverAccessNotifier Tests', () {
    test('Initial state load values correctly', () async {
      mockRepo.sessions = [
        ActiveSession(
          id: 's1',
          name: 'Nanny Jane',
          relationship: 'Babysitter',
          imageUrl: '',
          expiresAt: DateTime.now().add(const Duration(hours: 2)),
          status: SessionStatus.active,
        ),
      ];
      mockRepo.history = [
        const AccessHistory(
          id: 'h1',
          name: 'Uncle David',
          relationship: 'Uncle',
          date: 'Yesterday',
          timeRange: '4:00 PM – 5:00 PM',
          durationText: '1 Hour',
        ),
      ];

      final notifier = CaregiverAccessNotifier(caregiverRepo: mockRepo);
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify default state
      expect(notifier.state.permissions['live_monitoring'], isTrue);
      expect(notifier.state.selectedDurationLabel, '30 Mins');
      expect(notifier.state.isGeneratingQR, isFalse);

      // Wait for async loading to finish
      await notifier.loadSessions();

      expect(notifier.state.activeSessions.length, 1);
      expect(notifier.state.activeSessions.first.name, 'Nanny Jane');
      expect(notifier.state.accessHistory.length, 1);
      expect(notifier.state.accessHistory.first.name, 'Uncle David');
    });

    test('Toggle permission updates state and triggers token generation', () async {
      mockRepo.nextToken = "NEW_PERM_TOKEN";
      final notifier = CaregiverAccessNotifier(caregiverRepo: mockRepo);

      expect(notifier.state.permissions['health_data'], isFalse);

      notifier.togglePermission('health_data');

      expect(notifier.state.permissions['health_data'], isTrue);
      // Wait for the async microtasks to finish since _generateNewQR is called
      await Future.delayed(const Duration(milliseconds: 50));
      expect(notifier.state.qrToken, 'NEW_PERM_TOKEN');
    });

    test('Select duration updates duration label and generates new token', () async {
      mockRepo.nextToken = "NEW_DURATION_TOKEN";
      final notifier = CaregiverAccessNotifier(caregiverRepo: mockRepo);

      expect(notifier.state.selectedDurationLabel, '30 Mins');

      notifier.selectDuration('4 Hours');

      expect(notifier.state.selectedDurationLabel, '4 Hours');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(notifier.state.qrToken, 'NEW_DURATION_TOKEN');
    });

    test('addCaregiverSession adds session and generates token', () async {
      mockRepo.nextToken = "NEW_CAREGIVER_TOKEN";
      final notifier = CaregiverAccessNotifier(caregiverRepo: mockRepo);

      notifier.addCaregiverSession(
        name: 'Grandma Martha',
        relationship: 'Grandmother',
        durationLabel: '4 Hours',
        imageUrl: '',
      );

      await Future.delayed(const Duration(milliseconds: 50));
      expect(notifier.state.qrToken, 'NEW_CAREGIVER_TOKEN');
    });

    test('revokeSession removes session and inserts history entry', () async {
      final session = ActiveSession(
        id: 's1',
        name: 'Uncle David',
        relationship: 'Uncle',
        imageUrl: '',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        status: SessionStatus.active,
      );

      mockRepo.sessions = [session];
      final notifier = CaregiverAccessNotifier(caregiverRepo: mockRepo);
      await notifier.loadSessions();

      expect(notifier.state.activeSessions.length, 1);

      mockRepo.sessions = [];
      mockRepo.history = [
        const AccessHistory(
          id: 'h1',
          name: 'Uncle David',
          relationship: 'Uncle',
          date: 'Today',
          timeRange: '4:00 PM – 5:00 PM',
          durationText: 'Revoked',
        ),
      ];

      await notifier.revokeSession('s1');

      expect(notifier.state.activeSessions.length, 0);
      expect(notifier.state.accessHistory.length, 1);
      expect(notifier.state.accessHistory.first.name, 'Uncle David');
      expect(notifier.state.accessHistory.first.durationText, 'Revoked');
    });
  });
}
