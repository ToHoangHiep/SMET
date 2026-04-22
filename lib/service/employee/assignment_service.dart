import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smet/model/assignable_user_model.dart';
import 'package:smet/service/common/base_url.dart';
import 'package:smet/service/employee/employee_project_service.dart';
import 'package:smet/model/assignment_result_model.dart';

class AssignmentService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  Map<String, String> _headers(String token) {
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
      "Accept": "application/json",
    };
  }

  void _logRequest(String title, String url, {dynamic body}) {
    log("========== $title REQUEST ==========");
    log("URL: $url");
    if (body != null) log("BODY: $body");
  }

  void _logResponse(http.Response res) {
    log("STATUS: ${res.statusCode}");
    log("RESPONSE: ${res.body}");
    log("====================================");
  }

  // ============================================================
  // GET /api/projects/{projectId}/assignable-users
  // Lay danh sach thanh vien cua project de hien thi trong dialog chon
  // Endpoint tra ve ProjectAssignmentView: userId, userName, courses, learningPaths...
  // ============================================================
  Future<AssignableUserPageResponse> getProjectAssignableUsers({
    required int projectId,
    String? keyword,
    String? role,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token not found");

      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }
      if (role != null && role.isNotEmpty) {
        queryParams['role'] = role;
      }

      final uri = Uri.parse("$baseUrl/projects/$projectId/assignable-users")
          .replace(queryParameters: queryParams);

      _logRequest("GET PROJECT ASSIGNABLE USERS", uri.toString());

      final res = await http.get(uri, headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return AssignableUserPageResponse.fromJson(data as Map<String, dynamic>);
      }

      throw Exception("Get project assignable users failed: HTTP ${res.statusCode} - ${res.body}");
    } catch (e) {
      log("GET PROJECT ASSIGNABLE USERS ERROR: $e");
      rethrow;
    }
  }

  // ============================================================
  // Lay thanh vien cua project (khong dung endpoint /assignable-users vi no tra ve NOT IN)
  // Buoc 1: GET /api/projects/{id}/members -> tra ve List<int> userIds
  // Buoc 2: Goi getAssignableUsers lay tat ca user, filter client-side chi lay userId nam trong memberIds
  // Buoc 3: Filter them theo keyword
  // ============================================================
  Future<AssignableUserPageResponse> getProjectMembers({
    required int projectId,
    String? keyword,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final memberIds = await EmployeeProjectService.getMemberIds(projectId);
      if (memberIds.isEmpty) {
        return AssignableUserPageResponse(
          data: [],
          page: page,
          size: size,
          totalElements: 0,
          totalPages: 0,
          last: true,
        );
      }
      final memberIdSet = memberIds.toSet();

      final allUsers = await getAssignableUsers(page: 0, size: 1000);
      final projectUsers = allUsers.data.where((u) => memberIdSet.contains(u.userId)).toList();

      final filtered = keyword != null && keyword.isNotEmpty
          ? projectUsers.where((u) {
              final kw = keyword.toLowerCase();
              return u.fullName.toLowerCase().contains(kw) || u.email.toLowerCase().contains(kw);
            }).toList()
          : projectUsers;

      final totalElements = filtered.length;
      final totalPages = (totalElements / size).ceil();
      final start = page * size;
      final end = (start + size).clamp(0, totalElements);
      final pageItems = start < totalElements ? filtered.sublist(start, end) : <AssignableUser>[];

      return AssignableUserPageResponse(
        data: pageItems,
        page: page,
        size: size,
        totalElements: totalElements,
        totalPages: totalPages,
        last: page >= totalPages - 1 || totalPages == 0,
      );
    } catch (e) {
      log("GET PROJECT MEMBERS ERROR: $e");
      rethrow;
    }
  }

  // ============================================================
  // GET /api/assignments/assignable
  // Admin: lay danh sach user co the gan (khong phu thuoc project)
  // ============================================================
  Future<AssignableUserPageResponse> getAssignableUsers({
    String? keyword,
    int? departmentId,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token not found");

      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }
      if (departmentId != null) {
        queryParams['departmentId'] = departmentId.toString();
      }

      final uri = Uri.parse("$baseUrl/users/assignable")
          .replace(queryParameters: queryParams);

      _logRequest("GET ASSIGNMENTS ASSIGNABLE", uri.toString());

      final res = await http.get(uri, headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return AssignableUserPageResponse.fromJson(data as Map<String, dynamic>);
      }

      throw Exception("Get assignable users failed: HTTP ${res.statusCode} - ${res.body}");
    } catch (e) {
      log("GET ASSIGNMENTS ASSIGNABLE ERROR: $e");
      rethrow;
    }
  }

  // ============================================================
  // GET /api/projects/{projectId}/assignments
  // Project Lead: lay danh sach thanh vien du an + assignments
  // Backend tra ve List<ProjectAssignmentView> (plain array)
  // ============================================================
  Future<ProjectAssignmentsResponse> getProjectAssignments(int projectId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token not found");

      final uri = Uri.parse("$baseUrl/projects/$projectId/assignments");

      _logRequest("GET PROJECT ASSIGNMENTS", uri.toString());

      final res = await http.get(uri, headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List<dynamic>;
        return ProjectAssignmentsResponse.fromJson(data);
      }

      throw Exception("Get project assignments failed: HTTP ${res.statusCode} - ${res.body}");
    } catch (e) {
      log("GET PROJECT ASSIGNMENTS ERROR: $e");
      rethrow;
    }
  }

  // ============================================================
  // POST /api/assignments
  // Gan course hoac learning path cho user
  // - Admin: projectId = null
  // - Project Lead: projectId = X
  // ============================================================
  Future<AssignmentResult> assignCourses({
    required List<int> userIds,
    required List<int> courseIds,
    int? projectId,
    DateTime? dueDate,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token not found");

      final body = <String, dynamic>{
        'userIds': userIds,
        'courseIds': courseIds,
        'type': 'COURSE',
      };
      if (projectId != null) body['projectId'] = projectId;
      if (dueDate != null) body['dueDate'] = dueDate.toIso8601String();

      _logRequest("POST ASSIGN COURSES", "$baseUrl/assignments", body: body);

      final res = await http.post(
        Uri.parse("$baseUrl/assignments"),
        headers: _headers(token),
        body: jsonEncode(body),
      );
      _logResponse(res);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return AssignmentResult.fromJson(data as Map<String, dynamic>);
      }

      throw Exception("Assign courses failed: HTTP ${res.statusCode} - ${res.body}");
    } catch (e) {
      log("ASSIGN COURSES ERROR: $e");
      rethrow;
    }
  }

  Future<AssignmentResult> assignLearningPaths({
    required List<int> userIds,
    required List<int> learningPathIds,
    int? projectId,
    DateTime? dueDate,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token not found");

      final body = <String, dynamic>{
        'userIds': userIds,
        'learningPathIds': learningPathIds,
        'type': 'LEARNING_PATH',
      };
      if (projectId != null) body['projectId'] = projectId;
      if (dueDate != null) body['dueDate'] = dueDate.toIso8601String();

      _logRequest("POST ASSIGN LEARNING PATHS", "$baseUrl/assignments", body: body);

      final res = await http.post(
        Uri.parse("$baseUrl/assignments"),
        headers: _headers(token),
        body: jsonEncode(body),
      );
      _logResponse(res);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return AssignmentResult.fromJson(data as Map<String, dynamic>);
      }

      throw Exception("Assign learning paths failed: HTTP ${res.statusCode} - ${res.body}");
    } catch (e) {
      log("ASSIGN LEARNING PATHS ERROR: $e");
      rethrow;
    }
  }

  // ============================================================
  // DELETE /api/assignments
  // Huy gan course hoac learning path
  // ============================================================
  Future<void> unassignCourse({
    required int userId,
    required int courseId,
    int? projectId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token not found");

      final params = <String, String>{
        'userId': userId.toString(),
        'courseId': courseId.toString(),
        'type': 'COURSE',
      };
      if (projectId != null) params['projectId'] = projectId.toString();

      final uri = Uri.parse("$baseUrl/assignments")
          .replace(queryParameters: params);

      _logRequest("DELETE UNASSIGN COURSE", uri.toString());

      final res = await http.delete(uri, headers: _headers(token));
      _logResponse(res);

      if (res.statusCode != 200 && res.statusCode != 204) {
        throw Exception("Unassign course failed: HTTP ${res.statusCode} - ${res.body}");
      }
    } catch (e) {
      log("UNASSIGN COURSE ERROR: $e");
      rethrow;
    }
  }

  Future<void> unassignLearningPath({
    required int userId,
    required int learningPathId,
    int? projectId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token not found");

      final params = <String, String>{
        'userId': userId.toString(),
        'learningPathId': learningPathId.toString(),
        'type': 'LEARNING_PATH',
      };
      if (projectId != null) params['projectId'] = projectId.toString();

      final uri = Uri.parse("$baseUrl/assignments")
          .replace(queryParameters: params);

      _logRequest("DELETE UNASSIGN LEARNING PATH", uri.toString());

      final res = await http.delete(uri, headers: _headers(token));
      _logResponse(res);

      if (res.statusCode != 200 && res.statusCode != 204) {
        throw Exception("Unassign learning path failed: HTTP ${res.statusCode} - ${res.body}");
      }
    } catch (e) {
      log("UNASSIGN LEARNING PATH ERROR: $e");
      rethrow;
    }
  }
}

// ============================================================
// Project Assignments Response
// GET /api/projects/{projectId}/assignments
// Backend tra ve List<ProjectAssignmentView> (plain array)
// ============================================================
class ProjectAssignmentsResponse {
  final List<ProjectMemberAssignment> data;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool last;

  ProjectAssignmentsResponse({
    required this.data,
    this.page = 0,
    this.size = 0,
    this.totalElements = 0,
    this.totalPages = 0,
    this.last = true,
  });

  factory ProjectAssignmentsResponse.fromJson(List<dynamic> json) {
    return ProjectAssignmentsResponse(
      data: json
          .map((e) => ProjectMemberAssignment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ProjectMemberAssignment {
  final int userId;
  final String userName;
  final String? role;
  final List<CourseAssignment> courses;
  final List<LearningPathAssignment> learningPaths;
  final int totalCourses;
  final int completedCourses;

  ProjectMemberAssignment({
    required this.userId,
    required this.userName,
    this.role,
    this.courses = const [],
    this.learningPaths = const [],
    this.totalCourses = 0,
    this.completedCourses = 0,
  });

  factory ProjectMemberAssignment.fromJson(Map<String, dynamic> json) {
    return ProjectMemberAssignment(
      userId: _parseInt(json['userId']),
      userName: json['userName'] ?? '',
      role: json['role']?.toString(),
      courses: (json['courses'] as List<dynamic>?)
              ?.map((e) => CourseAssignment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      learningPaths: (json['learningPaths'] as List<dynamic>?)
              ?.map((e) => LearningPathAssignment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalCourses: _parseInt(json['totalCourses']),
      completedCourses: _parseInt(json['completedCourses']),
    );
  }
}

int _parseInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

class CourseAssignment {
  final int courseId;
  final String title;
  final String status;
  final double progress;

  CourseAssignment({
    required this.courseId,
    required this.title,
    required this.status,
    this.progress = 0,
  });

  factory CourseAssignment.fromJson(Map<String, dynamic> json) {
    return CourseAssignment(
      courseId: _parseInt(json['courseId']),
      title: json['title'] ?? 'Khoa hoc',
      status: json['status'] ?? 'NOT_STARTED',
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
    );
  }
}

class LearningPathAssignment {
  final int pathId;
  final String title;

  LearningPathAssignment({
    required this.pathId,
    required this.title,
  });

  factory LearningPathAssignment.fromJson(Map<String, dynamic> json) {
    return LearningPathAssignment(
      pathId: _parseInt(json['pathId']),
      title: json['title'] ?? 'Learning Path',
    );
  }
}
