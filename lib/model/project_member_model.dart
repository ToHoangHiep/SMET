enum ProjectMemberRole {
  PROJECT_LEAD,
  PROJECT_MEMBER;

  static ProjectMemberRole fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'PROJECT_LEAD':
        return ProjectMemberRole.PROJECT_LEAD;
      case 'PROJECT_MEMBER':
        return ProjectMemberRole.PROJECT_MEMBER;
      default:
        return ProjectMemberRole.PROJECT_MEMBER;
    }
  }

  String get label {
    switch (this) {
      case ProjectMemberRole.PROJECT_LEAD:
        return 'Trưởng nhóm';
      case ProjectMemberRole.PROJECT_MEMBER:
        return 'Thành viên';
    }
  }
}

class ProjectMemberModel {
  final int id;
  final int projectId;
  final int userId;
  final ProjectMemberRole role;
  final String? userName;
  final String? userEmail;

  ProjectMemberModel({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.role,
    this.userName,
    this.userEmail,
  });

  factory ProjectMemberModel.fromJson(Map<String, dynamic> json) {
    // Xử lý nested user object từ backend
    final user = json['user'];
    return ProjectMemberModel(
      id: json['id'] ?? 0,
      projectId: json['project']?['id'] ?? json['projectId'] ?? 0,
      userId: user?['id'] ?? json['userId'] ?? 0,
      role: ProjectMemberRole.fromString(json['role']),
      userName: user?['fullName']?.toString() ?? json['userName'],
      userEmail: user?['email']?.toString() ?? json['userEmail'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'userId': userId,
      'role': role.name,
    };
  }

  ProjectMemberModel copyWith({
    int? id,
    int? projectId,
    int? userId,
    ProjectMemberRole? role,
    String? userName,
    String? userEmail,
  }) {
    return ProjectMemberModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
    );
  }
}
