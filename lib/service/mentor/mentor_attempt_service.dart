import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smet/model/mentor_attempt_model.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/service/common/base_url.dart';

/// ============================================================
/// MENTOR ATTEMPT / ASSIGNMENT REVIEW SERVICE
/// Backend: AttemptController
///   GET  /api/lms/attempts/history/{quizId}
///         -> List<AttemptHistoryResponse>
///   GET  /api/lms/attempts/{attemptId}/questions
///         -> List<AttemptQuestionResponse>
///   GET  /api/lms/attempts/summary/{quizId}
///         -> QuizResultSummaryResponse
///
/// NOTE: Backend permission check @perm.isAttemptOwner chỉ cho phép
///       USER đang sở hữu attempt truy cập. Mentor muốn chấm bài
///       của học viên CẦN backend sửa permission để cho phép
///       MENTOR (quiz owner) truy cập mọi attempt của quiz đó.
/// ============================================================

class MentorAttemptService {
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
  // GET ATTEMPT HISTORY BY QUIZ
  // Backend: GET /api/lms/attempts/history/{quizId}
  // Returns: List of all attempts for a quiz (all students)
  // NOTE: Permission @perm.isAttemptOwner - chỉ owner attempt mới truy cập.
  //       Mentor cần backend sửa để quiz owner (mentor) được truy cập
  //       mọi attempt của quiz mình tạo.
  // ============================================
  Future<List<MentorAttemptInfo>> getAttemptsByQuiz(Long quizId) async {
    log("[MentorAttemptService] getAttemptsByQuiz() — quizId=${quizId.value}");

    try {
      _logStep("Getting auth token...");
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }
      _logResult("Token", "obtained (${token.length} chars)");

      final url = "$baseUrl/lms/attempts/history/${quizId.value}";
      _logResult("URL", url);

      _logStep("Sending GET request...");
      _logRequest("GET ATTEMPTS BY QUIZ", url, headers: _headers(token));
      final res = await http.get(Uri.parse(url), headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200) {
        _logStep("Parsing response JSON...");
        try {
          final decoded = jsonDecode(res.body);
          if (decoded == null || decoded is! List) {
            log("  [WARN] Response is not a list — returning empty");
            return [];
          }
          final List<dynamic> data = decoded as List<dynamic>;
          final attempts = data
              .map((e) => MentorAttemptInfo.fromJson(e as Map<String, dynamic>))
              .toList();
          _logResult("Attempts loaded", "${attempts.length} attempts");
          return attempts;
        } on FormatException catch (e) {
          log("  [ERROR] JSON parse failed: $e");
          throw Exception("Server returned invalid JSON.");
        }
      }

      if (res.statusCode == 403) {
        log("  [WARN] Permission denied — backend permission @perm.isAttemptOwner "
            "chưa cho phép mentor truy cập. Cần sửa backend.");
        throw Exception("Bạn không có quyền truy cập. "
            "Vui lòng liên hệ admin để được cấp quyền chấm bài.");
      }

      throw Exception("Get attempts failed: HTTP ${res.statusCode}");
    } catch (e) {
      log("[MentorAttemptService] getAttemptsByQuiz() FAILED: $e");
      rethrow;
    }
  }

  // ============================================
  // GET ATTEMPT QUESTIONS (chi tiết bài nộp)
  // Backend: GET /api/lms/attempts/{attemptId}/questions?page=0&size=10
  // Returns: List of AttemptQuestionResponse
  // NOTE: Same permission restriction as above
  // ============================================
  Future<List<AttemptQuestionInfo>> getAttemptQuestions(
    Long attemptId, {
    int page = 0,
    int size = 10,
  }) async {
    log("[MentorAttemptService] getAttemptQuestions() — attemptId=${attemptId.value}");

    try {
      _logStep("Getting auth token...");
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final uri = Uri.parse("$baseUrl/lms/attempts/${attemptId.value}/questions")
          .replace(queryParameters: {
        'page': page.toString(),
        'size': size.toString(),
      });
      final url = uri.toString();
      _logResult("URL", url);

      _logStep("Sending GET request...");
      _logRequest("GET ATTEMPT QUESTIONS", url, headers: _headers(token));
      final res = await http.get(Uri.parse(url), headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200) {
        _logStep("Parsing response JSON...");
        try {
          final decoded = jsonDecode(res.body);
          if (decoded == null || decoded is! List) {
            return [];
          }
          final List<dynamic> data = decoded as List<dynamic>;
          final questions = data
              .map((e) => AttemptQuestionInfo.fromJson(e as Map<String, dynamic>))
              .toList();
          _logResult("Questions loaded", "${questions.length} questions");
          return questions;
        } on FormatException catch (e) {
          log("  [ERROR] JSON parse failed: $e");
          throw Exception("Server returned invalid JSON.");
        }
      }

      if (res.statusCode == 403) {
        throw Exception("Bạn không có quyền truy cập bài nộp này.");
      }

      throw Exception("Get attempt questions failed: HTTP ${res.statusCode}");
    } catch (e) {
      log("[MentorAttemptService] getAttemptQuestions() FAILED: $e");
      rethrow;
    }
  }

  // ============================================
  // GET QUIZ RESULT SUMMARY
  // Backend: GET /api/lms/attempts/summary/{quizId}
  // Returns: QuizResultSummaryResponse
  // ============================================
  Future<Map<String, dynamic>> getQuizResultSummary(Long quizId) async {
    log("[MentorAttemptService] getQuizResultSummary() — quizId=${quizId.value}");

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final url = "$baseUrl/lms/attempts/summary/${quizId.value}";
      _logRequest("GET QUIZ RESULT SUMMARY", url, headers: _headers(token));
      final res = await http.get(Uri.parse(url), headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded == null) throw Exception("Empty response from server");
        _logResult("Summary loaded", decoded);
        return Map<String, dynamic>.from(decoded);
      }

      throw Exception("Get quiz summary failed: HTTP ${res.statusCode}");
    } catch (e) {
      log("[MentorAttemptService] getQuizResultSummary() FAILED: $e");
      rethrow;
    }
  }
}
