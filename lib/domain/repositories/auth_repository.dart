import '../../shared/models/user_session.dart';

/// Contract definition for user authentication.
abstract class AuthRepository {
  Future<UserSession> login({
    required String email,
    required String password,
  });

  Future<UserSession> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String role = 'caregiver',
  });

  Future<void> logout();

  Future<bool> isUserLoggedIn();
}
