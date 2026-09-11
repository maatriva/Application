import 'package:flutter_test/flutter_test.dart';
import 'package:maatriva/core/errors/api_exception.dart';
import 'package:maatriva/core/config/api_config.dart';
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
      throw const ApiException(statusCode: 409, message: 'An active caregiver already has access.');
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
    if (shouldFail) {
      throw const ApiException(statusCode: 400, message: 'Invalid payload or session expired.');
    }
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
      expect(notifier.state.permissions['health_data'], isTrue);
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

      expect(notifier.state.permissions['custom_music'], isFalse);

      notifier.togglePermission('custom_music');
      notifier.generateNewQR();

      expect(notifier.state.permissions['custom_music'], isTrue);
      // Wait for async _generateNewQR call
      await Future.delayed(const Duration(milliseconds: 100));
      expect(notifier.state.qrToken, 'NEW_PERM_TOKEN');
    });

    test('Select duration updates duration label and generates new token', () async {
      mockRepo.nextToken = "NEW_DURATION_TOKEN";
      final notifier = CaregiverAccessNotifier(caregiverRepo: mockRepo);

      expect(notifier.state.selectedDurationLabel, '30 Mins');

      notifier.selectDuration('4 Hours');
      notifier.generateNewQR();

      expect(notifier.state.selectedDurationLabel, '4 Hours');
      await Future.delayed(const Duration(milliseconds: 100));
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

      await Future.delayed(const Duration(milliseconds: 200));
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
          durationText: 'Expired',
        ),
      ];

      await notifier.revokeSession('s1');

      expect(notifier.state.activeSessions.length, 0);
      expect(notifier.state.accessHistory.length, 1);
      expect(notifier.state.accessHistory.first.name, 'Uncle David');
    });

    test('HTTP 409 conflict error is mapped to clean user message and cleared on retry', () async {
      mockRepo.shouldFail = true;
      final notifier = CaregiverAccessNotifier(caregiverRepo: mockRepo);

      notifier.generateNewQR();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(notifier.state.qrToken, isEmpty);
      expect(notifier.state.qrError, contains('An active caregiver already has access'));
      expect(notifier.state.qrError, isNot(contains('ApiException')));

      // Test clearing error on retry
      mockRepo.shouldFail = false;
      mockRepo.nextToken = "RETRY_SUCCESS_TOKEN";

      final retryFuture = notifier.retryGenerateQR();
      // Should immediately clear error while generating
      expect(notifier.state.qrError, isNull);
      expect(notifier.state.isGeneratingQR, isTrue);

      await retryFuture;
      expect(notifier.state.qrToken, "RETRY_SUCCESS_TOKEN");
      expect(notifier.state.qrError, isNull);
      expect(notifier.state.isGeneratingQR, isFalse);
    });

    test('updateTemporaryPermissions returns true on success and false on failure', () async {
      final notifier = CaregiverAccessNotifier(caregiverRepo: mockRepo);

      // Successful update returns true
      mockRepo.shouldFail = false;
      final success = await notifier.updateTemporaryPermissions(
        permissionId: 'perm_1',
        permissions: {'custom_music': true},
      );
      expect(success, isTrue);

      // Failed update returns false
      mockRepo.shouldFail = true;
      final failure = await notifier.updateTemporaryPermissions(
        permissionId: 'perm_1',
        permissions: {'custom_music': false},
      );
      expect(failure, isFalse);
    });

    test('ApiConfig.sanitizeApiUrl normalizes URLs without duplicate /api or trailing slashes', () {
      expect(ApiConfig.sanitizeApiUrl('http://192.168.1.15:3000'), 'http://192.168.1.15:3000/api');
      expect(ApiConfig.sanitizeApiUrl('http://192.168.1.15:3000/'), 'http://192.168.1.15:3000/api');
      expect(ApiConfig.sanitizeApiUrl('http://192.168.1.15:3000/api'), 'http://192.168.1.15:3000/api');
      expect(ApiConfig.sanitizeApiUrl('http://192.168.1.15:3000/api/'), 'http://192.168.1.15:3000/api');
      expect(ApiConfig.sanitizeApiUrl('http://192.168.1.15:3000/api/api'), 'http://192.168.1.15:3000/api');
      expect(ApiConfig.sanitizeApiUrl('192.168.1.15:3000'), 'http://192.168.1.15:3000/api');
    });

    test('ApiConfig customBaseUrl takes precedence over environment defaults', () {
      ApiConfig.setCustomBaseUrl('http://192.168.1.200:3000');
      expect(ApiConfig.baseUrl, 'http://192.168.1.200:3000/api');
      expect(ApiConfig.hasExplicitOverride, isTrue);

      // Resetting clears custom URL
      ApiConfig.setCustomBaseUrl(null);
      expect(ApiConfig.customBaseUrl, isNull);
    });
  });
}
