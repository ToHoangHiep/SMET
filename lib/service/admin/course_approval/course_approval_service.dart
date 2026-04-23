import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/service/common/base_url.dart';

class CourseApprovalService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Map<String, String> _headers(String token) => {
    "Content-Type": "application/json",
    "Authorization": "Bearer $token",
  };

  /// Get courses for admin review — GET /api/lms/courses/admin?status=PENDING&page=0&size=10
  static Future<PageResponse<CourseResponse>> getPendingCourses({
    int page = 0,
    int size = 10,
    String? status,
    String? q,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception("No auth token");

    final params = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (q != null && q.isNotEmpty) params['q'] = q;

    final uri = Uri.parse("$baseUrl/lms/courses/admin").replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers(token));

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      return PageResponse.fromJson(decoded, CourseResponse.fromJson);
    }
    throw Exception("Failed to load pending courses: ${res.statusCode}");
  }

  /// Get course detail — GET /api/lms/courses/{id}
  static Future<CourseDetailResponse> getCourseDetail(String courseId) async {
    final token = await _getToken();
    if (token == null) throw Exception("No auth token");

    final res = await http.get(
      Uri.parse("$baseUrl/lms/courses/$courseId"),
      headers: _headers(token),
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      if (res.body.isEmpty) throw Exception("Empty response from server");
      try {
        final decoded = jsonDecode(res.body);
        if (decoded == null) throw Exception("Empty response from server");
        return CourseDetailResponse.fromJson(decoded as Map<String, dynamic>);
      } on FormatException catch (e) {
        throw Exception("Invalid JSON from server: $e");
      } catch (e) {
        if (e is! Exception) throw Exception("Parse error: $e");
        rethrow;
      }
    }
    throw Exception("Failed to load course detail: HTTP ${res.statusCode}");
  }

  /// Approve a course — PUT /api/lms/courses/{id}/approve
  static Future<CourseResponse> approveCourse(String courseId) async {
    final token = await _getToken();
    if (token == null) throw Exception("No auth token");

    final res = await http.put(
      Uri.parse("$baseUrl/lms/courses/$courseId/approve"),
      headers: _headers(token),
    );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      return CourseResponse.fromJson(decoded);
    }
    throw Exception("Failed to approve course: ${res.statusCode} — ${res.body}");
  }

  /// Get quizzes for a course by checking each module — GET /api/lms/quizzes/module/{moduleId}
  static Future<List<CourseQuizResponse>> getCourseQuizzes(String courseId) async {
    final token = await _getToken();
    if (token == null) throw Exception("No auth token");

    // First get course detail to know which modules exist
    final courseRes = await http.get(
      Uri.parse("$baseUrl/lms/courses/$courseId"),
      headers: _headers(token),
    ).timeout(const Duration(seconds: 15));

    if (courseRes.statusCode != 200) {
      return [];
    }

    final decoded = jsonDecode(courseRes.body);
    if (decoded == null || decoded is! Map<String, dynamic>) return [];

    final modules = decoded['modules'] as List?;
    if (modules == null || modules.isEmpty) return [];

    final quizzes = <CourseQuizResponse>[];

    for (final module in modules) {
      final moduleId = module['id'];
      if (moduleId == null) continue;

      try {
        final quizRes = await http.get(
          Uri.parse("$baseUrl/lms/quizzes/module/$moduleId"),
          headers: _headers(token),
        ).timeout(const Duration(seconds: 10));

        if (quizRes.statusCode == 200 && quizRes.body.isNotEmpty) {
          final quizDecoded = jsonDecode(quizRes.body);
          if (quizDecoded != null && quizDecoded is Map<String, dynamic>) {
            quizzes.add(CourseQuizResponse.fromJson(quizDecoded));
          }
        }
      } catch (_) {
        // Module may not have a quiz — skip silently
      }
    }

    return quizzes;
  }
}
