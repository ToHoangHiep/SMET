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
      lastUpdated: DateTime.now(),
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
