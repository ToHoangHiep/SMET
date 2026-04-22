import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/service/common/base_url.dart';

class MentorModuleService {
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
  // CREATE MODULE
  // Backend: POST /api/lms/modules
  // ============================================
  Future<ModuleResponse> createModule(CreateModuleRequest request) async {
    log("[MentorModuleService] createModule() called — title=${request.title}, courseId=${request.courseId}");

    try {
      _logStep("Getting auth token...");
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final url = "$baseUrl/lms/modules";
      _logResult("URL", url);
      _logResult("Body", request.toJson());

      _logStep("Sending POST request...");
      _logRequest("CREATE MODULE", url, headers: _headers(token), body: request.toJson());
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
          final result = ModuleResponse.fromJson(data);
          _logResult("Module created", "id=${result.id.value}, title=${result.title}");
          return result;
        } on FormatException catch (e) {
          log("  [ERROR] JSON parse failed: $e");
          throw Exception("Server returned invalid JSON.");
        }
      }

      throw Exception("Create module failed: HTTP ${res.statusCode} — ${res.body}");
    } catch (e) {
      log("[MentorModuleService] createModule() FAILED: $e");
      rethrow;
    }
  }

  // ============================================
  // UPDATE MODULE
  // Backend: PUT /api/lms/modules/{id}
  // ============================================
  Future<ModuleResponse> updateModule(Long moduleId, CreateModuleRequest request) async {
    log("[MentorModuleService] updateModule() called — moduleId=${moduleId.value}, title=${request.title}");

    try {
      _logStep("Getting auth token...");
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final url = "$baseUrl/lms/modules/${moduleId.value}";
      _logResult("URL", url);
      _logResult("Body", request.toJson());

      _logStep("Sending PUT request...");
      _logRequest("UPDATE MODULE", url, headers: _headers(token), body: request.toJson());
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
          final result = ModuleResponse.fromJson(data);
          _logResult("Module updated", "id=${result.id.value}");
          return result;
        } on FormatException catch (e) {
          log("  [ERROR] JSON parse failed: $e");
          throw Exception("Server returned invalid JSON.");
        }
      }

      throw Exception("Update module failed: HTTP ${res.statusCode} — ${res.body}");
    } catch (e) {
      log("[MentorModuleService] updateModule() FAILED: $e");
      rethrow;
    }
  }

  // ============================================
  // DELETE MODULE
  // Backend: DELETE /api/lms/modules/{id}
  // ============================================
  Future<void> deleteModule(Long moduleId) async {
    log("[MentorModuleService] deleteModule() called — moduleId=${moduleId.value}");

    try {
      _logStep("Getting auth token...");
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final url = "$baseUrl/lms/modules/${moduleId.value}";
      _logResult("URL", url);

      _logStep("Sending DELETE request...");
      _logRequest("DELETE MODULE", url, headers: _headers(token));
      final res = await http.delete(Uri.parse(url), headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200 || res.statusCode == 204) {
        _logResult("Module deleted", "id=${moduleId.value}");
        return;
      }

      throw Exception("Delete module failed: HTTP ${res.statusCode} — ${res.body}");
    } catch (e) {
      log("[MentorModuleService] deleteModule() FAILED: $e");
      rethrow;
    }
  }

  // ============================================
  // GET MODULES BY COURSE
  // Backend: GET /api/lms/modules/course/{courseId}
  // ============================================
  Future<List<ModuleResponse>> getModulesByCourse(Long courseId) async {
    log("[MentorModuleService] getModulesByCourse() called — courseId=${courseId.value}");

    try {
      _logStep("Getting auth token...");
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final url = "$baseUrl/lms/modules/course/${courseId.value}";
      _logResult("URL", url);

      _logStep("Sending GET request...");
      _logRequest("GET MODULES BY COURSE", url, headers: _headers(token));
      final res = await http.get(Uri.parse(url), headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200) {
        _logStep("Parsing response JSON...");
        try {
          final decoded = jsonDecode(res.body);
          if (decoded == null) return [];
          final List<dynamic> list = List<dynamic>.from(decoded);
          final result = list.map((e) => ModuleResponse.fromJson(e as Map<String, dynamic>)).toList();
          _logResult("Modules loaded", "${result.length} modules");
          return result;
        } on FormatException catch (e) {
          log("  [ERROR] JSON parse failed: $e");
          throw Exception("Server returned invalid JSON.");
        }
      }

      throw Exception("Get modules failed: HTTP ${res.statusCode} — ${res.body}");
    } catch (e) {
      log("[MentorModuleService] getModulesByCourse() FAILED: $e");
      rethrow;
    }
  }
}
