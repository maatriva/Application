import 'package:equatable/equatable.dart';

/// Caregiver invitation mapping detail.
class CaregiverInvitation extends Equatable {
  final String invitationId;
  final String email;
  final String firstName;
  final String lastName;
  final String accessLevel;
  final String status;

  const CaregiverInvitation({
    required this.invitationId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.accessLevel,
    required this.status,
  });

  factory CaregiverInvitation.fromJson(Map<String, dynamic> json) {
    return CaregiverInvitation(
      invitationId: json['invitationId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      accessLevel: json['accessLevel'] as String? ?? 'monitor',
      status: json['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invitationId': invitationId,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'accessLevel': accessLevel,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [
    invitationId,
    email,
    firstName,
    lastName,
    accessLevel,
    status,
  ];
}
