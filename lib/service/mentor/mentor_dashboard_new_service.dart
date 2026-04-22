import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smet/model/mentor_dashboard_new_models.dart';
import 'package:smet/model/mentor_enrollment_model.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/model/mentor_live_session_model.dart';
import 'package:smet/model/project_model.dart';
import 'package:smet/service/common/base_url.dart';

/// ============================================================
/// MENTOR DASHBOARD NEW SERVICE
/// Load data từ API dashboard theo thiết kế mới
/// ============================================================
class MentorDashboardNewService {
  // ============================================
  // TOKEN HELPERS
  // ============================================
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

  void _log(String msg) {
    log("[MentorDashboardNewService] $msg");
  }

  // ============================================
  // GET SUMMARY
  // GET /api/mentor/dashboard/summary
  // ============================================
  Future<MentorDashboardSummary> getSummary() async {
    try {
      final token = await _getToken();
      if (token == null) return MentorDashboardSummary.empty();

      final res = await http.get(
        Uri.parse("$baseUrl/mentor/dashboard/summary"),
        headers: _headers(token),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return MentorDashboardSummary.fromJson(data);
      }
      _log("getSummary failed: HTTP ${res.statusCode}");
      return MentorDashboardSummary.empty();
    } catch (e) {
      _log("getSummary error: $e");
      return MentorDashboardSummary.empty();
    }
  }

  // ============================================
  // GET PROGRESS (Pie Chart)
  // GET /api/mentor/dashboard/progress
  // ============================================
  Future<MentorProgress> getProgress() async {
    try {
      final token = await _getToken();
      if (token == null) return MentorProgress.empty();

      final res = await http.get(
        Uri.parse("$baseUrl/mentor/dashboard/progress"),
        headers: _headers(token),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return MentorProgress.fromJson(data);
      }
      _log("getProgress failed: HTTP ${res.statusCode}");
      return MentorProgress.empty();
    } catch (e) {
      _log("getProgress error: $e");
      return MentorProgress.empty();
    }
  }

  // ============================================
  // LOAD COURSES
  // GET /api/lms/courses?isMine=true
  // ============================================
  Future<List<CourseResponse>> _loadCourses(String token) async {
    try {
      final uri = Uri.parse("$baseUrl/lms/courses").replace(queryParameters: {
        'isMine': 'true',
        'page': '0',
        'size': '100',
      });
      final res = await http.get(uri, headers: _headers(token));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final data = Map<String, dynamic>.from(decoded);
        final content = data['data'] ?? data['content'] as List<dynamic>? ?? [];
        return content
            .map((e) => CourseResponse.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      _log("loadCourses error: $e");
      return [];
    }
  }

  // ============================================
  // LOAD ENROLLMENTS BY COURSE
  // GET /api/lms/enrollments/courses/{courseId}
  // ============================================
  Future<List<MentorEnrollmentInfo>> _loadEnrollmentsByCourse(
    String token,
    int courseId,
  ) async {
    try {
      final uri = Uri.parse("$baseUrl/lms/enrollments/courses/$courseId")
          .replace(queryParameters: {'page': '0', 'size': '500'});
      final res = await http.get(uri, headers: _headers(token));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final data = Map<String, dynamic>.from(decoded);
        final content = data['content'] as List<dynamic>? ?? [];
        return content
            .map((e) => MentorEnrollmentInfo.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ============================================
  // LOAD LIVE SESSIONS BY COURSE
  // GET /api/lms/live-sessions/course/{courseId}
  // ============================================
  Future<List<LiveSessionInfo>> _loadSessionsByCourse(
    String token,
    int courseId,
  ) async {
    try {
      final uri = Uri.parse("$baseUrl/lms/live-sessions/course/$courseId");
      final res = await http.get(uri, headers: _headers(token));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data
            .map((e) => LiveSessionInfo.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ============================================
  // LOAD PROJECTS
  // GET /api/projects/my-projects
  // ============================================
  Future<List<ProjectModel>> _loadProjects(String token) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/projects/my-projects"),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((e) => ProjectModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ============================================
  // LOAD ALL DASHBOARD DATA
  // ============================================
  Future<_DashboardRawData> loadDashboardData() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("No auth token. Please login again.");
    }

    _log("Loading dashboard data...");

    // Load courses first
    final courses = await _loadCourses(token);
    _log("Courses loaded: ${courses.length}");

    // Load enrollments for all courses in parallel
    final enrollmentFutures = courses.map(
      (c) => _loadEnrollmentsByCourse(token, c.id.value),
    );
    final enrollmentResults = await Future.wait(enrollmentFutures);
    final allEnrollments = enrollmentResults.expand((list) => list).toList();
    _log("Enrollments loaded: ${allEnrollments.length}");

    // Load live sessions for all courses in parallel
    final sessionFutures = courses.map(
      (c) => _loadSessionsByCourse(token, c.id.value),
    );
    final sessionResults = await Future.wait(sessionFutures);
    final allSessions = sessionResults.expand((list) => list).toList();
    _log("Sessions loaded: ${allSessions.length}");

    // Load projects
    final projects = await _loadProjects(token);
    _log("Projects loaded: ${projects.length}");

    return _DashboardRawData(
      courses: courses,
      enrollments: allEnrollments,
      sessions: allSessions,
      projects: projects,
    );
  }
}

/// Raw data container
class _DashboardRawData {
  final List<CourseResponse> courses;
  final List<MentorEnrollmentInfo> enrollments;
  final List<LiveSessionInfo> sessions;
  final List<ProjectModel> projects;

  _DashboardRawData({
    required this.courses,
    required this.enrollments,
    required this.sessions,
    required this.projects,
  });
}
