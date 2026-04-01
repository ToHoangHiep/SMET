import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:smet/model/department_model.dart';
import 'package:smet/service/common/auth_service.dart';
import 'package:smet/service/common/base_url.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DepartmentService {
  /// ================= LOG HELPER =================
  void _logRequest(
    String title,
    String url, {
    Map<String, String>? headers,
    dynamic body,
  }) {
    log("========== $title REQUEST ==========");
    log("URL: $url");

    if (headers != null) {
      log("HEADERS: $headers");
    }

    if (body != null) {
      log("BODY: $body");
    }
  }

  void _logResponse(http.Response res) {
    log("STATUS: ${res.statusCode}");
    log("RESPONSE: ${res.body}");
    log("====================================");
  }

  /// ================= TOKEN =================
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

  /// ================= CREATE =================
  /// POST /api/departments/createDepartment
  Future<DepartmentModel> createDepartment({
    required String name,
    required String code,
    bool isActive = true,
    int? projectManagerId,
    List<int>? mentorIds,
    List<int>? userIds,
  }) async {
    try {
      final url = "$baseUrl/departments/createDepartment";

      int? createdById;
      try {
        final me = await AuthService.getMe();
        final id = me['id'];
        if (id != null) createdById = id is int ? id : (id as num).toInt();
      } catch (_) {}

      final body = {
        "name": name,
        "code": code,
        "is_active": isActive,
        if (projectManagerId != null) "projectManagerId": projectManagerId,
        if (mentorIds != null && mentorIds.isNotEmpty) "mentorIds": mentorIds,
        if (userIds != null && userIds.isNotEmpty) "userIds": userIds,
        if (createdById != null) "createdBy": createdById,
      };

      _logRequest(
        "CREATE DEPARTMENT",
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final token = await _getToken();
      final response = await http.post(
        Uri.parse(url),
        headers: _headers(token!),
        body: jsonEncode(body),
      );
      _logResponse(response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return DepartmentModel.fromJson(jsonDecode(response.body));
      }

      throw Exception("Create department failed: ${response.body}");
    } catch (e) {
      log("CREATE DEPARTMENT ERROR: $e");
      rethrow;
    }
  }

  /// ================= UPDATE =================
  /// PATCH /api/departments/{id}
  Future<DepartmentModel?> updateDepartment({
    required int id,
    required String name,
    required String code,
    required bool isActive,
    int? projectManagerId,
    List<int>? mentorIds,
    List<int>? userIds,
  }) async {
    try {
      final url = "$baseUrl/departments/$id";

      final body = {
        "name": name,
        "code": code,
        "is_active": isActive,
        if (projectManagerId != null) "projectManagerId": projectManagerId,
        "mentorIds": mentorIds ?? [],
        "userIds": userIds ?? [],
      };

      _logRequest(
        "UPDATE DEPARTMENT",
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final token = await _getToken();
      final response = await http.patch(
        Uri.parse(url),
        headers: _headers(token!),
        body: jsonEncode(body),
      );

      _logResponse(response);

      if (response.statusCode == 200) {
        return DepartmentModel.fromJson(jsonDecode(response.body));
      }

      return null;
    } catch (e) {
      log("UPDATE DEPARTMENT ERROR: $e");
      rethrow;
    }
  }

  /// ================= DELETE =================
  /// DELETE /api/departments/{id}
  Future<bool> deleteDepartment(int id) async {
    try {
      final url = "$baseUrl/departments/$id";

      _logRequest("DELETE DEPARTMENT", url);

      final token = await _getToken();
      final response = await http.delete(
        Uri.parse(url),
        headers: _headers(token!),
      );

      _logResponse(response);

      return response.statusCode == 200;
    } catch (e) {
      log("DELETE DEPARTMENT ERROR: $e");
      log("DEPARTMENT ID: $id");
      rethrow;
    }
  }

  /// ================= SEARCH / GET ALL =================
  /// GET /api/departments
  Future<Map<String, dynamic>> searchDepartments({
    String? keyword,
    bool? active,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }
      if (active != null) {
        queryParams['active'] = active.toString();
      }

      final uri = Uri.parse("$baseUrl/departments").replace(
        queryParameters: queryParams,
      );

      _logRequest("GET DEPARTMENTS", uri.toString());

      final token = await _getToken();
      final response = await http.get(
        uri,
        headers: _headers(token!),
      );

      _logResponse(response);

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        List content = data['data'] ?? [];

        log("TOTAL DEPARTMENTS: ${data['totalElements'] ?? content.length}");

        return {
          'departments': content.map((e) => DepartmentModel.fromJson(e)).toList(),
          'totalElements': data['totalElements'] ?? content.length,
          'totalPages': data['totalPages'] ?? 1,
        };
      }

      throw Exception("Failed to load departments");
    } catch (e) {
      log("GET DEPARTMENTS ERROR: $e");
      rethrow;
    }
  }

  /// ================= GET BY ID =================
  /// GET /api/departments/findDepartment/{id}
  Future<DepartmentModel?> getDepartmentById(int id) async {
    try {
      final url = "$baseUrl/departments/findDepartment/$id";

      _logRequest("GET DEPARTMENT BY ID", url);

      final token = await _getToken();
      final response = await http.get(
        Uri.parse(url),
        headers: _headers(token!),
      );

      _logResponse(response);

      if (response.statusCode == 200) {
        return DepartmentModel.fromJson(jsonDecode(response.body));
      }

      return null;
    } catch (e) {
      log("GET DEPARTMENT BY ID ERROR: $e");
      return null;
    }
  }

  /// ================= GET MEMBERS =================
  /// GET /api/departments/{id}/members
  Future<List<Map<String, dynamic>>> getDepartmentMembers(int departmentId) async {
    try {
      final url = "$baseUrl/departments/$departmentId/members";

      _logRequest("GET DEPARTMENT MEMBERS", url);

      final token = await _getToken();
      final response = await http.get(
        Uri.parse(url),
        headers: _headers(token!),
      );

      _logResponse(response);

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }

      return [];
    } catch (e) {
      log("GET DEPARTMENT MEMBERS ERROR: $e");
      return [];
    }
  }

  /// ================= GET PROJECT MANAGERS FOR DEPARTMENT =================
  /// GET /api/departments/department/managers
  Future<Map<String, dynamic>> getProjectManagersForDepartment({
    String? keyword,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }

      final uri = Uri.parse("$baseUrl/users/department/managers").replace(
        queryParameters: queryParams,
      );

      _logRequest("GET PROJECT MANAGERS FOR DEPARTMENT", uri.toString());

      final token = await _getToken();
      final response = await http.get(
        uri,
        headers: _headers(token!),
      );

      _logResponse(response);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      throw Exception("Failed to load project managers");
    } catch (e) {
      log("GET PROJECT MANAGERS ERROR: $e");
      rethrow;
    }
  }

  /// ================= GET PROJECT MEMBERS FOR DEPARTMENT =================
  /// GET /api/departments/department/members
  Future<Map<String, dynamic>> getProjectMembersForDepartment({
    String? keyword,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }

      final uri = Uri.parse("$baseUrl/users/department/members").replace(
        queryParameters: queryParams,
      );

      _logRequest("GET PROJECT MEMBERS FOR DEPARTMENT", uri.toString());

      final token = await _getToken();
      final response = await http.get(
        uri,
        headers: _headers(token!),
      );

      _logResponse(response);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      throw Exception("Failed to load project members");
    } catch (e) {
      log("GET PROJECT MEMBERS ERROR: $e");
      rethrow;
    }
  }

  /// ================= GET DEPARTMENT BY PROJECT MANAGER ID =================
  Future<DepartmentModel?> getDepartmentByProjectManagerId(
    int projectManagerId,
  ) async {
    try {
      final result = await searchDepartments(page: 0, size: 1000);
      final departments = result['departments'] as List<DepartmentModel>;

      final matched = departments.firstWhere(
        (d) => d.projectManagerId == projectManagerId,
        orElse: () => DepartmentModel(id: 0, name: '', code: '', isActive: false),
      );
      if (matched.id != 0) {
        log(
          "Found department for projectManagerId $projectManagerId: ${matched.id} - ${matched.name}",
        );
        return matched;
      }

      log("No department found for projectManagerId: $projectManagerId");
      return null;
    } catch (e) {
      log("GET DEPARTMENT BY PROJECT MANAGER ERROR: $e");
      return null;
    }
  }

  /// ================= GET ALL (Legacy - for compatibility) =================
  Future<Map<String, dynamic>> getDepartments({
    String? keyword,
    bool? active,
    int page = 0,
    int size = 10,
  }) async {
    return searchDepartments(
      keyword: keyword,
      active: active,
      page: page,
      size: size,
    );
  }

  /// ================= GET DEPARTMENT COURSES =================
  /// GET /api/lms/courses?departmentId={id}
  Future<List<Map<String, dynamic>>> getDepartmentCourses(int departmentId) async {
    try {
      final uri = Uri.parse("$baseUrl/lms/courses").replace(
        queryParameters: {
          'departmentId': departmentId.toString(),
          'page': '0',
          'size': '100',
        },
      );

      _logRequest("GET DEPARTMENT COURSES", uri.toString());

      final token = await _getToken();
      final response = await http.get(
        uri,
        headers: _headers(token!),
      );

      _logResponse(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'] as List<dynamic>? ??
            data['data'] as List<dynamic>? ??
            data as List<dynamic>;
        return List<Map<String, dynamic>>.from(content);
      }

      return [];
    } catch (e) {
      log("GET DEPARTMENT COURSES ERROR: $e");
      return [];
    }
  }

  /// ================= GET DEPARTMENT LEARNING PATHS =================
  /// GET /api/lms/learning-paths?departmentId={id}
  Future<List<Map<String, dynamic>>> getDepartmentLearningPaths(int departmentId) async {
    try {
      final uri = Uri.parse("$baseUrl/lms/learning-paths").replace(
        queryParameters: {
          'departmentId': departmentId.toString(),
          'page': '0',
          'size': '100',
        },
      );

      _logRequest("GET DEPARTMENT LEARNING PATHS", uri.toString());

      final token = await _getToken();
      final response = await http.get(
        uri,
        headers: _headers(token!),
      );

      _logResponse(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'] as List<dynamic>? ??
            data['data'] as List<dynamic>? ??
            data as List<dynamic>;
        return List<Map<String, dynamic>>.from(content);
      }

      return [];
    } catch (e) {
      log("GET DEPARTMENT LEARNING PATHS ERROR: $e");
      return [];
    }
  }

  /// ================= ADD USERS TO DEPARTMENT (Legacy) =================
  Future<bool> addUsersToDepartment({
    required int departmentId,
    required String departmentName,
    required String departmentCode,
    required bool isActive,
    required List<int> userIds,
    int? projectManagerId,
  }) async {
    try {
      final url = "$baseUrl/departments/$departmentId";

      final body = {
        "name": departmentName,
        "code": departmentCode,
        "isActive": isActive,
        "is_active": isActive, // Fallback for snake_case
        if (userIds.isNotEmpty) "userIds": userIds,
        if (projectManagerId != null) "projectManagerId": projectManagerId,
      };

      _logRequest(
        "ADD USERS TO DEPARTMENT (via update)",
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final token = await _getToken();
      final response = await http.patch(
        Uri.parse(url),
        headers: _headers(token!),
        body: jsonEncode(body),
      );

      _logResponse(response);

      return response.statusCode == 200;
    } catch (e) {
      log("ADD USERS TO DEPARTMENT ERROR: $e");
      rethrow;
    }
  }
}
