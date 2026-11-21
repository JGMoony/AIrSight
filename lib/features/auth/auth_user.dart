class AuthUser {
  final String name;
  final String email;
  final String password;
  final String role;

  const AuthUser({
    required this.name,
    required this.email,
    required this.password,
    this.role = 'student',
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    };
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      role: json['role'] ?? 'student',
    );
  }
}