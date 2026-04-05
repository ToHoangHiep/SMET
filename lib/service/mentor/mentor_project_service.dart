import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smet/service/common/base_url.dart';
import 'package:smet/service/common/auth_service.dart';
import 'package:smet/model/project_model.dart';
import 'package:smet/model/project_member_model.dart';
import 'dart:developer';

class MentorProjectService {
  static const String _baseEndpoint = '$baseUrl/projects';

  static Future<Map<String, String>> get _headers async {
    final token = await AuthService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // ============================================================
  // GET /api/projects/my-projects
  // Lay danh sach project ma mentor dang huong dan
  // Backend tra ve tat ca project ma user la member (ke ca mentor)
  // ============================================================
  static Future<List<ProjectModel>> getMyProjects() async {
    try {
      final headers = await _headers;
      final url = Uri.parse('$_baseEndpoint/my-projects');

      final response = await http.get(url, headers: headers);

      log('GET MENTOR PROJECTS STATUS: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => ProjectModel.fromJson(json)).toList();
      } else {
        throw Exception('Khong the tai danh sach du an');
      }
    } catch (e) {
      log('MentorProjectService.getMyProjects failed: $e');
      rethrow;
    }
  }

  // ============================================================
  // GET /api/projects/get/{id}
  // Lay chi tiet 1 project de xac dinh mentor role
  // ============================================================
  static Future<ProjectModel> getProjectById(int projectId) async {
    try {
      final headers = await _headers;
      final url = Uri.parse('$_baseEndpoint/get/$projectId');

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return ProjectModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Khong the tai chi tiet du an');
      }
    } catch (e) {
      log('MentorProjectService.getProjectById failed: $e');
      rethrow;
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

      log('GET MENTOR DASHBOARD STATUS: ${response.statusCode}, projectId=$projectId');

      if (response.statusCode == 200) {
        return ProjectDashboardData.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Khong the tai dashboard');
      }
    } catch (e) {
      log('MentorProjectService.getDashboard failed: $e');
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

      log('GET MENTOR REVIEW STATE STATUS: ${response.statusCode}, projectId=$projectId');

      if (response.statusCode == 200) {
        return ProjectReviewStateData.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Khong the tai trang thai review');
      }
    } catch (e) {
      log('MentorProjectService.getReviewState failed: $e');
      rethrow;
    }
  }

  // ============================================================
  // GET /api/projects/{id}/assignments
  // Lay danh sach bai tap duoc assign trong project
  // ============================================================
  static Future<List<ProjectAssignmentData>> getAssignments(int projectId) async {
    try {
      final headers = await _headers;
      final url = Uri.parse('$_baseEndpoint/$projectId/assignments');

      final response = await http.get(url, headers: headers);

      log('GET MENTOR ASSIGNMENTS STATUS: ${response.statusCode}, projectId=$projectId');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => ProjectAssignmentData.fromJson(json)).toList();
      } else {
        throw Exception('Khong the tai danh sach bai tap');
      }
    } catch (e) {
      log('MentorProjectService.getAssignments failed: $e');
      rethrow;
    }
  }

  // ============================================================
  // POST /api/projects/{id}/approve/mentor
  // Duyet du an - chi mentor moi goi duoc
  // ============================================================
  static Future<void> approveByMentor(int projectId) async {
    try {
      final headers = await _headers;
      final url = Uri.parse('$_baseEndpoint/$projectId/approve/mentor');

      final response = await http.post(url, headers: headers);

      log('APPROVE MENTOR STATUS: ${response.statusCode}, projectId=$projectId');

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Khong the duyet du an');
      }
    } catch (e) {
      log('MentorProjectService.approveByMentor failed: $e');
      rethrow;
    }
  }

  // ============================================================
  // POST /api/projects/{id}/reject/mentor
  // Tu choi du an - chi mentor moi goi duoc
  // Backend hien tai chua co endpoint nay - can backend them
  // ============================================================
  static Future<void> rejectByMentor(int projectId, String reason) async {
    try {
      final headers = await _headers;
      final url = Uri.parse('$_baseEndpoint/$projectId/reject/mentor?reason=$reason');

      final response = await http.post(url, headers: headers);

      log('REJECT MENTOR STATUS: ${response.statusCode}, projectId=$projectId');

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Khong the tu choi du an');
      }
    } catch (e) {
      log('MentorProjectService.rejectByMentor failed: $e');
      rethrow;
    }
  }

  // ============================================================
  // GET /api/projects/{id}/members/progress
  // Lay tien do tung thanh vien
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

      log('GET MENTOR MEMBERS PROGRESS STATUS: ${response.statusCode}');

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
      log('MentorProjectService.getMembersProgress failed: $e');
      rethrow;
    }
  }
}

// ============================================================
// DTO: Project Dashboard (reused from employee service)
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