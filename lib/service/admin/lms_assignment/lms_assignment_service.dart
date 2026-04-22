import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smet/model/assignment_result_model.dart';
import 'package:smet/service/common/base_url.dart';

class LmsAssignmentService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  Map<String, String> _headers(String token) {
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
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

  String _formatDate(DateTime date) {
    return date.toIso8601String();
  }

  /// POST /api/lms/enrollments/assign
  /// Gan course cho nhieu user
  Future<AssignmentResult> assignCourses({
    required List<int> userIds,
    required List<int> courseIds,
    Long? projectId,
    DateTime? dueDate,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token not found");

      final url = "$baseUrl/lms/enrollments/assign";
      final body = <String, dynamic>{
        'userIds': userIds,
        'courseIds': courseIds,
      };
      if (projectId != null) body['projectId'] = projectId.value;
      if (dueDate != null) body['dueDate'] = _formatDate(dueDate);

      _logRequest("ASSIGN COURSES", url, body: body);

      final res = await http.post(
        Uri.parse(url),
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

  /// POST /api/lms/learning-paths/assign
  /// Gan learning path cho nhieu user
  Future<AssignmentResult> assignLearningPaths({
    required List<int> userIds,
    required List<int> learningPathIds,
    Long? projectId,
    DateTime? dueDate,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token not found");

      final url = "$baseUrl/lms/learning-paths/assign";
      final body = <String, dynamic>{
        'userIds': userIds,
        'learningPathIds': learningPathIds,
      };
      if (projectId != null) body['projectId'] = projectId.value;
      if (dueDate != null) body['dueDate'] = _formatDate(dueDate);

      _logRequest("ASSIGN LEARNING PATHS", url, body: body);

      final res = await http.post(
        Uri.parse(url),
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

  /// DELETE /api/lms/enrollments/{courseId}/users/{userId}
  /// Huy gan course khoi user
  Future<void> unassignCourse({
    required int courseId,
    required int userId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token not found");

      final url = "$baseUrl/lms/enrollments/$courseId/users/$userId";
      _logRequest("UNASSIGN COURSE", url);

      final res = await http.delete(
        Uri.parse(url),
        headers: _headers(token),
      );
      _logResponse(res);

      if (res.statusCode != 200 && res.statusCode != 204) {
        throw Exception("Unassign course failed: HTTP ${res.statusCode} - ${res.body}");
      }
    } catch (e) {
      log("UNASSIGN COURSE ERROR: $e");
      rethrow;
    }
  }

  /// DELETE /api/lms/learning-paths/{lpId}/users/{userId}
  /// Huy gan learning path khoi user
  Future<void> unassignLearningPath({
    required int learningPathId,
    required int userId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token not found");

      final url = "$baseUrl/lms/learning-paths/$learningPathId/users/$userId";
      _logRequest("UNASSIGN LEARNING PATH", url);

      final res = await http.delete(
        Uri.parse(url),
        headers: _headers(token),
      );
      _logResponse(res);

      if (res.statusCode != 200 && res.statusCode != 204) {
        throw Exception("Unassign learning path failed: HTTP ${res.statusCode} - ${res.body}");
      }
    } catch (e) {
      log("UNASSIGN LEARNING PATH ERROR: $e");
      rethrow;
    }
  }

  /// DELETE /api/projects/{projectId}/unassign/course?courseId=X&userId=Y
  /// Huy gan course khoi user trong project
  Future<void> unassignCourseByProject({
    required int projectId,
    required int courseId,
    required int userId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token not found");

      final url = "$baseUrl/projects/$projectId/unassign/course?courseId=$courseId&userId=$userId";
      _logRequest("UNASSIGN COURSE BY PROJECT", url);

      final res = await http.delete(
        Uri.parse(url),
        headers: _headers(token),
      );
      _logResponse(res);

      if (res.statusCode != 200 && res.statusCode != 204) {
        throw Exception("Unassign course by project failed: HTTP ${res.statusCode} - ${res.body}");
      }
    } catch (e) {
      log("UNASSIGN COURSE BY PROJECT ERROR: $e");
      rethrow;
    }
  }

  /// DELETE /api/projects/{projectId}/unassign/learning-path?learningPathId=X&userId=Y
  /// Huy gan learning path khoi user trong project
  Future<void> unassignLearningPathByProject({
    required int projectId,
    required int learningPathId,
    required int userId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token not found");

      final url = "$baseUrl/projects/$projectId/unassign/learning-path?learningPathId=$learningPathId&userId=$userId";
      _logRequest("UNASSIGN LEARNING PATH BY PROJECT", url);

      final res = await http.delete(
        Uri.parse(url),
        headers: _headers(token),
      );
      _logResponse(res);

      if (res.statusCode != 200 && res.statusCode != 204) {
        throw Exception("Unassign learning path by project failed: HTTP ${res.statusCode} - ${res.body}");
      }
    } catch (e) {
      log("UNASSIGN LEARNING PATH BY PROJECT ERROR: $e");
      rethrow;
    }
  }

  /// GET /api/admin/enrollments
  /// Lay danh sach enrollment phan trang (cho admin quan ly huy gan)
  /// Query params: page, size, userId, courseId, status, minProgress, maxProgress, q
  Future<PageResultEnrollment> getEnrollments({
    int page = 0,
    int size = 20,
    int? userId,
    int? courseId,
    String? status,
    int? minProgress,
    int? maxProgress,
    String? q,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token not found");

      final params = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };
      if (userId != null) params['userId'] = userId.toString();
      if (courseId != null) params['courseId'] = courseId.toString();
      if (status != null && status.isNotEmpty) params['status'] = status;
      if (minProgress != null) params['minProgress'] = minProgress.toString();
      if (maxProgress != null) params['maxProgress'] = maxProgress.toString();
      if (q != null && q.isNotEmpty) params['q'] = q;

      final uri = Uri.parse("$baseUrl/admin/enrollments")
          .replace(queryParameters: params);
      _logRequest("GET ENROLLMENTS", uri.toString());

      final res = await http.get(uri, headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return PageResultEnrollment.fromJson(data as Map<String, dynamic>);
      }
      throw Exception("Get enrollments failed: HTTP ${res.statusCode} - ${res.body}");
    } catch (e) {
      log("GET ENROLLMENTS ERROR: $e");
      rethrow;
    }
  }

  /// GET /api/admin/learning-path-assignments
  /// Lay danh sach learning path assignment phan trang (cho admin quan ly huy gan)
  /// Query params: page, size, userId, learningPathId, q
  Future<PageResultLearningPath> getLearningPathAssignments({
    int page = 0,
    int size = 20,
    int? userId,
    int? learningPathId,
    String? q,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token not found");

      final params = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };
      if (userId != null) params['userId'] = userId.toString();
      if (learningPathId != null) params['learningPathId'] = learningPathId.toString();
      if (q != null && q.isNotEmpty) params['q'] = q;

      final uri = Uri.parse("$baseUrl/admin/learning-path-assignments")
          .replace(queryParameters: params);
      _logRequest("GET LEARNING PATH ASSIGNMENTS", uri.toString());

      final res = await http.get(uri, headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return PageResultLearningPath.fromJson(data as Map<String, dynamic>);
      }
      throw Exception("Get learning path assignments failed: HTTP ${res.statusCode} - ${res.body}");
    } catch (e) {
      log("GET LEARNING PATH ASSIGNMENTS ERROR: $e");
      rethrow;
    }
  }
}

/// ============================================================
/// PageResult - Wrapper cho phan trang (Backend tra PageResponse<T>)
/// ============================================================
class PageResultEnrollment {
  final List<UserEnrollmentData> data;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool last;

  PageResultEnrollment({
    required this.data,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.last,
  });

  factory PageResultEnrollment.fromJson(Map<String, dynamic> json) {
    final List<dynamic> dataList = json['data'] ?? [];
    return PageResultEnrollment(
      data: dataList.map((e) => UserEnrollmentData.fromJson(e as Map<String, dynamic>)).toList(),
      page: json['page'] ?? 0,
      size: json['size'] ?? 20,
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      last: json['last'] ?? true,
    );
  }
}

class PageResultLearningPath {
  final List<UserLearningPathData> data;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool last;

  PageResultLearningPath({
    required this.data,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.last,
  });

  factory PageResultLearningPath.fromJson(Map<String, dynamic> json) {
    final List<dynamic> dataList = json['data'] ?? [];
    return PageResultLearningPath(
      data: dataList.map((e) => UserLearningPathData.fromJson(e as Map<String, dynamic>)).toList(),
      page: json['page'] ?? 0,
      size: json['size'] ?? 20,
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      last: json['last'] ?? true,
    );
  }
}

/// ============================================================
/// Data models for assignment management
/// ============================================================
class UserEnrollmentData {
  final int courseId;
  final String courseTitle;
  final int userId;
  final String userName;
  final String status;
  final int progressPercent;
  final DateTime? enrolledAt;
  final DateTime? deadline;

  UserEnrollmentData({
    required this.courseId,
    required this.courseTitle,
    required this.userId,
    required this.userName,
    required this.status,
    this.progressPercent = 0,
    this.enrolledAt,
    this.deadline,
  });

  factory UserEnrollmentData.fromJson(Map<String, dynamic> json) {
    return UserEnrollmentData(
      courseId: int.tryParse(json['courseId']?.toString() ?? '') ?? 0,
      courseTitle: json['courseTitle'] ?? '',
      userId: int.tryParse(json['userId']?.toString() ?? '') ?? 0,
      userName: json['userName'] ?? '',
      status: json['status'] ?? 'NOT_STARTED',
      progressPercent: (json['progressPercent'] ?? 0).toInt(),
      enrolledAt: json['enrolledAt'] != null ? DateTime.tryParse(json['enrolledAt'].toString()) : null,
      deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline'].toString()) : null,
    );
  }
}

class UserLearningPathData {
  final int learningPathId;
  final String learningPathTitle;
  final int userId;
  final String userName;
  final DateTime? assignedAt;
  final DateTime? dueDate;

  UserLearningPathData({
    required this.learningPathId,
    required this.learningPathTitle,
    required this.userId,
    required this.userName,
    this.assignedAt,
    this.dueDate,
  });

  factory UserLearningPathData.fromJson(Map<String, dynamic> json) {
    return UserLearningPathData(
      learningPathId: int.tryParse(json['learningPathId']?.toString() ?? '') ?? 0,
      learningPathTitle: json['learningPathTitle'] ?? '',
      userId: int.tryParse(json['userId']?.toString() ?? '') ?? 0,
      userName: json['userName'] ?? '',
      assignedAt: json['assignedAt'] != null ? DateTime.tryParse(json['assignedAt'].toString()) : null,
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate'].toString()) : null,
    );
  }
}

/// Wrapper cho so nguyen (vi JS ko co Long)
class Long {
  final int value;
  Long(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Long && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value.toString();
}
