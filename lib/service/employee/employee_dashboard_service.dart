import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smet/model/employee_dashboard_models.dart';
import 'package:smet/service/common/base_url.dart';

/// ============================================================
/// EMPLOYEE DASHBOARD SERVICE
/// Backend endpoints:
///   GET /api/user/dashboard/overview
///   GET /api/lms/enrollments/my-courses
///   GET /api/lms/live-sessions/course/{courseId} (goi tung course sau khi lay my-courses)
///   GET /api/leaderboard
/// ============================================================
class EmployeeDashboardService {
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
    log("[EmployeeDashboardService] $msg");
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // ============================================
  // GET OVERVIEW
  // GET /api/user/dashboard/overview
  // ============================================
  Future<UserDashboardOverview> getOverview() async {
    try {
      final token = await _getToken();
      if (token == null) {
        _log("No auth token");
        return UserDashboardOverview.empty();
      }

      final res = await http.get(
        Uri.parse("$baseUrl/user/dashboard/overview"),
        headers: _headers(token),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data == null || data == '') {
          return UserDashboardOverview.empty();
        }
        return UserDashboardOverview.fromJson(data as Map<String, dynamic>);
      }
      _log("getOverview failed: HTTP ${res.statusCode}");
      return UserDashboardOverview.empty();
    } catch (e) {
      _log("getOverview error: $e");
      return UserDashboardOverview.empty();
    }
  }

  // ============================================
  // GET MY COURSES
  // GET /api/lms/enrollments/my-courses
  // ============================================
  Future<List<MyCourse>> getMyCourses({int page = 0, int size = 20}) async {
    try {
      final token = await _getToken();
      if (token == null) {
        _log("No auth token");
        return [];
      }

      final res = await http.get(
        Uri.parse("$baseUrl/lms/enrollments/my-courses?page=$page&size=$size"),
        headers: _headers(token),
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List<dynamic> content;

        if (decoded is List) {
          content = decoded;
        } else if (decoded is Map) {
          content = decoded['content'] as List<dynamic>? ??
                    decoded['data'] as List<dynamic>? ??
                    [];
        } else {
          return [];
        }

        return content
            .map((c) => MyCourse.fromJson(c as Map<String, dynamic>))
            .toList();
      }
      _log("getMyCourses failed: HTTP ${res.statusCode}");
      return [];
    } catch (e) {
      _log("getMyCourses error: $e");
      return [];
    }
  }

  // ============================================
  // GET LIVE SESSIONS
  // Logic: lay danh sach course da enroll,
  // roi goi /live-sessions/course/{courseId} cho tung course
  // ============================================
  Future<List<LiveSession>> getLiveSessions() async {
    try {
      final token = await _getToken();
      if (token == null) {
        _log("No auth token");
        return [];
      }

      // Lay danh sach course da enroll
      final coursesRes = await http.get(
        Uri.parse("$baseUrl/lms/enrollments/my-courses?page=0&size=50"),
        headers: _headers(token),
      );

      if (coursesRes.statusCode != 200) {
        _log("getLiveSessions: failed to fetch enrollments, HTTP ${coursesRes.statusCode}");
        return [];
      }

      final decoded = jsonDecode(coursesRes.body);
      List<dynamic> courseList;

      if (decoded is List) {
        courseList = decoded;
      } else if (decoded is Map) {
        courseList = decoded['content'] as List<dynamic>? ??
                    decoded['data'] as List<dynamic>? ??
                    [];
      } else {
        return [];
      }

      if (courseList.isEmpty) return [];

      // Goi live-sessions/course/{courseId} cho tung course
      final sessions = <LiveSession>[];
      final futures = courseList.map<Map<String, dynamic>>((c) {
        final courseId = _parseInt(c['id']);
        return {'id': courseId, 'title': c['title'] ?? 'Khóa học'};
      }).where((c) => c['id'] > 0).map((courseInfo) async {
        try {
          final sessionRes = await http.get(
            Uri.parse("$baseUrl/lms/live-sessions/course/${courseInfo['id']}"),
            headers: _headers(token),
          );
          if (sessionRes.statusCode == 200) {
            final List<dynamic> sessionData = jsonDecode(sessionRes.body);
            return sessionData
                .map((s) => LiveSession.fromJson(s as Map<String, dynamic>))
                .toList();
          }
        } catch (_) {}
        return <LiveSession>[];
      });

      final results = await Future.wait(futures);
      for (final list in results) {
        sessions.addAll(list);
      }

      // Sort theo startTime
      sessions.sort((a, b) => a.startTime.compareTo(b.startTime));

      _log("getLiveSessions: fetched ${sessions.length} sessions from ${courseList.length} courses");
      return sessions;
    } catch (e) {
      _log("getLiveSessions error: $e");
      return [];
    }
  }

  // ============================================
  // GET LEADERBOARD
  // GET /api/leaderboard
  // ============================================
  Future<List<LeaderboardItem>> getLeaderboard({int? departmentId}) async {
    try {
      final token = await _getToken();
      if (token == null) {
        _log("No auth token");
        return [];
      }

      var url = "$baseUrl/leaderboard";
      if (departmentId != null) {
        url += "?departmentId=$departmentId";
      }

      final res = await http.get(
        Uri.parse(url),
        headers: _headers(token),
      );

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data
            .map((e) => LeaderboardItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      _log("getLeaderboard failed: HTTP ${res.statusCode}");
      return [];
    } catch (e) {
      _log("getLeaderboard error: $e");
      return [];
    }
  }

  // ============================================
  // LOAD ALL DATA
  // ============================================
  Future<EmployeeDashboardData> loadDashboardData() async {
    _log("Loading employee dashboard data...");

    final results = await Future.wait([
      getOverview(),
      getMyCourses(),
      getLiveSessions(),
      getLeaderboard(),
    ]);

    final overview = results[0] as UserDashboardOverview;
    final courses = results[1] as List<MyCourse>;
    final liveSessions = results[2] as List<LiveSession>;
    final leaderboard = results[3] as List<LeaderboardItem>;

    _log("Overview: course=${overview.courseTitle}");
    _log("Courses loaded: ${courses.length}");
    _log("Live sessions loaded: ${liveSessions.length}");
    _log("Leaderboard loaded: ${leaderboard.length}");

    return EmployeeDashboardData(
      overview: overview,
      courses: courses,
      liveSessions: liveSessions,
      leaderboard: leaderboard,
    );
  }
}

class EmployeeDashboardData {
  final UserDashboardOverview overview;
  final List<MyCourse> courses;
  final List<LiveSession> liveSessions;
  final List<LeaderboardItem> leaderboard;

  EmployeeDashboardData({
    required this.overview,
    required this.courses,
    required this.liveSessions,
    required this.leaderboard,
  });
}
