import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smet/model/learning_path_model.dart';
import 'package:smet/service/common/base_url.dart';

class LearningPathService {
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
  // GET ALL / SEARCH LEARNING PATHS (paginated)
  // Backend: GET /api/lms/learning-paths?keyword=&page=0&size=10
  // ============================================
  Future<LearningPathPageResponse> getAllLearningPaths({
    String? keyword,
    int page = 0,
    int size = 10,
  }) async {
    log("[LearningPathService] getAllLearningPaths() called - page=$page, size=$size, keyword=$keyword");

    try {
      _logStep("Getting auth token...");
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }
      _logResult("Token", "obtained (${token.length} chars)");

      final params = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };
      if (keyword != null && keyword.isNotEmpty) params['keyword'] = keyword;
      final uri = Uri.parse("$baseUrl/lms/learning-paths").replace(queryParameters: params);
      final url = uri.toString();
      _logResult("URL", url);

      _logStep("Sending GET request...");
      _logRequest("GET ALL LEARNING PATHS", url, headers: _headers(token));
      final res = await http.get(Uri.parse(url), headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200) {
        _logStep("Parsing response JSON...");
        try {
          final decoded = jsonDecode(res.body);
          if (decoded == null) {
            log("  [WARN] Response body is null - returning empty page");
            return LearningPathPageResponse.empty();
          }
          final Map<String, dynamic> data = Map<String, dynamic>.from(decoded);
          final result = LearningPathPageResponse.fromJson(data);
          _logResult("Learning paths loaded", "${result.content.length} / ${result.totalElements} total");
          for (int i = 0; i < result.content.length; i++) {
            _logResult("  Path[$i]", "id=${result.content[i].id.value}, title=${result.content[i].title}");
          }
          return result;
        } on FormatException catch (e) {
          log("  [ERROR] JSON parse failed: $e");
          throw Exception("Server returned invalid JSON. Is the backend running?");
        }
      }

      throw Exception("Get learning paths failed: HTTP ${res.statusCode}");
    } catch (e) {
      log("[LearningPathService] getAllLearningPaths() FAILED: $e");
      rethrow;
    }
  }

  // ============================================
  // GET LEARNING PATH BY ID (DETAIL)
  // Backend: GET /api/lms/learning-paths/{id}
  // Returns: LearningPathResponse (with courses list)
  // ============================================
  Future<LearningPathDetailResponse> getLearningPathDetail(Long pathId) async {
    log("[LearningPathService] getLearningPathDetail() called - pathId=${pathId.value}");

    try {
      _logStep("Getting auth token...");
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final url = "$baseUrl/lms/learning-paths/$pathId";
      _logResult("URL", url);

      _logStep("Sending GET request...");
      _logRequest("GET LEARNING PATH DETAIL", url, headers: _headers(token));
      final res = await http.get(Uri.parse(url), headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200) {
        _logStep("Parsing response JSON...");
        try {
          final decoded = jsonDecode(res.body);
          if (decoded == null) throw Exception("Empty response from server");
          final Map<String, dynamic> data = Map<String, dynamic>.from(decoded);
          final result = LearningPathDetailResponse.fromJson(data);
          _logResult("Learning path loaded", "id=${result.id.value}, title=${result.title}");
          _logResult("Courses count", result.courses.length);
          for (int i = 0; i < result.courses.length; i++) {
            _logResult("  Course[$i]", "courseId=${result.courses[i].courseId.value}, title=${result.courses[i].title}, order=${result.courses[i].orderIndex}");
          }
          return result;
        } on FormatException catch (e) {
          log("  [ERROR] JSON parse failed: $e");
          throw Exception("Server returned invalid JSON. Is the backend running?");
        }
      }

      throw Exception("Get learning path detail failed: HTTP ${res.statusCode}");
    } catch (e) {
      log("[LearningPathService] getLearningPathDetail() FAILED: $e");
      rethrow;
    }
  }

  // ============================================
  // CREATE LEARNING PATH
  // Backend: POST /api/lms/learning-paths?title=&description=
  // Backend uses @RequestParam (query params), NOT JSON body
  // ============================================
  Future<Map<String, dynamic>> createLearningPath(String title, String description) async {
    log("[LearningPathService] createLearningPath() called - title=$title");

    try {
      _logStep("Getting auth token...");
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final uri = Uri.parse("$baseUrl/lms/learning-paths").replace(queryParameters: {
        'title': title,
        'description': description,
      });
      final url = uri.toString();
      _logResult("URL", url);

      _logStep("Sending POST request...");
      _logRequest("CREATE LEARNING PATH", url, headers: _headers(token));
      final res = await http.post(Uri.parse(url), headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200 || res.statusCode == 201) {
        _logStep("Parsing response JSON...");
        final decoded = jsonDecode(res.body);
        if (decoded == null) throw Exception("Empty response from server");
        final Map<String, dynamic> data = Map<String, dynamic>.from(decoded);
        final id = _parseLong(data['id']).value;
        _logResult("Learning path created", "id=$id, title=${data['title']}");
        return data;
      }

      throw Exception("Create learning path failed: HTTP ${res.statusCode}");
    } catch (e) {
      log("[LearningPathService] createLearningPath() FAILED: $e");
      rethrow;
    }
  }

  // ============================================
  // ADD COURSE TO LEARNING PATH
  // Backend: POST /api/lms/learning-paths/{pathId}/courses/{courseId}?orderIndex=
  // ============================================
  Future<void> addCourseToLearningPath(Long pathId, Long courseId, int orderIndex) async {
    log("[LearningPathService] addCourseToLearningPath() called - pathId=${pathId.value}, courseId=${courseId.value}, orderIndex=$orderIndex");

    try {
      _logStep("Getting auth token...");
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final url = "$baseUrl/lms/learning-paths/$pathId/courses/$courseId?orderIndex=$orderIndex";
      _logResult("URL", url);

      _logStep("Sending POST request...");
      _logRequest("ADD COURSE TO LEARNING PATH", url, headers: _headers(token));
      final res = await http.post(Uri.parse(url), headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200 || res.statusCode == 201) {
        _logResult("Course added", "pathId=${pathId.value}, courseId=${courseId.value}, orderIndex=$orderIndex");
        return;
      }

      throw Exception("Add course to learning path failed: HTTP ${res.statusCode}");
    } catch (e) {
      log("[LearningPathService] addCourseToLearningPath() FAILED: $e");
      rethrow;
    }
  }

  // ============================================
  // REMOVE COURSE FROM LEARNING PATH
  // Backend: DELETE /api/lms/learning-paths/{pathId}/courses/{relationId}
  // Backend uses relationId (learning_path_course PK), NOT courseId
  // ============================================
  Future<void> removeCourseFromLearningPath(Long pathId, Long relationId) async {
  final token = await _getToken();

  final url =
      "$baseUrl/lms/learning-paths/${pathId.value}/courses/${relationId.value}";

  final res = await http.delete(
    Uri.parse(url),
    headers: _headers(token!),
  );

  if (res.statusCode != 200 && res.statusCode != 204) {
    throw Exception("Remove course failed: ${res.body}");
  }
}
Future<void> reorderCourses(
    Long pathId, List<Map<String, dynamic>> orders) async {
  final token = await _getToken();

  final url = "$baseUrl/lms/learning-paths/${pathId.value}/reorder";

  final res = await http.put(
    Uri.parse(url),
    headers: _headers(token!),
    body: jsonEncode(orders),
  );

  if (res.statusCode != 200) {
    throw Exception("Reorder failed: ${res.body}");
  }
}

  // ============================================
  // UPDATE LEARNING PATH (title, description)
  // Backend: PUT /api/lms/learning-paths/{pathId}?title=&description=
  // Backend uses @RequestParam (query params), NOT JSON body
  // ============================================
  Future<void> updateLearningPath(Long pathId, String title, String description) async {
    log("[LearningPathService] updateLearningPath() called - pathId=${pathId.value}, title=$title");

    try {
      _logStep("Getting auth token...");
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final uri = Uri.parse("$baseUrl/lms/learning-paths/$pathId").replace(queryParameters: {
        'title': title,
        'description': description,
      });
      final url = uri.toString();
      _logResult("URL", url);

      _logStep("Sending PUT request...");
      _logRequest("UPDATE LEARNING PATH", url, headers: _headers(token));
      final res = await http.put(Uri.parse(url), headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200) {
        _logResult("Learning path updated", "pathId=${pathId.value}");
        return;
      }

      throw Exception("Update learning path failed: HTTP ${res.statusCode}");
    } catch (e) {
      log("[LearningPathService] updateLearningPath() FAILED: $e");
      rethrow;
    }
  }

  // ============================================
  // DELETE LEARNING PATH
  // Backend: DELETE /api/lms/learning-paths/{pathId}
  // ============================================
  Future<void> deleteLearningPath(Long pathId) async {
    log("[LearningPathService] deleteLearningPath() called - pathId=${pathId.value}");

    try {
      _logStep("Getting auth token...");
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final url = "$baseUrl/lms/learning-paths/$pathId";
      _logResult("URL", url);

      _logStep("Sending DELETE request...");
      _logRequest("DELETE LEARNING PATH", url, headers: _headers(token));
      final res = await http.delete(Uri.parse(url), headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200 || res.statusCode == 204) {
        _logResult("Learning path deleted", "pathId=${pathId.value}");
        return;
      }

      throw Exception("Delete learning path failed: HTTP ${res.statusCode}");
    } catch (e) {
      log("[LearningPathService] deleteLearningPath() FAILED: $e");
      rethrow;
    }
  }

  // ============================================
  // GET COURSES FOR COURSE SELECTOR
  // Backend: GET /api/lms/courses (paginated) - fetch all pages
  // ============================================
  Future<List<Map<String, dynamic>>> getMentorCourses() async {
    log("[LearningPathService] getMentorCourses() called");

    try {
      _logStep("Getting auth token...");
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }
      _logResult("Token", "obtained (${token.length} chars)");

      // Fetch all pages from courses list endpoint
      final allCourses = <Map<String, dynamic>>[];
      int page = 0;
      const size = 50;
      int totalPages = 1;

      while (page < totalPages) {
        final url = "$baseUrl/lms/courses?page=$page&size=$size";
        _logResult("URL", url);

        _logStep("Sending GET request (page $page)...");
        _logRequest("GET MENTOR COURSES", url, headers: _headers(token));
        final res = await http.get(Uri.parse(url), headers: _headers(token));
        _logResponse(res);

        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          if (decoded != null) {
            final data = Map<String, dynamic>.from(decoded);
            final content = data['data'] as List<dynamic>?;
            if (content != null) {
              allCourses.addAll(content.map((e) => Map<String, dynamic>.from(e)));
            }
            totalPages = _parseInt(data['totalPages'] ?? 1);
            _logResult("Page $page loaded", "${content?.length ?? 0} courses (total: $totalPages pages)");
          }
        } else {
          throw Exception("Get courses failed: HTTP ${res.statusCode}");
        }
        page++;
      }

      _logResult("Mentor courses loaded", "${allCourses.length} total courses");
      for (int i = 0; i < allCourses.length && i < 10; i++) {
        _logResult("  Course[$i]", "id=${allCourses[i]['id']}, title=${allCourses[i]['title']}");
      }
      return allCourses;
    } catch (e) {
      log("[LearningPathService] getMentorCourses() FAILED: $e");
      rethrow;
    }
  }

  // ============================================
  // REORDER COURSE IN LEARNING PATH
  // Backend: PUT /api/lms/learning-paths/{pathId}/courses/reorder?relationId=&newOrderIndex=
  // ============================================
  Future<void> reorderCourse(Long pathId, Long relationId, int newOrderIndex) async {
    log("[LearningPathService] reorderCourse() called - pathId=${pathId.value}, relationId=${relationId.value}, newOrderIndex=$newOrderIndex");

    try {
      _logStep("Getting auth token...");
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final url = "$baseUrl/lms/learning-paths/$pathId/courses/reorder?relationId=$relationId&newOrderIndex=$newOrderIndex";
      _logResult("URL", url);

      _logStep("Sending PUT request...");
      _logRequest("REORDER COURSE IN LEARNING PATH", url, headers: _headers(token));
      final res = await http.put(Uri.parse(url), headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200) {
        _logResult("Course reordered", "pathId=${pathId.value}, relationId=${relationId.value}, newOrderIndex=$newOrderIndex");
        return;
      }

      throw Exception("Reorder course failed: HTTP ${res.statusCode}");
    } catch (e) {
      log("[LearningPathService] reorderCourse() FAILED: $e");
      rethrow;
    }
  }

  // ============================================
  // ASSIGN LEARNING PATH TO DEPARTMENT
  // Backend: POST /api/lms/learning-paths/{pathId}/assign/department/{departmentId}
  // Role: ADMIN, PROJECT_LEAD
  // ============================================
  Future<void> assignToDepartment(Long pathId, Long departmentId) async {
    log("[LearningPathService] assignToDepartment() called - pathId=${pathId.value}, departmentId=${departmentId.value}");

    try {
      _logStep("Getting auth token...");
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final url = "$baseUrl/lms/learning-paths/$pathId/assign/department/$departmentId";
      _logResult("URL", url);

      _logStep("Sending POST request...");
      _logRequest("ASSIGN TO DEPARTMENT", url, headers: _headers(token));
      final res = await http.post(Uri.parse(url), headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200 || res.statusCode == 201) {
        _logResult("Assigned to department", "pathId=${pathId.value}, departmentId=${departmentId.value}");
        return;
      }

      throw Exception("Assign to department failed: HTTP ${res.statusCode}");
    } catch (e) {
      log("[LearningPathService] assignToDepartment() FAILED: $e");
      rethrow;
    }
  }

  // ============================================
  // ASSIGN LEARNING PATH TO PROJECT
  // Backend: POST /api/lms/learning-paths/{pathId}/assign/project/{projectId}
  // Role: ADMIN, PROJECT_LEAD
  // ============================================
  Future<void> assignToProject(Long pathId, Long projectId) async {
    log("[LearningPathService] assignToProject() called - pathId=${pathId.value}, projectId=${projectId.value}");

    try {
      _logStep("Getting auth token...");
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final url = "$baseUrl/lms/learning-paths/$pathId/assign/project/$projectId";
      _logResult("URL", url);

      _logStep("Sending POST request...");
      _logRequest("ASSIGN TO PROJECT", url, headers: _headers(token));
      final res = await http.post(Uri.parse(url), headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200 || res.statusCode == 201) {
        _logResult("Assigned to project", "pathId=${pathId.value}, projectId=${projectId.value}");
        return;
      }

      throw Exception("Assign to project failed: HTTP ${res.statusCode}");
    } catch (e) {
      log("[LearningPathService] assignToProject() FAILED: $e");
      rethrow;
    }
  }

  // ============================================
  // ASSIGN LEARNING PATH TO USER
  // Backend: POST /api/lms/learning-paths/{pathId}/assign/user/{userId}
  // Role: ADMIN, PROJECT_LEAD
  // ============================================
  Future<void> assignToUser(Long pathId, Long userId) async {
    log("[LearningPathService] assignToUser() called - pathId=${pathId.value}, userId=${userId.value}");

    try {
      _logStep("Getting auth token...");
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please login again.");
      }

      final url = "$baseUrl/lms/learning-paths/$pathId/assign/user/$userId";
      _logResult("URL", url);

      _logStep("Sending POST request...");
      _logRequest("ASSIGN TO USER", url, headers: _headers(token));
      final res = await http.post(Uri.parse(url), headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200 || res.statusCode == 201) {
        _logResult("Assigned to user", "pathId=${pathId.value}, userId=${userId.value}");
        return;
      }

      throw Exception("Assign to user failed: HTTP ${res.statusCode}");
    } catch (e) {
      log("[LearningPathService] assignToUser() FAILED: $e");
      rethrow;
    }
  }

  // ============================================
  // HELPER: parse int safely
  // ============================================
  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Long _parseLong(dynamic value) {
    if (value == null) return Long(0);
    if (value is int) return Long(value);
    if (value is double) return Long(value.toInt());
    if (value is String) {
      final parsed = int.tryParse(value);
      return Long(parsed ?? 0);
    }
    return Long(0);
  }
}
