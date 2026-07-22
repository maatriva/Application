import 'package:equatable/equatable.dart';

/// Represents a Baby Profile.
class BabyProfile extends Equatable {
  final String id;
  final String parentId;
  final String name;
  final DateTime birthDate;
  final String gender;

  const BabyProfile({
    required this.id,
    required this.parentId,
    required this.name,
    required this.birthDate,
    required this.gender,
  });

  factory BabyProfile.fromJson(Map<String, dynamic> json) {
    return BabyProfile(
      id: json['id'] as String? ?? '',
      parentId: json['parentId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'] as String)
          : DateTime.now(),
      gender: json['gender'] as String? ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'name': name,
      'birthDate': birthDate.toIso8601String(),
      'gender': gender,
    };
  }

  @override
  List<Object?> get props => [id, parentId, name, birthDate, gender];
}
