import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:smet/model/department_model.dart';
import 'package:smet/service/common/base_url.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ← THÊM DÒNG NÀY

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

      final body = {
        "name": name,
        "code": code,
        "active": active,
        if (projectManagerId != null) "projectManagerId": projectManagerId,
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
}
