import '../../shared/models/caregiver.dart';

/// Contract definition for managing delegating cradle access to caregivers.
abstract class CaregiverRepository {
  Future<List<ActiveSession>> getActiveSessions();

  Future<List<AccessHistory>> getAccessHistory();

  Future<String> generateInviteToken(
    Map<String, bool> permissions,
    Duration duration, {
    String? email,
    String? role,
  });

  Future<void> revokeAccess(String sessionId);

  Future<void> acceptInvitation(String token);

  Future<void> rejectInvitation(String token);

  Future<List<Map<String, dynamic>>> getReceivedInvitations();
}
