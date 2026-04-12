import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smet/model/mentor_dashboard_models.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/service/common/base_url.dart';

/// ============================================================
/// MENTOR DASHBOARD SERVICE
/// Backend endpoints:
///   GET /api/mentor/dashboard/summary
///   GET /api/mentor/dashboard/progress
///   GET /api/lms/courses?isMine=true
///   GET /api/lms/live-sessions/course/{courseId}
/// ============================================================

class MentorDashboardService {
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
    log("[MentorDashboardService] $msg");
  }

  // ============================================
  // LOAD SUMMARY
  // Backend: GET /api/mentor/dashboard/summary
  // Response: { totalCourses, totalLearners, unreadNotifications, upcomingDeadlines }
  // ============================================
  Future<MentorDashboardSummary> _loadSummary(String token) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/mentor/dashboard/summary"),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final data = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
        return MentorDashboardSummary.fromJson(data);
      }
      _log("loadSummary failed: HTTP ${res.statusCode}");
      return MentorDashboardSummary(
        totalCourses: 0,
        totalLearners: 0,
        unreadNotifications: 0,
        upcomingDeadlines: 0,
      );
    } catch (e) {
      _log("loadSummary error: $e");
      return MentorDashboardSummary(
        totalCourses: 0,
        totalLearners: 0,
        unreadNotifications: 0,
        upcomingDeadlines: 0,
      );
    }
  }

  // ============================================
  // LOAD PROGRESS
  // Backend: GET /api/mentor/dashboard/progress
  // Response: { notStarted, inProgress, completed }
  // ============================================
  Future<MentorDashboardProgress> _loadProgress(String token) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/mentor/dashboard/progress"),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final data = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
        return MentorDashboardProgress.fromJson(data);
      }
      _log("loadProgress failed: HTTP ${res.statusCode}");
      return MentorDashboardProgress(
        notStarted: 0,
        inProgress: 0,
        completed: 0,
      );
    } catch (e) {
      _log("loadProgress error: $e");
      return MentorDashboardProgress(
        notStarted: 0,
        inProgress: 0,
        completed: 0,
      );
    }
  }

  // ============================================
  // LOAD COURSES (mentor's own courses)
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
        List<dynamic> content;

        if (decoded is Map<String, dynamic>) {
          content = (decoded['data'] ?? decoded['content'] ?? []) as List<dynamic>;
        } else if (decoded is List<dynamic>) {
          content = decoded;
        } else {
          content = [];
        }

        return content
            .whereType<Map<String, dynamic>>()
            .map((e) => CourseResponse.fromJson(e))
            .toList();
      }
      _log("loadCourses failed: HTTP ${res.statusCode}");
      return [];
    } catch (e) {
      _log("loadCourses error: $e");
      return [];
    }
  }

  // ============================================
  // LOAD LIVE SESSIONS BY COURSE
  // GET /api/lms/live-sessions/course/{courseId}
  // Response: List<LiveSessionResponse>
  // ============================================
  Future<List<MentorLiveSession>> _loadSessionsByCourse(String token, int courseId) async {
    try {
      final uri = Uri.parse("$baseUrl/lms/live-sessions/course/$courseId");
      final res = await http.get(uri, headers: _headers(token));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data
            .map((s) => MentorLiveSession.fromJson(s as Map<String, dynamic>))
            .toList();
      }
      _log("_loadSessionsByCourse($courseId) failed: HTTP ${res.statusCode}");
      return [];
    } catch (e) {
      _log("_loadSessionsByCourse($courseId) error: $e");
      return [];
    }
  }

  // ============================================
  // LOAD LIVE SESSIONS (for all mentor's courses)
  // Calls /api/lms/live-sessions/course/{courseId} for each course
  // ============================================
  Future<List<MentorLiveSession>> _loadLiveSessions(String token) async {
    final courses = await _loadCourses(token);
    if (courses.isEmpty) return [];

    final futures = courses.map((c) => _loadSessionsByCourse(token, c.id.value));
    final results = await Future.wait(futures);
    final allSessions = results.expand((list) => list).toList();
    _log("Live sessions loaded: ${allSessions.length}");
    return allSessions;
  }

  // ============================================
  // MAIN: LOAD ALL DASHBOARD DATA
  // ============================================
  Future<MentorDashboardResult> loadDashboardData() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("No auth token. Please login again.");
    }

    _log("Loading dashboard data...");

    final results = await Future.wait([
      _loadSummary(token),
      _loadProgress(token),
      _loadLiveSessions(token),
    ]);

    final summary = results[0] as MentorDashboardSummary;
    final progress = results[1] as MentorDashboardProgress;
    final liveSessions = results[2] as List<MentorLiveSession>;

    _log("Summary loaded: courses=${summary.totalCourses}, learners=${summary.totalLearners}");
    _log("Progress loaded: notStarted=${progress.notStarted}, inProgress=${progress.inProgress}, completed=${progress.completed}");
    _log("Live sessions loaded: ${liveSessions.length}");

    return MentorDashboardResult(
      summary: summary,
      progress: progress,
      liveSessions: liveSessions,
    );
  }
}

class MentorDashboardResult {
  final MentorDashboardSummary summary;
  final MentorDashboardProgress progress;
  final List<MentorLiveSession> liveSessions;

  MentorDashboardResult({
    required this.summary,
    required this.progress,
    required this.liveSessions,
  });
}
