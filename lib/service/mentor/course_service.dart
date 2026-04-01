import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/service/common/base_url.dart';

class MentorCourseService {
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
      // Hide token for security
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
  // LIST COURSES (paginated)
  // Backend: GET /api/lms/courses?keyword=&published=&page=&size=
  // ============================================
  Future<PageResponse<CourseResponse>> listCourses({
    String? keyword,
    bool? published,
    int page = 0,
    int size = 10,
  }) async {
    log("[MentorCourseService] listCourses() called — page=$page, size=$size, keyword=$keyword, published=$published");

    try {
      _logStep("Getting auth token...");
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }
      _logResult("Token", "obtained (${token.length} chars)");

      _logStep("Building request URL...");
      final params = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };
      if (keyword != null && keyword.isNotEmpty) params['keyword'] = keyword;
      if (published != null) params['published'] = published.toString();
      final uri = Uri.parse("$baseUrl/lms/courses").replace(queryParameters: params);
      final url = uri.toString();
      _logResult("URL", url);

      _logStep("Sending GET request...");
      _logRequest("LIST COURSES", url, headers: _headers(token));
      final res = await http.get(Uri.parse(url), headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200) {
        _logStep("Parsing response JSON...");
        try {
          final decoded = jsonDecode(res.body);
          if (decoded == null) {
            log("  [WARN] Response body is null — returning empty page");
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
          final Map<String, dynamic> data = Map<String, dynamic>.from(decoded);
          final result = PageResponse.fromJson(data, CourseResponse.fromJson);
          _logResult("Courses loaded", "${result.content.length} / ${result.totalElements} total");
          return result;
        } on FormatException catch (e) {
          log("  [ERROR] JSON parse failed: $e");
          throw Exception("Server returned invalid JSON. Is the backend running?");
        }
      }

      throw Exception("List courses failed: HTTP ${res.statusCode}");
    } catch (e) {
      log("[MentorCourseService] listCourses() FAILED: $e");
      rethrow;
    }
  }

  // ============================================
  // GET COURSE DETAIL
  // Backend: GET /api/lms/courses/{id}
  // ============================================
  Future<CourseDetailResponse> getCourseDetail(Long courseId) async {
    log("[MentorCourseService] getCourseDetail() called — courseId=${courseId.value}");

    try {
      _logStep("Getting auth token...");
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final url = "$baseUrl/lms/courses/${courseId.value}";
      _logResult("URL", url);

      _logStep("Sending GET request...");
      _logRequest("GET COURSE DETAIL", url, headers: _headers(token));
      final res = await http.get(Uri.parse(url), headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200) {
        _logStep("Parsing response JSON...");
        try {
          final decoded = jsonDecode(res.body);
          if (decoded == null) throw Exception("Empty response from server");
          final Map<String, dynamic> data = Map<String, dynamic>.from(decoded);
          final result = CourseDetailResponse.fromJson(data);
          _logResult("Course loaded", "id=${result.id.value}, title=${result.title}");
          _logResult("Modules count", result.moduleCount);
          return result;
        } on FormatException catch (e) {
          log("  [ERROR] JSON parse failed: $e");
          throw Exception("Server returned invalid JSON. Is the backend running?");
        }
      }

      throw Exception("Get course detail failed: HTTP ${res.statusCode}");
    } catch (e) {
      log("[MentorCourseService] getCourseDetail() FAILED: $e");
      rethrow;
    }
  }

  // ============================================
  // CREATE COURSE
  // Backend: POST /api/lms/courses
  // ============================================
  Future<CourseResponse> createCourse(CreateCourseRequest request) async {
    log("[MentorCourseService] createCourse() called — title=${request.title}");

    try {
      _logStep("Getting auth token...");
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final url = "$baseUrl/lms/courses";
      _logResult("URL", url);
      _logResult("Body", request.toJson());

      _logStep("Sending POST request...");
      _logRequest("CREATE COURSE", url, headers: _headers(token), body: request.toJson());
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
          final result = CourseResponse.fromJson(data);
          _logResult("Course created", "id=${result.id.value}, title=${result.title}");
          return result;
        } on FormatException catch (e) {
          log("  [ERROR] JSON parse failed: $e");
          throw Exception("Server returned invalid JSON.");
        }
      }

      throw Exception("Create course failed: HTTP ${res.statusCode} — ${res.body}");
    } catch (e) {
      log("[MentorCourseService] createCourse() FAILED: $e");
      rethrow;
    }
  }

  // ============================================
  // UPDATE COURSE
  // Backend: PUT /api/lms/courses/{id}
  // ============================================
  Future<CourseResponse> updateCourse(Long courseId, UpdateCourseRequest request) async {
    log("[MentorCourseService] updateCourse() called — courseId=${courseId.value}, title=${request.title}");

    try {
      _logStep("Getting auth token...");
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final url = "$baseUrl/lms/courses/${courseId.value}";
      _logResult("URL", url);
      _logResult("Body", request.toJson());

      _logStep("Sending PUT request...");
      _logRequest("UPDATE COURSE", url, headers: _headers(token), body: request.toJson());
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
          final result = CourseResponse.fromJson(data);
          _logResult("Course updated", "id=${result.id.value}");
          return result;
        } on FormatException catch (e) {
          log("  [ERROR] JSON parse failed: $e");
          throw Exception("Server returned invalid JSON.");
        }
      }

      throw Exception("Update course failed: HTTP ${res.statusCode}");
    } catch (e) {
      log("[MentorCourseService] updateCourse() FAILED: $e");
      rethrow;
    }
  }

  // ============================================
  // PUBLISH COURSE
  // Backend: PUT /api/lms/courses/{id}/publish
  // ============================================
  Future<CourseResponse> publishCourse(Long courseId) async {
    log("[MentorCourseService] publishCourse() called — courseId=${courseId.value}");

    try {
      _logStep("Getting auth token...");
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final url = "$baseUrl/lms/courses/${courseId.value}/publish";
      _logResult("URL", url);

      _logStep("Sending PUT request...");
      _logRequest("PUBLISH COURSE", url, headers: _headers(token));
      final res = await http.put(Uri.parse(url), headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200) {
        _logStep("Parsing response JSON...");
        try {
          final decoded = jsonDecode(res.body);
          if (decoded == null) throw Exception("Empty response from server");
          final Map<String, dynamic> data = Map<String, dynamic>.from(decoded);
          final result = CourseResponse.fromJson(data);
          _logResult("Course published", "id=${result.id.value}, published=${result.published}");
          return result;
        } on FormatException catch (e) {
          log("  [ERROR] JSON parse failed: $e");
          throw Exception("Server returned invalid JSON.");
        }
      }

      throw Exception("Publish course failed: HTTP ${res.statusCode}");
    } catch (e) {
      log("[MentorCourseService] publishCourse() FAILED: $e");
      rethrow;
    }
  }

  // ============================================
  // ARCHIVE COURSE
  // Backend: PUT /api/lms/courses/{id}/archive
  // ============================================
  Future<CourseResponse> archiveCourse(Long courseId) async {
    log("[MentorCourseService] archiveCourse() called — courseId=${courseId.value}");

    try {
      _logStep("Getting auth token...");
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final url = "$baseUrl/lms/courses/${courseId.value}/archive";
      _logResult("URL", url);

      _logStep("Sending PUT request...");
      _logRequest("ARCHIVE COURSE", url, headers: _headers(token));
      final res = await http.put(Uri.parse(url), headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200) {
        _logStep("Parsing response JSON...");
        try {
          final decoded = jsonDecode(res.body);
          if (decoded == null) throw Exception("Empty response from server");
          final Map<String, dynamic> data = Map<String, dynamic>.from(decoded);
          final result = CourseResponse.fromJson(data);
          _logResult("Course archived", "id=${result.id.value}");
          return result;
        } on FormatException catch (e) {
          log("  [ERROR] JSON parse failed: $e");
          throw Exception("Server returned invalid JSON.");
        }
      }

      throw Exception("Archive course failed: HTTP ${res.statusCode}");
    } catch (e) {
      log("[MentorCourseService] archiveCourse() FAILED: $e");
      rethrow;
    }
  }

  // ============================================
  // REORDER MODULES
  // Backend: PUT /api/lms/courses/{courseId}/modules/reorder
  // Body: List<{id, orderIndex}>
  // ============================================
  Future<void> reorderModules(Long courseId, List<Long> moduleIds) async {
    log("[MentorCourseService] reorderModules() called — courseId=${courseId.value}, moduleIds=$moduleIds");

    try {
      _logStep("Getting auth token...");
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final url = "$baseUrl/lms/courses/${courseId.value}/modules/reorder";
      _logResult("URL", url);

      final body = List.generate(
        moduleIds.length,
        (i) => {"relationId": moduleIds[i], "orderIndex": i},
      );
      _logResult("Body", body);

      _logStep("Sending PUT request...");
      _logRequest("REORDER MODULES", url, headers: _headers(token), body: body);
      final res = await http.put(
        Uri.parse(url),
        headers: _headers(token),
        body: jsonEncode(body),
      );
      _logResponse(res);

      if (res.statusCode == 200 || res.statusCode == 204) {
        _logResult("Modules reordered", moduleIds.toString());
        return;
      }

      throw Exception("Reorder modules failed: HTTP ${res.statusCode}");
    } catch (e) {
      log("[MentorCourseService] reorderModules() FAILED: $e");
      rethrow;
    }
  }

  // ============================================
  // DELETE COURSE
  // Backend: DELETE /api/lms/courses/{id}
  // ============================================
  Future<void> deleteCourse(Long courseId) async {
    log("[MentorCourseService] deleteCourse() called — courseId=${courseId.value}");

    try {
      _logStep("Getting auth token...");
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final url = "$baseUrl/lms/courses/${courseId.value}";
      _logResult("URL", url);

      _logStep("Sending DELETE request...");
      _logRequest("DELETE COURSE", url, headers: _headers(token));
      final res = await http.delete(Uri.parse(url), headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200 || res.statusCode == 204) {
        _logResult("Course deleted", "id=${courseId.value}");
        return;
      }

      throw Exception("Delete course failed: HTTP ${res.statusCode}");
    } catch (e) {
      log("[MentorCourseService] deleteCourse() FAILED: $e");
      rethrow;
    }
  }
}
