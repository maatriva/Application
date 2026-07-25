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
  });

  factory BabyProfile.fromJson(Map<String, dynamic> json) {
    return BabyProfile(
      id: json['id'] as String? ?? '',
      parentId: json['parentId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'] as String)
          : (json['dateOfBirth'] != null
              ? DateTime.parse(json['dateOfBirth'] as String)
              : DateTime.now()),
      gender: json['gender'] as String? ?? 'unknown',
      bloodGroup: json['bloodGroup'] as String?,
      birthWeight: (json['birthWeight'] as num?)?.toDouble(),
      birthHeight: (json['birthHeight'] as num?)?.toDouble(),
      photoUrl: json['photoUrl'] as String?,
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
      ];
}
