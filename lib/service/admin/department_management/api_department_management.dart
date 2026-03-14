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

  /// ================= GET ALL =================
  Future<List<DepartmentModel>> getDepartments() async {
    try {
      final url = "$baseUrl/departments/getAllDepartment";

      _logRequest("GET DEPARTMENTS", url);

      final token = await _getToken();
      final response = await http.get(
        Uri.parse(url),
        headers: _headers(token!),
      );

      _logResponse(response);

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);

        log("TOTAL DEPARTMENTS: ${data.length}");

        return data.map((e) => DepartmentModel.fromJson(e)).toList();
      }

      throw Exception("Failed to load departments");
    } catch (e) {
      log("GET DEPARTMENTS ERROR: $e");
      rethrow;
    }
  }

  /// ================= CREATE =================
  Future<DepartmentModel> createDepartment({
    required String name,
    required String code,
    required bool active,
    int? projectManagerId,
  }) async {
    try {
      final url = "$baseUrl/departments/createDepartment";

      // Lấy id người đăng nhập để gửi createdBy (backend sẽ lưu vào cột created_by)
      int? createdById;
      try {
        final me = await AuthService.getMe();
        final id = me['id'];
        if (id != null) createdById = id is int ? id : (id as num).toInt();
      } catch (_) {}

      final body = {
        "name": name,
        "code": code,
        "active": active,
        if (projectManagerId != null) "projectManagerId": projectManagerId,
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

      throw Exception("Create department failed");
    } catch (e) {
      log("CREATE DEPARTMENT ERROR: $e");
      rethrow;
    }
  }

  /// ================= UPDATE =================
  Future<DepartmentModel?> updateDepartment({
    required int id,
    required String name,
    required String code,
    required bool active,
    int? projectManagerId,
  }) async {
    try {
      final url = "$baseUrl/departments/updateDepartment/$id";

      final body = {
        "name": name,
        "code": code,
        "active": active,
        if (projectManagerId != null) "projectManagerId": projectManagerId,
      };

      _logRequest(
        "UPDATE DEPARTMENT",
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final token = await _getToken();
      final response = await http.put(
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

  /// ================= ADD USERS TO DEPARTMENT =================
  /// Dùng endpoint updateDepartment để thêm users vào department
  Future<bool> addUsersToDepartment({
    required int departmentId,
    required String departmentName,
    required String departmentCode,
    required bool active,
    required List<int> userIds,
    int? projectManagerId,
  }) async {
    try {
      // Dùng endpoint update thay vì endpoint riêng
      final url = "$baseUrl/departments/updateDepartment/$departmentId";

      final body = {
        "name": departmentName,
        "code": departmentCode,
        "active": active,
        "userIds": userIds,
        if (projectManagerId != null) "projectManagerId": projectManagerId,
      };

      _logRequest(
        "ADD USERS TO DEPARTMENT (via update)",
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final token = await _getToken();
      final response = await http.put(
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

  /// ================= GET USERS IN DEPARTMENT =================
  Future<List<Map<String, dynamic>>> getUsersInDepartment(
    int departmentId,
  ) async {
    try {
      final url = "$baseUrl/departments/$departmentId/users";

      _logRequest("GET USERS IN DEPARTMENT", url);

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
      log("GET USERS IN DEPARTMENT ERROR: $e");
      return [];
    }
  }

  /// ================= GET SELECTABLE USERS (NEW) =================
  /// Sử dụng endpoint /users/selectable?context=xxx
  /// Backend: @GetMapping("/selectable") @PreAuthorize("hasRole('ADMIN') or hasRole('PROJECT_MANAGER')")
  Future<List<Map<String, dynamic>>> getSelectableUsers({
    required String context,
  }) async {
    try {
      final url = "$baseUrl/users/selectable?context=$context";

      _logRequest("GET SELECTABLE USERS", url);

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
      log("GET SELECTABLE USERS ERROR: $e");
      return [];
    }
  }

  /// ================= GET DEPARTMENT BY PROJECT MANAGER ID =================
  /// Tìm department mà user là projectManager
  Future<DepartmentModel?> getDepartmentByProjectManagerId(
    int projectManagerId,
  ) async {
    try {
      final departments = await getDepartments();

      // Tìm department có projectManager.id = projectManagerId
      final matched = departments.firstWhere(
        (d) => d.projectManagerId == projectManagerId,
        orElse: () => DepartmentModel(id: 0, name: '', code: '', active: false),
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

  /// ================= GET DEPARTMENT MEMBERS =================
  /// Lấy danh sách thành viên của department theo API mới
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
}
