import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smet/model/mentor_live_session_model.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/service/common/base_url.dart';

/// ============================================================
/// MENTOR LIVE SESSION SERVICE
/// Backend: LiveSessionController
///   GET    /api/lms/live-sessions/course/{courseId}
///   GET    /api/lms/live-sessions/{sessionId}
///   POST   /api/lms/live-sessions
///   PUT    /api/lms/live-sessions/{sessionId}
///   DELETE /api/lms/live-sessions/{sessionId}
///   GET    /api/lms/live-sessions/{sessionId}/join
///   GET    /api/lms/courses  (for dropdown)
/// ============================================================

class MentorLiveSessionService {
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

  void _logRequest(String title, String url, {dynamic body, Map<String, String>? headers}) {
    log("==========================================");
    log(">>> [$title] REQUEST");
    log("    URL    : $url");
    if (headers != null) {
      final safeHeaders = Map<String, String>.from(headers);
      if (safeHeaders.containsKey("Authorization")) {
        safeHeaders["Authorization"] = "Bearer ***";
      }
      log("    HEADERS: $safeHeaders");
    }
    if (body != null) {
      log("    BODY   : $body");
    }
    log("--------------------------------------------------");
  }

  void _logResponse(http.Response res) {
    log("<<< RESPONSE");
    log("    STATUS : ${res.statusCode}");
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final preview = res.body.length > 500
          ? '${res.body.substring(0, 500)}... [truncated]'
          : res.body;
      log("    BODY   : $preview");
    } else {
      log("    ERROR  : ${res.body}");
    }
    log("==========================================");
  }

  void _logStep(String step) {
    log("  [STEP] $step");
  }

  void _logResult(String label, dynamic result) {
    log("  [RESULT] $label: $result");
  }

  // ============================================
  // GET LIVE SESSIONS BY COURSE
  // Backend: GET /api/lms/live-sessions/course/{courseId}
  // ============================================
  Future<List<LiveSessionInfo>> getSessionsByCourse(Long courseId) async {
    log("[MentorLiveSessionService] getSessionsByCourse() — courseId=${courseId.value}");

    try {
      _logStep("Getting auth token...");
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }
      _logResult("Token", "obtained (${token.length} chars)");

      final url = "$baseUrl/lms/live-sessions/course/${courseId.value}";
      _logResult("URL", url);

      _logStep("Sending GET request...");
      _logRequest("GET SESSIONS BY COURSE", url, headers: _headers(token));
      final res = await http.get(Uri.parse(url), headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200) {
        _logStep("Parsing response JSON...");
        try {
          final decoded = jsonDecode(res.body);
          if (decoded == null) {
            log("  [WARN] Response body is null — returning empty list");
            return [];
          }
          final List<dynamic> data = decoded is List ? decoded : (decoded['content'] as List<dynamic>? ?? []);
          final sessions = data
              .map((e) => LiveSessionInfo.fromJson(e as Map<String, dynamic>))
              .toList();
          _logResult("Sessions loaded", "${sessions.length} sessions");
          return sessions;
        } on FormatException catch (e) {
          log("  [ERROR] JSON parse failed: $e");
          throw Exception("Server returned invalid JSON.");
        }
      }

      throw Exception("Get sessions failed: HTTP ${res.statusCode}");
    } catch (e) {
      log("[MentorLiveSessionService] getSessionsByCourse() FAILED: $e");
      rethrow;
    }
  }

  // ============================================
  // GET LIVE SESSION BY ID
  // Backend: GET /api/lms/live-sessions/{sessionId}
  // ============================================
  Future<LiveSessionInfo> getSessionById(Long sessionId) async {
    log("[MentorLiveSessionService] getSessionById() — sessionId=${sessionId.value}");

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final url = "$baseUrl/lms/live-sessions/${sessionId.value}";
      _logRequest("GET SESSION BY ID", url, headers: _headers(token));
      final res = await http.get(Uri.parse(url), headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded == null) throw Exception("Empty response from server");
        final data = Map<String, dynamic>.from(decoded);
        final result = LiveSessionInfo.fromJson(data);
        _logResult("Session loaded", "id=${result.id.value}, title=${result.title}");
        return result;
      }

      throw Exception("Get session failed: HTTP ${res.statusCode}");
    } catch (e) {
      log("[MentorLiveSessionService] getSessionById() FAILED: $e");
      rethrow;
    }
  }

  // ============================================
  // CREATE LIVE SESSION
  // Backend: POST /api/lms/live-sessions
  // Backend uses @RequestParam → send as query params (NOT JSON body)
  // ============================================
  Future<LiveSessionInfo> createSession(CreateLiveSessionRequest request) async {
    log("[MentorLiveSessionService] createSession() — title=${request.title}, courseId=${request.courseId.value}");

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final uri = Uri.parse("$baseUrl/lms/live-sessions").replace(queryParameters: {
        'courseId': request.courseId.value.toString(),
        'title': request.title,
        'startTime': request.startTime,
        'endTime': request.endTime,
      });
      final url = uri.toString();
      _logRequest("CREATE LIVE SESSION", url, headers: _headers(token));
      final res = await http.post(
        Uri.parse(url),
        headers: _headers(token),
      );
      _logResponse(res);

      if (res.statusCode == 200 || res.statusCode == 201) {
        final decoded = jsonDecode(res.body);
        if (decoded == null) throw Exception("Empty response from server");
        final data = Map<String, dynamic>.from(decoded);
        final result = LiveSessionInfo.fromJson(data);
        _logResult("Session created", "id=${result.id.value}");
        return result;
      }

      throw Exception("Create session failed: HTTP ${res.statusCode} — ${res.body}");
    } catch (e) {
      log("[MentorLiveSessionService] createSession() FAILED: $e");
      rethrow;
    }
  }

  // ============================================
  // UPDATE LIVE SESSION
  // Backend: PUT /api/lms/live-sessions/{sessionId}
  // Backend uses @RequestParam → send as query params (NOT JSON body)
  // NOTE: Only ADMIN can delete; Mentor can only create & update.
  // ============================================
  Future<LiveSessionInfo> updateSession(Long sessionId, UpdateLiveSessionRequest request) async {
    log("[MentorLiveSessionService] updateSession() — sessionId=${sessionId.value}");

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final uri = Uri.parse("$baseUrl/lms/live-sessions/${sessionId.value}").replace(queryParameters: {
        'title': request.title,
        'startTime': request.startTime,
        'endTime': request.endTime,
      });
      final url = uri.toString();
      _logRequest("UPDATE LIVE SESSION", url, headers: _headers(token));
      final res = await http.put(
        Uri.parse(url),
        headers: _headers(token),
      );
      _logResponse(res);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded == null) throw Exception("Empty response from server");
        final data = Map<String, dynamic>.from(decoded);
        final result = LiveSessionInfo.fromJson(data);
        _logResult("Session updated", "id=${result.id.value}");
        return result;
      }

      throw Exception("Update session failed: HTTP ${res.statusCode}");
    } catch (e) {
      log("[MentorLiveSessionService] updateSession() FAILED: $e");
      rethrow;
    }
  }

  // ============================================
  // DELETE LIVE SESSION
  // Backend: DELETE /api/lms/live-sessions/{sessionId}
  // ⚠️ NOTE: Backend restricts DELETE to ADMIN only (403 for MENTOR role).
  // Mentor should NOT call this directly. Only ADMIN can delete sessions.
  // ============================================
  Future<void> deleteSession(Long sessionId) async {
    log("[MentorLiveSessionService] deleteSession() — sessionId=${sessionId.value}");

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final url = "$baseUrl/lms/live-sessions/${sessionId.value}";
      _logRequest("DELETE LIVE SESSION", url, headers: _headers(token));
      final res = await http.delete(Uri.parse(url), headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200 || res.statusCode == 204) {
        _logResult("Session deleted", "id=${sessionId.value}");
        return;
      }

      // Provide helpful error message for 403
      if (res.statusCode == 403) {
        throw Exception("Bạn không có quyền xóa buổi live. Chỉ Admin mới được phép xóa.");
      }

      throw Exception("Delete session failed: HTTP ${res.statusCode}");
    } catch (e) {
      log("[MentorLiveSessionService] deleteSession() FAILED: $e");
      rethrow;
    }
  }

  // ============================================
  // JOIN LIVE SESSION
  // Backend: GET /api/lms/live-sessions/{sessionId}/join
  // NOTE: @PreAuthorize("hasRole('USER')") on backend.
  // Mentor may get 403 if they are not enrolled in the course.
  // ============================================
  Future<String> joinSession(Long sessionId) async {
    log("[MentorLiveSessionService] joinSession() — sessionId=${sessionId.value}");

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final url = "$baseUrl/lms/live-sessions/${sessionId.value}/join";
      _logRequest("JOIN LIVE SESSION", url, headers: _headers(token));
      final res = await http.get(Uri.parse(url), headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200) {
        final body = res.body.trim();
        if (body.startsWith('"') && body.endsWith('"')) {
          return jsonDecode(body) as String;
        }
        return body;
      }

      String errorMsg = 'Không thể tham gia buổi live';
      try {
        final decoded = jsonDecode(res.body);
        errorMsg = decoded['message'] ?? decoded['error'] ?? res.body;
      } catch (_) {
        errorMsg = res.body.isNotEmpty ? res.body : errorMsg;
      }

      if (res.statusCode == 403) {
        throw Exception('Bạn chưa đăng ký khóa học này. Vui lòng đăng ký trước để tham gia.');
      }
      throw Exception(errorMsg);
    } catch (e) {
      log("[MentorLiveSessionService] joinSession() FAILED: $e");
      rethrow;
    }
  }

  // ============================================
  // GET MY COURSES (for dropdown)
  // Backend: GET /api/lms/courses?page=&size=
  // ============================================
  Future<PageResponse<CourseResponse>> getMyCourses({
    int page = 0,
    int size = 50,
  }) async {
    log("[MentorLiveSessionService] getMyCourses() — page=$page, size=$size");

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final uri = Uri.parse("$baseUrl/lms/courses").replace(queryParameters: {
        'page': page.toString(),
        'size': size.toString(),
      });
      final url = uri.toString();
      _logRequest("GET MY COURSES", url, headers: _headers(token));
      final res = await http.get(Uri.parse(url), headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded == null) {
          return PageResponse(
            content: [],
            totalElements: 0,
            totalPages: 0,
            number: 0,
            size: size,
            first: true,
            last: true,
          );
        }
        final data = Map<String, dynamic>.from(decoded);
        final result = PageResponse.fromJson(data, CourseResponse.fromJson);
        _logResult("Courses loaded", "${result.content.length} / ${result.totalElements} total");
        return result;
      }

      throw Exception("Get my courses failed: HTTP ${res.statusCode}");
    } catch (e) {
      log("[MentorLiveSessionService] getMyCourses() FAILED: $e");
      rethrow;
    }
  }

  // ============================================
  // CHECK GOOGLE OAUTH STATUS
  // Backend: GET /api/users/me/google-status
  // ============================================
  Future<bool> checkGoogleStatus() async {
    log("[MentorLiveSessionService] checkGoogleStatus()");

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final url = "$baseUrl/users/me/google-status";
      _logRequest("CHECK GOOGLE STATUS", url, headers: _headers(token));
      final res = await http.get(Uri.parse(url), headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final connected = decoded['googleConnected'] == true;
        _logResult("Google status", connected ? "CONNECTED" : "NOT CONNECTED");
        return connected;
      }

      throw Exception("Check google status failed: HTTP ${res.statusCode}");
    } catch (e) {
      log("[MentorLiveSessionService] checkGoogleStatus() FAILED: $e");
      rethrow;
    }
  }

  // ============================================
  // INITIATE GOOGLE OAUTH
  // Returns the authorization URL with token as query param
  // so backend can identify the user when opened in external browser.
  // Backend: GET /api/oauth/google?token={jwt}
  // ============================================
  Future<String> getGoogleOAuthUrl() async {
    log("[MentorLiveSessionService] getGoogleOAuthUrl()");

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final url = "$baseUrl/oauth/google?token=$token";
      _logRequest("GET GOOGLE OAUTH URL", url);
      return url;
    } catch (e) {
      log("[MentorLiveSessionService] getGoogleOAuthUrl() FAILED: $e");
      rethrow;
    }
  }
}
