import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/service/common/base_url.dart';

class MentorLessonService {
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

  // CREATE LESSON
  // Backend: POST /api/lms/lessons
  Future<LessonResponse> createLesson(CreateLessonRequest request) async {
    log("[MentorLessonService] createLesson() called â€” title=${request.title}, moduleId=${request.moduleId}");

    try {
      _logStep("Getting auth token...");
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final url = "$baseUrl/lms/lessons";
      _logResult("URL", url);
      _logResult("Body", request.toJson());

      _logStep("Sending POST request...");
      _logRequest("CREATE LESSON", url, headers: _headers(token), body: request.toJson());
      final res = await http.post(
        Uri.parse(url),
        headers: _headers(token),
        body: jsonEncode(request.toJson()),
      );
      _logResponse(res);

      if (res.statusCode == 200 || res.statusCode == 201) {
        _logStep("Parsing response JSON...");
        try {
          final decoded = jsonDecode(res.body);
          if (decoded == null) throw Exception("Empty response from server");
          final Map<String, dynamic> data = Map<String, dynamic>.from(decoded);
          final result = LessonResponse.fromJson(data);
          _logResult("Lesson created", "id=${result.id.value}, title=${result.title}");
          return result;
        } on FormatException catch (e) {
          log("  [ERROR] JSON parse failed: $e");
          throw Exception("Server returned invalid JSON.");
        }
      }

      throw Exception("Create lesson failed: HTTP ${res.statusCode} â€” ${res.body}");
    } catch (e) {
      log("[MentorLessonService] createLesson() FAILED: $e");
      rethrow;
    }
  }

  // UPDATE LESSON
  // Backend: PUT /api/lms/lessons/{id}
  Future<LessonResponse> updateLesson(Long lessonId, CreateLessonRequest request) async {
    log("[MentorLessonService] updateLesson() called â€” lessonId=${lessonId.value}, title=${request.title}");

    try {
      _logStep("Getting auth token...");
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final url = "$baseUrl/lms/lessons/${lessonId.value}";
      _logResult("URL", url);
      _logResult("Body", request.toJson());

      _logStep("Sending PUT request...");
      _logRequest("UPDATE LESSON", url, headers: _headers(token), body: request.toJson());
      final res = await http.put(
        Uri.parse(url),
        headers: _headers(token),
        body: jsonEncode(request.toJson()),
      );
      _logResponse(res);

      if (res.statusCode == 200) {
        _logStep("Parsing response JSON...");
        try {
          final decoded = jsonDecode(res.body);
          if (decoded == null) throw Exception("Empty response from server");
          final Map<String, dynamic> data = Map<String, dynamic>.from(decoded);
          final result = LessonResponse.fromJson(data);
          _logResult("Lesson updated", "id=${result.id.value}");
          return result;
        } on FormatException catch (e) {
          log("  [ERROR] JSON parse failed: $e");
          throw Exception("Server returned invalid JSON.");
        }
      }

      throw Exception("Update lesson failed: HTTP ${res.statusCode} â€” ${res.body}");
    } catch (e) {
      log("[MentorLessonService] updateLesson() FAILED: $e");
      rethrow;
    }
  }

  // DELETE LESSON
  // Backend: DELETE /api/lms/lessons/{id}
  Future<void> deleteLesson(Long lessonId) async {
    log("[MentorLessonService] deleteLesson() called â€” lessonId=${lessonId.value}");

    try {
      _logStep("Getting auth token...");
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final url = "$baseUrl/lms/lessons/${lessonId.value}";
      _logResult("URL", url);

      _logStep("Sending DELETE request...");
      _logRequest("DELETE LESSON", url, headers: _headers(token));
      final res = await http.delete(Uri.parse(url), headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200 || res.statusCode == 204) {
        _logResult("Lesson deleted", "id=${lessonId.value}");
        return;
      }

      throw Exception("Delete lesson failed: HTTP ${res.statusCode} â€” ${res.body}");
    } catch (e) {
      log("[MentorLessonService] deleteLesson() FAILED: $e");
      rethrow;
    }
  }

  // ============================================
  // REORDER LESSONS
  // Backend: PUT /api/lms/lessons/modules/{moduleId}/lessons/reorder
  // Body: List<{id, orderIndex}>
  // ============================================
  Future<void> reorderLessons(Long moduleId, List<Long> lessonIds) async {
    log("[MentorLessonService] reorderLessons() called — moduleId=${moduleId.value}, lessonIds=$lessonIds");

    try {
      _logStep("Getting auth token...");
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final url = "$baseUrl/lms/lessons/modules/${moduleId.value}/lessons/reorder";
      _logResult("URL", url);

      final body = List.generate(
        lessonIds.length,
        (i) => {"id": lessonIds[i], "orderIndex": i},
      );
      _logResult("Body", body);

      _logStep("Sending PUT request...");
      _logRequest("REORDER LESSONS", url, headers: _headers(token), body: body);
      final res = await http.put(
        Uri.parse(url),
        headers: _headers(token),
        body: jsonEncode(body),
      );
      _logResponse(res);

      if (res.statusCode == 200 || res.statusCode == 204) {
        _logResult("Lessons reordered", lessonIds.toString());
        return;
      }

      throw Exception("Reorder lessons failed: HTTP ${res.statusCode} — ${res.body}");
    } catch (e) {
      log("[MentorLessonService] reorderLessons() FAILED: $e");
      rethrow;
    }
  }

  // GET LESSONS BY MODULE
  // Backend: GET /api/lms/lessons/module/{moduleId}
  Future<List<LessonResponse>> getLessonsByModule(Long moduleId) async {
    log("[MentorLessonService] getLessonsByModule() called â€” moduleId=${moduleId.value}");

    try {
      _logStep("Getting auth token...");
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final url = "$baseUrl/lms/lessons/module/${moduleId.value}";
      _logResult("URL", url);

      _logStep("Sending GET request...");
      _logRequest("GET LESSONS BY MODULE", url, headers: _headers(token));
      final res = await http.get(Uri.parse(url), headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200) {
        _logStep("Parsing response JSON...");
        try {
          final decoded = jsonDecode(res.body);
          if (decoded == null) return [];
          final List<dynamic> list = List<dynamic>.from(decoded);
          final result = list.map((e) => LessonResponse.fromJson(e as Map<String, dynamic>)).toList();
          _logResult("Lessons loaded", "${result.length} lessons");
          return result;
        } on FormatException catch (e) {
          log("  [ERROR] JSON parse failed: $e");
          throw Exception("Server returned invalid JSON.");
        }
      }

      throw Exception("Get lessons failed: HTTP ${res.statusCode} â€” ${res.body}");
    } catch (e) {
      log("[MentorLessonService] getLessonsByModule() FAILED: $e");
      rethrow;
    }
  }
}
