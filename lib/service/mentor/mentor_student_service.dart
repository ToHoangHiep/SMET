import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smet/model/mentor_enrollment_model.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/service/common/base_url.dart';

/// ============================================================
/// MENTOR STUDENT / ENROLLMENT SERVICE
/// Backend: EnrollmentController
///   GET  /api/lms/enrollments/courses/{courseId}
///         (NOTE: endpoint chưa có sẵn - cần backend tạo thêm)
///   PUT  /api/lms/enrollments/{enrollmentId}/extend-deadline?extraDays={days}
/// ============================================================

class MentorStudentService {
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
  // GET ENROLLMENTS BY COURSE
  // Backend: GET /api/lms/enrollments/courses/{courseId}
  // NOTE: Endpoint này chưa có sẵn ở backend.
  //       Cần backend tạo thêm trong EnrollmentController.
  // ============================================
  Future<MentorEnrollmentPageResponse> getEnrollmentsByCourse(
    Long courseId, {
    int page = 0,
    int size = 20,
  }) async {
    log("[MentorStudentService] getEnrollmentsByCourse() — courseId=${courseId.value}, page=$page");

    try {
      _logStep("Getting auth token...");
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }
      _logResult("Token", "obtained (${token.length} chars)");

      final params = {
        'page': page.toString(),
        'size': size.toString(),
      };
      final uri = Uri.parse("$baseUrl/lms/enrollments/courses/${courseId.value}")
          .replace(queryParameters: params);
      final url = uri.toString();
      _logResult("URL", url);

      _logStep("Sending GET request...");
      _logRequest("GET ENROLLMENTS BY COURSE", url, headers: _headers(token));
      final res = await http.get(Uri.parse(url), headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200) {
        _logStep("Parsing response JSON...");
        try {
          final decoded = jsonDecode(res.body);
          if (decoded == null) {
            return MentorEnrollmentPageResponse(
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
          final result = MentorEnrollmentPageResponse.fromJson(data);
          _logResult("Enrollments loaded", "${result.content.length} / ${result.totalElements} total");
          return result;
        } on FormatException catch (e) {
          log("  [ERROR] JSON parse failed: $e");
          throw Exception("Server returned invalid JSON.");
        }
      }

      throw Exception("Get enrollments failed: HTTP ${res.statusCode}");
    } catch (e) {
      log("[MentorStudentService] getEnrollmentsByCourse() FAILED: $e");
      rethrow;
    }
  }

  // ============================================
  // EXTEND DEADLINE
  // Backend: PUT /api/lms/enrollments/{enrollmentId}/extend-deadline?extraDays={days}
  // ============================================
  Future<void> extendDeadline(Long enrollmentId, int extraDays) async {
    log("[MentorStudentService] extendDeadline() — enrollmentId=${enrollmentId.value}, extraDays=$extraDays");

    try {
      _logStep("Getting auth token...");
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }
      _logResult("Token", "obtained");

      final url = "$baseUrl/lms/enrollments/${enrollmentId.value}/extend-deadline?extraDays=$extraDays";
      _logResult("URL", url);

      _logStep("Sending PUT request...");
      _logRequest("EXTEND DEADLINE", url, headers: _headers(token));
      final res = await http.put(
        Uri.parse(url),
        headers: _headers(token),
      );
      _logResponse(res);

      if (res.statusCode == 200 || res.statusCode == 204) {
        _logResult("Deadline extended", "enrollmentId=${enrollmentId.value}, +$extraDays days");
        return;
      }

      throw Exception("Extend deadline failed: HTTP ${res.statusCode}");
    } catch (e) {
      log("[MentorStudentService] extendDeadline() FAILED: $e");
      rethrow;
    }
  }
}
