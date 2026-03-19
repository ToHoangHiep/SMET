enum UserRole { ADMIN, PROJECT_MANAGER, MENTOR, USER }

extension UserRoleDisplay on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.ADMIN:
        return 'Quản trị';
      case UserRole.PROJECT_MANAGER:
        return 'Quản lý dự án';
      case UserRole.MENTOR:
        return 'Hướng dẫn';
      case UserRole.USER:
        return 'Nhân viên';
    }
  }
}

class UserModel {
  final int id;
  final String? userName;
  final String firstName;
  final String? lastName;
  final String email;
  final String phone;
  final UserRole role;
  bool isActive;
  final bool mustChangePassword;
  bool isTwoFactorEnabled; // 2FA flag
  final String? department;
  final String? departmentCode;
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? lastUpdated;
  final int? departmentId;

  UserModel({
    required this.id,
    this.userName,
    required this.firstName,
    this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    this.isActive = true,
    this.mustChangePassword = false,
    this.isTwoFactorEnabled = false,
    this.department,
    this.departmentCode,
    this.avatarUrl,
    this.createdAt,
    this.lastUpdated,
    this.departmentId,
  });

  String get fullName => '$firstName ${lastName ?? ""}'.trim();

  /// Parse role từ backend
  static UserRole _parseRole(dynamic role) {
    final value = role?.toString().toLowerCase();

    switch (value) {
      case 'admin':
        return UserRole.ADMIN;

      case 'project_manager':
      case 'projectmanager':
      case 'pm':
        return UserRole.PROJECT_MANAGER;

      case 'mentor':
        return UserRole.MENTOR;

      case 'user':
        return UserRole.USER;

      default:
        return UserRole.USER;
    }
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return UserModel(
      id: json['id'] ?? 0,
      userName: json['userName']?.toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: json['lastName']?.toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      role: _parseRole(json['role']),
      isActive: json['isActive'] ?? json['active'] ?? true,
      mustChangePassword: json['mustChangePassword'] ?? false,
      isTwoFactorEnabled: json['twoFactorEnabled'] ?? json['isTwoFactorEnabled'] ?? false,
      // Parse department - backend trả về departmentName, departmentCode ở root level
      department: json["departmentName"]?.toString() ?? 
                  (json["department"] is Map ? json["department"]["name"]?.toString() : null),
      departmentCode: json["departmentCode"]?.toString() ?? 
                      (json["department"] is Map ? json["department"]["code"]?.toString() : null),
      avatarUrl: json['avatarUrl']?.toString(),
      createdAt: parseDate(json['createdAt']),
      lastUpdated:
          parseDate(json['lastUpdated']) ?? parseDate(json['updatedAt']),
      // Parse departmentId - ưu tiên từ root level, fallback từ object department
      departmentId: json['departmentId'] ?? 
                   (json["department"] is Map ? (json["department"]["id"] as int?) : null),
    );
  }

  /// Chuyển đổi sang JSON để gửi lên backend (tương thích với RegisterDto)
  Map<String, dynamic> toJson() {
    return {
      'userName': email,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'role': role.name,
      'avatarUrl': avatarUrl,
      'departmentId': departmentId,
      'departmentCode': departmentCode,
    };
  }

  /// Route theo role
  String get rolePath {
    switch (role) {
      case UserRole.ADMIN:
        return '/user_management';

      case UserRole.PROJECT_MANAGER:
        return '/pm/dashboard';

      case UserRole.MENTOR:
        return '/mentor/dashboard';

      case UserRole.USER:
        return '/employee/dashboard';
    }
  }
}
