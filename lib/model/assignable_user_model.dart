// ============================================================
// Interface chung cho page response de dialog co the dung chung
// ============================================================
abstract class AssignablePageResult {
  List<AssignableUser> get data;
  bool get hasNext;
  int get page;
}

class AssignableUser {
  final int userId;
  final String fullName;
  final String email;
  final String phone;
  final String? departmentName;
  final int projectCount;
  final int enrolledCourseCount;
  final int learningPathCount;

  AssignableUser({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    this.departmentName,
    this.projectCount = 0,
    this.enrolledCourseCount = 0,
    this.learningPathCount = 0,
  });

  factory AssignableUser.fromJson(Map<String, dynamic> json) {
    // Backend ProjectAssignmentView: userId, userName, courses, learningPaths, totalCourses, completedCourses
    // Backend UserAssignment: userId, fullName, email, phone, departmentName, projectCount...
    // Dua vao cac truong co san de xac dinh loai response

    final isProjectAssignmentView = json.containsKey('userName') && json.containsKey('courses');

    if (isProjectAssignmentView) {
      final courses = json['courses'] as List<dynamic>?;
      final learningPaths = json['learningPaths'] as List<dynamic>?;
      final completedCourses = json['completedCourses'] ?? 0;

      return AssignableUser(
        userId: json['userId'] ?? json['id'] ?? 0,
        fullName: json['userName']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        departmentName: json['departmentName']?.toString(),
        projectCount: completedCourses is int ? completedCourses : 0,
        enrolledCourseCount: courses?.length ?? json['totalCourses'] ?? 0,
        learningPathCount: learningPaths?.length ?? 0,
      );
    }

    return AssignableUser(
      userId: json['userId'] ?? json['id'] ?? 0,
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      departmentName: json['departmentName']?.toString(),
      projectCount: json['projectCount'] ?? 0,
      enrolledCourseCount: json['enrolledCourseCount'] ?? 0,
      learningPathCount: json['learningPathCount'] ?? 0,
    );
  }

  String get displayName => fullName.isNotEmpty ? fullName : email;

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}

class AssignableUserPageResponse extends AssignablePageResult {
  final List<AssignableUser> data;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool last;

  AssignableUserPageResponse({
    required this.data,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.last,
  });

  @override
  bool get hasNext => !last;

  factory AssignableUserPageResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawList =
        (json['data'] ?? json['content']) as List<dynamic>? ?? [];

    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return AssignableUserPageResponse(
      data: rawList
          .map((e) => AssignableUser.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: parseInt(json['page']),
      size: parseInt(json['size']),
      totalElements: parseInt(json['totalElements']),
      totalPages: parseInt(json['totalPages']),
      last: json['last'] ?? true,
    );
  }
}
