import '../../shared/models/baby_profile.dart';

/// Contract definition for managing infant profiles.
abstract class BabyRepository {
  Future<BabyProfile> createBaby({
    required String name,
    required DateTime birthDate,
    required String gender,
    String? bloodGroup,
    double? birthWeight,
    double? birthHeight,
    String? photoUrl,
  });

  Future<List<BabyProfile>> getBabies();

  Future<BabyProfile> getBabyById(String id);

  Future<BabyProfile> updateBaby(
    String id, {
    String? name,
    DateTime? birthDate,
    String? gender,
    String? bloodGroup,
    double? birthWeight,
    double? birthHeight,
    String? photoUrl,
  });
}
