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

  Future<Map<String, dynamic>> grantTemporaryAccess({
    required String babyId,
    required String caregiverEmail,
    required int durationMinutes,
    String? permission,
    Map<String, bool>? permissions,
  });

  Future<List<Map<String, dynamic>>> getActivePermissions();

  Future<void> revokeTemporaryPermission(String permissionId);

  Future<Map<String, dynamic>> updatePermissions(String permissionId, Map<String, bool> permissions);

  Future<Map<String, dynamic>> extendAccess(String permissionId, int extensionMinutes);

  Future<Map<String, dynamic>?> getCaregiverAccess();
}
