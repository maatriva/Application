class ProfileResponse {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String createdAt;

  const ProfileResponse({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'role': role,
      'createdAt': createdAt,
    };
  }
}
