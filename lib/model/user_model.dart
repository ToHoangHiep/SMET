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
  final String? department;
  final DateTime? createdAt;
  final DateTime lastUpdated;
  final String? avatarUrl;

  UserModel({
    required this.id,
    this.username = '',
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone = '',
    required this.role,
    this.isActive = true,
    this.department,
    this.createdAt,
    required this.lastUpdated,
    this.avatarUrl,
  });

  String get fullName => '$firstName $lastName';

  // Hàm cập nhật dữ liệu
  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
    String? department,
    bool? isActive,
  }) {
    return UserModel(
      id: id,
      username: username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email,
      phone: phone ?? this.phone,
      role: role,
      isActive: isActive ?? this.isActive,
      department: department ?? this.department,
      createdAt: createdAt,
      lastUpdated: DateTime.now(),
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    UserRole parseRole(dynamic value) {
      final role = value?.toString().toLowerCase();
      switch (role) {
        case 'admin':
          return UserRole.admin;
        case 'project_manager':
        case 'projectmanager':
        case 'pm':
          return UserRole.projectManager;
        case 'mentor':
          return UserRole.mentor;
        default:
          return UserRole.employee;
      }
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.tryParse(value.toString());
    }

    final updatedAt = parseDate(json['lastUpdated'] ?? json['updated_at']) ?? DateTime.now();

    return UserModel(
      id: (json['id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      firstName: (json['firstName'] ?? json['first_name'] ?? '').toString(),
      lastName: (json['lastName'] ?? json['last_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      role: parseRole(json['role']),
      isActive: (json['isActive'] ?? json['is_active'] ?? true) == true,
      department: (json['department'] ?? '').toString().isNotEmpty ? (json['department'] ?? '').toString() : null,
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      lastUpdated: updatedAt,
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
