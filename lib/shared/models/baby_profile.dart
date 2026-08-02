import 'package:equatable/equatable.dart';

/// Represents a Baby Profile.
class BabyProfile extends Equatable {
  final String id;
  final String parentId;
  final String name;
  final DateTime birthDate;
  final String gender;
  final String? bloodGroup;
  final double? birthWeight;
  final double? birthHeight;
  final String? photoUrl;
  final String? accessLevel;

  const BabyProfile({
    required this.id,
    required this.parentId,
    required this.name,
    required this.birthDate,
    required this.gender,
    this.bloodGroup,
    this.birthWeight,
    this.birthHeight,
    this.photoUrl,
    this.accessLevel,
  });

  factory BabyProfile.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic raw) {
      if (raw is DateTime) return raw;
      if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
      return DateTime.now();
    }

    return BabyProfile(
      id: json['id'] as String? ?? '',
      parentId: json['parentId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      birthDate: json['birthDate'] != null
          ? parseDate(json['birthDate'])
          : (json['dateOfBirth'] != null
              ? parseDate(json['dateOfBirth'])
              : DateTime.now()),
      gender: json['gender'] as String? ?? 'unknown',
      bloodGroup: json['bloodGroup'] as String?,
      birthWeight: (json['birthWeight'] as num?)?.toDouble(),
      birthHeight: (json['birthHeight'] as num?)?.toDouble(),
      photoUrl: json['photoUrl'] as String?,
      accessLevel: json['accessLevel'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'name': name,
      'birthDate': birthDate.toIso8601String(),
      'gender': gender,
      'bloodGroup': bloodGroup,
      'birthWeight': birthWeight,
      'birthHeight': birthHeight,
      'photoUrl': photoUrl,
      'accessLevel': accessLevel,
    };
  }

  BabyProfile copyWith({
    String? id,
    String? parentId,
    String? name,
    DateTime? birthDate,
    String? gender,
    String? bloodGroup,
    double? birthWeight,
    double? birthHeight,
    String? photoUrl,
    String? accessLevel,
  }) {
    return BabyProfile(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      birthWeight: birthWeight ?? this.birthWeight,
      birthHeight: birthHeight ?? this.birthHeight,
      photoUrl: photoUrl ?? this.photoUrl,
      accessLevel: accessLevel ?? this.accessLevel,
    );
  }

  @override
  List<Object?> get props => [
        id,
        parentId,
        name,
        birthDate,
        gender,
        bloodGroup,
        birthWeight,
        birthHeight,
        photoUrl,
        accessLevel,
      ];
}
