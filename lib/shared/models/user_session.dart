import 'package:equatable/equatable.dart';

/// User profile roles in the MAATRIVA ecosystem.
enum UserRole { parent, caregiver, doctor, admin }

/// Helper to parse roles from/to JSON string.
UserRole parseRole(String roleStr) {
  final clean = roleStr.trim().toLowerCase();
  return UserRole.values.firstWhere(
    (e) => e.name.toLowerCase() == clean,
    orElse: () => UserRole.parent,
  );
}

/// Represents user credentials session details.
class UserSession extends Equatable {
  final String id;
  final String email;
  final UserRole role;

  const UserSession({
    required this.id,
    required this.email,
    required this.role,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: parseRole(json['role'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email, 'role': role.name};
  }

  UserSession copyWith({
    String? id,
    String? email,
    UserRole? role,
  }) {
    return UserSession(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }

  @override
  List<Object?> get props => [id, email, role];
}
