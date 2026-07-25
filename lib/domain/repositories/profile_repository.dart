import '../../shared/models/profile.dart';

/// Contract definition for loading and updating user settings profiles.
abstract class ProfileRepository {
  Future<ProfileState> getProfile();

  Future<ProfileState> updateProfile(ProfileState profile);
}
