enum UserRole {
  employee,
  mentor,
  projectManager,
  admin,
}

class User {
  final String email;
  final String name;
  final UserRole role;
  final String? token;

  User({
    required this.email,
    required this.name,
    required this.role,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: _parseRole(json['role']),
      token: json['token'],
    );
  }

  static UserRole _parseRole(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'project_manager':
      case 'projectmanager':
        return UserRole.projectManager;
      case 'mentor':
        return UserRole.mentor;
      case 'employee':
      default:
        return UserRole.employee;
    }
  }

  String get rolePath {
    switch (role) {
      case UserRole.admin:
        return '/user_management';
      case UserRole.projectManager:
        return '/pm/dashboard';
      case UserRole.mentor:
        return '/mentor/dashboard';
      case UserRole.employee:
        return '/employee/dashboard';
    }
  }
}
