class RegisterRequest {
  final String fullName;
  final String email;
  final String password;
  final String? role;

  const RegisterRequest({
    required this.fullName,
    required this.email,
    required this.password,
    this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'password': password,
      if (role != null) 'role': role,
    };
  }
}
