// file: user_model.dart
enum UserRole { admin, projectManager, mentor, employee }

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
  });

  String get fullName => '$firstName $lastName';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    UserRole parseRole(dynamic value) {
      final role = value?.toString().toLowerCase();
      switch (role) {
        case 'admin':
          return UserRole.admin;
        case 'projectmanager':
        case 'project_manager':
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

    final updatedAt =
        parseDate(json['lastUpdated'] ?? json['updated_at']) ?? DateTime.now();

    return UserModel(
      id: (json['id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      firstName: (json['firstName'] ?? json['first_name'] ?? '').toString(),
      lastName: (json['lastName'] ?? json['last_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      role: parseRole(json['role']),
      isActive: (json['isActive'] ?? json['is_active'] ?? true) == true,
      department: (json['department'] ?? '').toString(),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      lastUpdated: updatedAt,
    );
  }
}
