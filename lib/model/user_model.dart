enum UserRole { admin, projectManager, mentor, employee }

/// Tên hiển thị role (tiếng Việt) dùng trong form, dialog.
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
  final DateTime? createdAt;
  final DateTime lastUpdated;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    this.isActive = true,
    this.createdAt,
    required this.lastUpdated,
    this.avatarUrl,
  });

  String get fullName => '$firstName $lastName';

  // Hàm quan trọng để cập nhật dữ liệu
  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
  }) {
    return UserModel(
      id: this.id,
      username: this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: this.email,
      phone: phone ?? this.phone,
      role: this.role,
      isActive: this.isActive,
      createdAt: this.createdAt,
      lastUpdated: DateTime.now(),
      avatarUrl: avatarUrl ?? this.avatarUrl,
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
