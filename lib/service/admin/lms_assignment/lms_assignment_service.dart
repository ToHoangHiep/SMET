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

  /// GET /api/lms/enrollments/my-courses?page=0&size=1000
  /// Lay danh sach tat ca enrollment toan he thong (cho admin quan ly huy gan)
  Future<List<UserEnrollmentData>> getAllEnrollments() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token not found");

      final url = "$baseUrl/lms/enrollments/my-courses?page=0&size=1000";
      _logRequest("GET ALL ENROLLMENTS", url);

      final res = await http.get(Uri.parse(url), headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> content = data['content'] ?? data as List<dynamic>;
        return content.map((e) => UserEnrollmentData.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception("Get all enrollments failed: HTTP ${res.statusCode} - ${res.body}");
    } catch (e) {
      log("GET ALL ENROLLMENTS ERROR: $e");
      rethrow;
    }
  }

  /// GET /api/lms/learning-paths?assignedToMe=true&page=0&size=1000
  /// Lay danh sach learning path assignment toan he thong (cho admin)
  Future<List<UserLearningPathData>> getAllLearningPathAssignments() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token not found");

      final url = "$baseUrl/lms/learning-paths?assignedToMe=true&page=0&size=1000";
      _logRequest("GET ALL LEARNING PATH ASSIGNMENTS", url);

      final res = await http.get(Uri.parse(url), headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> content = data['content'] ?? data as List<dynamic>;
        return content.map((e) => UserLearningPathData.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception("Get all learning path assignments failed: HTTP ${res.statusCode} - ${res.body}");
    } catch (e) {
      log("GET ALL LEARNING PATH ASSIGNMENTS ERROR: $e");
      rethrow;
    }
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
      courseTitle: json['title'] ?? json['courseTitle'] ?? '',
      userId: int.tryParse(json['userId']?.toString() ?? '') ?? 0,
      userName: json['userName'] ?? json['user']?['name'] ?? '',
      status: json['status'] ?? 'NOT_STARTED',
      progressPercent: json['progressPercent'] ?? json['progress'] ?? 0,
      enrolledAt: json['enrolledAt'] != null ? DateTime.tryParse(json['enrolledAt'].toString()) : null,
      deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline'].toString()) : null,
    );
  }
}

class UserLearningPathData {
  final int pathId;
  final String pathTitle;
  final int userId;
  final String userName;
  final int courseCount;

  UserLearningPathData({
    required this.pathId,
    required this.pathTitle,
    required this.userId,
    required this.userName,
    this.courseCount = 0,
  });

  factory UserLearningPathData.fromJson(Map<String, dynamic> json) {
    return UserLearningPathData(
      pathId: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      pathTitle: json['title'] ?? json['pathTitle'] ?? '',
      userId: int.tryParse(json['userId']?.toString() ?? '') ?? 0,
      userName: json['userName'] ?? '',
      courseCount: json['courseCount'] ?? 0,
    );
  }
}

/// Wrapper cho so nguyen (vì JS ko co Long)
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
