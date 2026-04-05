import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smet/service/common/base_url.dart';
import 'package:smet/service/common/auth_service.dart';
import 'package:smet/model/project_model.dart';
import 'package:smet/model/project_member_model.dart';
import 'package:smet/model/assignment_result_model.dart';
import 'dart:developer';

class EmployeeProjectService {
  static const String _baseEndpoint = '$baseUrl/projects';

  static Future<Map<String, String>> get _headers async {
    final token = await AuthService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  static Future<int> get _currentUserId async {
    final user = await AuthService.getCurrentUser();
    return user.id;
  }

  // ============================================================
  // GET /api/projects/my-projects
  // Lay danh sach project cua employee (LEAD + MEMBER)
  // ============================================================
  static Future<List<ProjectModel>> getMyProjects() async {
    try {
      final headers = await _headers;
      final url = Uri.parse('$_baseEndpoint/my-projects');

      final response = await http.get(url, headers: headers);

      log('GET MY PROJECTS STATUS: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => ProjectModel.fromJson(json)).toList();
      } else {
        throw Exception('Khong the tai danh sach du an');
      }
    } catch (e) {
      log('EmployeeProjectService.getMyProjects failed: $e');
      rethrow;
    }
  }

  // ============================================================
  // Xac dinh vai tro cua user trong 1 project
  // ============================================================
  static Future<ProjectMemberRole?> getRoleInProject(
    int projectId,
    int userId,
  ) async {
    try {
      final headers = await _headers;
      final url = Uri.parse('$_baseEndpoint/$projectId/members');

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> memberIds = jsonDecode(response.body);

        if (memberIds.contains(userId)) {
          return await _findProjectRole(projectId, userId);
        }
      }
      return null;
    } catch (e) {
      log('EmployeeProjectService.getRoleInProject failed: $e');
      return null;
    }
  }

  static Future<ProjectMemberRole?> _findProjectRole(
    int projectId,
    int userId,
  ) async {
    try {
      final headers = await _headers;
      final url = Uri.parse('$_baseEndpoint/get/$projectId');

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['leaderId'] == userId) {
          return ProjectMemberRole.PROJECT_LEAD;
        }
        if (json['mentorId'] == userId) {
          return ProjectMemberRole.PROJECT_MENTOR;
        }

        final memberIds = json['memberIds'] as List<dynamic>?;
        if (memberIds != null && memberIds.contains(userId)) {
          return ProjectMemberRole.PROJECT_MEMBER;
        }
      }
      return null;
    } catch (e) {
      log('EmployeeProjectService._findProjectRole failed: $e');
      return null;
    }
  }

  // ============================================================
  // GET /api/projects/{id}/dashboard
  // Lay dashboard cua project
  // ============================================================
  static Future<ProjectDashboardData> getDashboard(int projectId) async {
    try {
      final headers = await _headers;
      final url = Uri.parse('$_baseEndpoint/$projectId/dashboard');

      final response = await http.get(url, headers: headers);

      log('GET DASHBOARD STATUS: ${response.statusCode}, projectId=$projectId');

      if (response.statusCode == 200) {
        return ProjectDashboardData.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Khong the tai dashboard');
      }
    } catch (e) {
      log('EmployeeProjectService.getDashboard failed: $e');
      rethrow;
    }
  }

  // ============================================================
  // GET /api/projects/{id}/assignments
  // Lay danh sach bai tap duoc assign
  // ============================================================
  static Future<List<ProjectAssignmentData>> getAssignments(int projectId) async {
    try {
      final headers = await _headers;
      final url = Uri.parse('$_baseEndpoint/$projectId/assignments');

      final response = await http.get(url, headers: headers);

      log('GET ASSIGNMENTS STATUS: ${response.statusCode}, projectId=$projectId');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => ProjectAssignmentData.fromJson(json)).toList();
      } else {
        throw Exception('Khong the tai danh sach bai tap');
      }
    } catch (e) {
      log('EmployeeProjectService.getAssignments failed: $e');
      rethrow;
    }
  }

  // ============================================================
  // GET /api/projects/{id}/review-state
  // Lay trang thai review cua project
  // ============================================================
  static Future<ProjectReviewStateData> getReviewState(int projectId) async {
    try {
      final headers = await _headers;
      final url = Uri.parse('$_baseEndpoint/$projectId/review-state');

      final response = await http.get(url, headers: headers);

      log('GET REVIEW STATE STATUS: ${response.statusCode}, projectId=$projectId');

      if (response.statusCode == 200) {
        return ProjectReviewStateData.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Khong the tai trang thai review');
      }
    } catch (e) {
      log('EmployeeProjectService.getReviewState failed: $e');
      rethrow;
    }
  }

  // ============================================================
  // POST /api/projects/{id}/submit
  // Chi LEAD moi duoc goi
  // ============================================================
  static Future<void> submitProject(int projectId, String link) async {
    try {
      final headers = await _headers;
      final url = Uri.parse('$_baseEndpoint/$projectId/submit?link=$link');

      final response = await http.post(url, headers: headers);

      log('SUBMIT PROJECT STATUS: ${response.statusCode}, projectId=$projectId');

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Khong the nop du an');
      }
    } catch (e) {
      log('EmployeeProjectService.submitProject failed: $e');
      rethrow;
    }
  }

  // ============================================================
  // GET /api/projects/{id}/members/progress
  // Lay tien do tung thanh vien (chi LEAD xem duoc)
  // ============================================================
  static Future<List<MemberProgressData>> getMembersProgress(
    int projectId, {
    int page = 0,
    int size = 10,
  }) async {
    try {
      final headers = await _headers;
      final url = Uri.parse(
        '$_baseEndpoint/$projectId/members/progress?page=$page&size=$size',
      );

      final response = await http.get(url, headers: headers);

      log('GET MEMBERS PROGRESS STATUS: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final content = json['content'] as List<dynamic>?;
        if (content != null) {
          return content.map((json) => MemberProgressData.fromJson(json)).toList();
        }
        return [];
      } else {
        throw Exception('Khong the tai tien do thanh vien');
      }
    } catch (e) {
      log('EmployeeProjectService.getMembersProgress failed: $e');
      rethrow;
    }
  }

  // ============================================================
  // Lay danh sach thanh vien cua project
  // GET /api/projects/{id}/members
  // ============================================================
  static Future<List<int>> getMemberIds(int projectId) async {
    try {
      final headers = await _headers;
      final url = Uri.parse('$_baseEndpoint/$projectId/members');

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> ids = jsonDecode(response.body);
        return ids.cast<int>();
      }
      return [];
    } catch (e) {
      log('EmployeeProjectService.getMemberIds failed: $e');
      return [];
    }
  }

  // ============================================================
  // GET /api/projects/{id}/assignable-users
  // Lay danh sach thanh vien co the gan trong project
  // ============================================================
  static Future<List<ProjectMemberInfo>> getAssignableUsers(int projectId) async {
    try {
      final headers = await _headers;
      final url = Uri.parse('$_baseEndpoint/$projectId/assignable-users');

      final response = await http.get(url, headers: headers);

      log('GET ASSIGNABLE USERS STATUS: ${response.statusCode}, projectId=$projectId');

      if (response.statusCode == 200) {
        final dynamic jsonData = jsonDecode(response.body);
        if (jsonData is List) {
          return jsonData
              .map((json) => ProjectMemberInfo.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        return [];
      }
      return [];
    } catch (e) {
      log('EmployeeProjectService.getAssignableUsers failed: $e');
      return [];
    }
  }

  // ============================================================
  // POST /api/projects/{id}/assign/courses
  // Gan khóa học cho thành viên trong project
  // ============================================================
  static Future<AssignmentResult> assignCourses({
    required int projectId,
    required List<int> userIds,
    required List<int> courseIds,
  }) async {
    try {
      final headers = await _headers;
      final url = Uri.parse('$_baseEndpoint/$projectId/assign/courses');
      final body = {
        'userIds': userIds,
        'courseIds': courseIds,
      };

      log('ASSIGN COURSES REQUEST: projectId=$projectId, userIds=$userIds, courseIds=$courseIds');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      log('ASSIGN COURSES STATUS: ${response.statusCode}, body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AssignmentResult.fromJson(data as Map<String, dynamic>);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? error['error'] ?? 'Gán khóa học thất bại');
      }
    } catch (e) {
      log('EmployeeProjectService.assignCourses failed: $e');
      rethrow;
    }
  }

  // ============================================================
  // POST /api/projects/{id}/assign/learning-paths
  // Gan Learning Path cho thành viên trong project
  // ============================================================
  static Future<AssignmentResult> assignLearningPaths({
    required int projectId,
    required List<int> userIds,
    required List<int> learningPathIds,
  }) async {
    try {
      final headers = await _headers;
      final url = Uri.parse('$_baseEndpoint/$projectId/assign/learning-paths');
      final body = {
        'userIds': userIds,
        'learningPathIds': learningPathIds,
      };

      log('ASSIGN LEARNING PATHS REQUEST: projectId=$projectId, userIds=$userIds, lpIds=$learningPathIds');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      log('ASSIGN LEARNING PATHS STATUS: ${response.statusCode}, body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AssignmentResult.fromJson(data as Map<String, dynamic>);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? error['error'] ?? 'Gán Learning Path thất bại');
      }
    } catch (e) {
      log('EmployeeProjectService.assignLearningPaths failed: $e');
      rethrow;
    }
  }

  // ============================================================
  // DELETE /api/projects/{id}/unassign/course
  // Huy gan khóa học khoi thành viên trong project
  // ============================================================
  static Future<void> unassignCourse({
    required int projectId,
    required int courseId,
    required int userId,
  }) async {
    try {
      final headers = await _headers;
      final url = Uri.parse(
        '$_baseEndpoint/$projectId/unassign/course?courseId=$courseId&userId=$userId',
      );

      log('UNASSIGN COURSE REQUEST: projectId=$projectId, courseId=$courseId, userId=$userId');

      final response = await http.delete(url, headers: headers);

      log('UNASSIGN COURSE STATUS: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? error['error'] ?? 'Hủy gán khóa học thất bại');
      }
    } catch (e) {
      log('EmployeeProjectService.unassignCourse failed: $e');
      rethrow;
    }
  }

  // ============================================================
  // DELETE /api/projects/{id}/unassign/learning-path
  // Huy gan Learning Path khoi thành viên trong project
  // ============================================================
  static Future<void> unassignLearningPath({
    required int projectId,
    required int learningPathId,
    required int userId,
  }) async {
    try {
      final headers = await _headers;
      final url = Uri.parse(
        '$_baseEndpoint/$projectId/unassign/learning-path?learningPathId=$learningPathId&userId=$userId',
      );

      log('UNASSIGN LEARNING PATH REQUEST: projectId=$projectId, lpId=$learningPathId, userId=$userId');

      final response = await http.delete(url, headers: headers);

      log('UNASSIGN LEARNING PATH STATUS: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? error['error'] ?? 'Hủy gán Learning Path thất bại');
      }
    } catch (e) {
      log('EmployeeProjectService.unassignLearningPath failed: $e');
      rethrow;
    }
  }
}

// ============================================================
// DTO: Project Dashboard
// ============================================================
class ProjectDashboardData {
  final int projectId;
  final String projectTitle;
  final String status;
  final ProjectSummaryData? summary;
  final List<MemberProgressData> members;
  final int page;
  final int size;
  final int totalElements;
  final ProjectReviewStateData? reviewState;

  ProjectDashboardData({
    required this.projectId,
    required this.projectTitle,
    required this.status,
    this.summary,
    this.members = const [],
    this.page = 0,
    this.size = 10,
    this.totalElements = 0,
    this.reviewState,
  });

  factory ProjectDashboardData.fromJson(Map<String, dynamic> json) {
    return ProjectDashboardData(
      projectId: json['projectId'] ?? 0,
      projectTitle: json['projectTitle'] ?? '',
      status: json['status'] ?? '',
      summary: json['summary'] != null
          ? ProjectSummaryData.fromJson(json['summary'])
          : null,
      members: (json['members'] as List<dynamic>?)
              ?.map((m) => MemberProgressData.fromJson(m))
              .toList() ??
          [],
      page: json['page'] ?? 0,
      size: json['size'] ?? 10,
      totalElements: json['totalElements'] ?? 0,
      reviewState: json['reviewState'] != null
          ? ProjectReviewStateData.fromJson(json['reviewState'])
          : null,
    );
  }
}

class ProjectSummaryData {
  final int totalMembers;
  final int completedMembers;
  final int inProgressMembers;
  final int notStartedMembers;
  final double avgProgress;

  ProjectSummaryData({
    required this.totalMembers,
    required this.completedMembers,
    required this.inProgressMembers,
    required this.notStartedMembers,
    required this.avgProgress,
  });

  factory ProjectSummaryData.fromJson(Map<String, dynamic> json) {
    return ProjectSummaryData(
      totalMembers: json['totalMembers'] ?? 0,
      completedMembers: json['completedMembers'] ?? 0,
      inProgressMembers: json['inProgressMembers'] ?? 0,
      notStartedMembers: json['notStartedMembers'] ?? 0,
      avgProgress: (json['avgProgress'] ?? 0).toDouble(),
    );
  }
}

class MemberProgressData {
  final int userId;
  final String fullName;
  final int totalCourses;
  final int completedCourses;
  final int progressPercent;
  final String status;

  MemberProgressData({
    required this.userId,
    required this.fullName,
    required this.totalCourses,
    required this.completedCourses,
    required this.progressPercent,
    required this.status,
  });

  factory MemberProgressData.fromJson(Map<String, dynamic> json) {
    return MemberProgressData(
      userId: json['userId'] ?? 0,
      fullName: json['fullName'] ?? '',
      totalCourses: json['totalCourses'] ?? 0,
      completedCourses: json['completedCourses'] ?? 0,
      progressPercent: json['progressPercent'] ?? 0,
      status: json['status'] ?? 'NOT_STARTED',
    );
  }
}

// ============================================================
// DTO: Review State
// ============================================================
class ProjectReviewStateData {
  final bool submitted;
  final bool hasMentor;
  final bool mentorApproved;
  final bool hasPM;
  final bool pmApproved;
  final String currentStage;

  ProjectReviewStateData({
    required this.submitted,
    required this.hasMentor,
    required this.mentorApproved,
    required this.hasPM,
    required this.pmApproved,
    required this.currentStage,
  });

  factory ProjectReviewStateData.fromJson(Map<String, dynamic> json) {
    return ProjectReviewStateData(
      submitted: json['submitted'] ?? false,
      hasMentor: json['hasMentor'] ?? false,
      mentorApproved: json['mentorApproved'] ?? false,
      hasPM: json['hasPM'] ?? false,
      pmApproved: json['pmApproved'] ?? false,
      currentStage: json['currentStage'] ?? 'NOT_SUBMITTED',
    );
  }

  String get stageLabel {
    switch (currentStage) {
      case 'NOT_SUBMITTED':
        return 'Chua nop';
      case 'WAITING_MENTOR':
        return 'Cho mentor duyet';
      case 'WAITING_PM':
        return 'Cho PM duyet';
      case 'COMPLETED':
        return 'Da hoan thanh';
      default:
        return currentStage;
    }
  }
}

// ============================================================
// DTO: Assignment View
// ============================================================
class ProjectAssignmentData {
  final int userId;
  final String userName;
  final List<CourseItemData> courses;
  final List<LearningPathItemData> learningPaths;
  final int totalCourses;
  final int completedCourses;

  ProjectAssignmentData({
    required this.userId,
    required this.userName,
    this.courses = const [],
    this.learningPaths = const [],
    this.totalCourses = 0,
    this.completedCourses = 0,
  });

  factory ProjectAssignmentData.fromJson(Map<String, dynamic> json) {
    return ProjectAssignmentData(
      userId: json['userId'] ?? 0,
      userName: json['userName'] ?? '',
      courses: (json['courses'] as List<dynamic>?)
              ?.map((c) => CourseItemData.fromJson(c))
              .toList() ??
          [],
      learningPaths: (json['learningPaths'] as List<dynamic>?)
              ?.map((l) => LearningPathItemData.fromJson(l))
              .toList() ??
          [],
      totalCourses: json['totalCourses'] ?? 0,
      completedCourses: json['completedCourses'] ?? 0,
    );
  }
}

class CourseItemData {
  final int courseId;
  final String title;
  final String status;
  final int progress;

  CourseItemData({
    required this.courseId,
    required this.title,
    required this.status,
    this.progress = 0,
  });

  factory CourseItemData.fromJson(Map<String, dynamic> json) {
    return CourseItemData(
      courseId: json['courseId'] ?? 0,
      title: json['title'] ?? '',
      status: json['status'] ?? '',
      progress: json['progress'] ?? 0,
    );
  }
}

class LearningPathItemData {
  final int pathId;
  final String title;

  LearningPathItemData({
    required this.pathId,
    required this.title,
  });

  factory LearningPathItemData.fromJson(Map<String, dynamic> json) {
    return LearningPathItemData(
      pathId: json['pathId'] ?? 0,
      title: json['title'] ?? '',
    );
  }
}

// ============================================================
// DTO: Project Member Info (for assignable users)
// ============================================================
class ProjectMemberInfo {
  final int userId;
  final String fullName;
  final String? email;

  ProjectMemberInfo({
    required this.userId,
    required this.fullName,
    this.email,
  });

  factory ProjectMemberInfo.fromJson(Map<String, dynamic> json) {
    return ProjectMemberInfo(
      userId: json['userId'] ?? 0,
      fullName: json['fullName'] ?? json['userName'] ?? json['name'] ?? '',
      email: json['email'],
    );
  }
}