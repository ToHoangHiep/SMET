enum UserRole { admin, projectManager, mentor, employee }

extension UserRoleDisplay on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Quản trị';
      case UserRole.projectManager:
        return 'Quản lý dự án';
      case UserRole.mentor:
        return 'Hướng dẫn';
      case UserRole.employee:
        return 'Nhân viên';
    }
  }
}

class UserModel {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final UserRole role;
  bool isActive;
  final bool mustChangePassword;
  final String? department;
  final DateTime? createdAt;
  final DateTime lastUpdated;

  UserModel({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    required this.mustChangePassword,
    this.isActive = true,
    this.department,
    this.createdAt,
    required this.lastUpdated,
  });

  String get fullName => '$firstName $lastName';

  /// Parse role từ backend
  static UserRole _parseRole(dynamic role) {
    final value = role?.toString().toLowerCase();

    switch (value) {
      case 'admin':
        return UserRole.admin;

      case 'projectmanager':
      case 'project_manager':
        return UserRole.projectManager;

      case 'mentor':
        return UserRole.mentor;

      default:
        return UserRole.employee;
    }
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return UserModel(
      id: (json['id'] ?? '').toString(),
      username: (json['userName'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      role: _parseRole(json['role']),
      isActive: json['isActive'] ?? true,
      mustChangePassword: json['mustChangePassword'] ?? false,
      department:
          json['department'] != null ? json['department']['name'] : null,
      createdAt: parseDate(json['createdAt']),
      lastUpdated: parseDate(json['updatedAt']) ?? DateTime.now(),
    );
  }

  /// Route theo role
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
