import 'dart:convert';
import 'dart:developer';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smet/model/user_model.dart';
import 'package:smet/service/common/base_url.dart';

class UserManagementApi {
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

  void _logResponse(http.Response res, {bool logBody = true}) {
    log("STATUS: ${res.statusCode}");
    if (logBody) {
      log("RESPONSE: ${res.body}");
    } else {
      log("RESPONSE: <binary> ${res.bodyBytes.length} bytes (không log nội dung file)");
    }
    log("====================================");
  }

  /// Parse int từ response (backend có thể trả int, double, hoặc string).
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// ================= GET USERS =================
  /// Backend hỗ trợ: pagination, search, filter (keyword, role, isActive, departmentId)
  Future<Map<String, dynamic>> getUsers({
    int page = 0,
    int size = 10,
    String? keyword,
    String? role,
    bool? isActive,
    int? departmentId,
  }) async {
    try {
      final token = await _getToken();
      
      // Build query params
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }
      if (role != null && role.isNotEmpty && role != 'ALL') {
        queryParams['role'] = role;
      }
      if (isActive != null) {
        queryParams['isActive'] = isActive.toString();
      }
      if (departmentId != null) {
        queryParams['departmentId'] = departmentId.toString();
      }
      
      final uri = Uri.parse("$baseUrl/admin/listUser").replace(queryParameters: queryParams);

      _logRequest("GET USERS", uri.toString(), headers: _headers(token!));

      final res = await http.get(uri, headers: _headers(token));

      _logResponse(res);

      if (res.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(res.body);
        final List<dynamic> data = responseData['data'] ?? [];
        // Parse số từ backend (có thể là int/double/string)
        final totalElements = _parseInt(responseData['totalElements']) ?? 0;
        final totalPages = _parseInt(responseData['totalPages']) ?? 0;
        final page = _parseInt(responseData['page']) ?? 0;
        final size = _parseInt(responseData['size']) ?? 10;

        return {
          'users': data.map((e) => UserModel.fromJson(e)).toList(),
          'page': page,
          'size': size,
          'totalElements': totalElements,
          'totalPages': totalPages,
        };
      }

      throw Exception("Get users failed");
    } catch (e) {
      log("GET USERS ERROR: $e");
      rethrow;
    }
  }

  /// ================= UPDATE USER =================
  Future<void> updateUser(UserModel user, {int? departmentId}) async {
    try {
      final token = await _getToken();
      final url = "$baseUrl/admin/users/${user.id}";

      final body = {
        "firstName": user.firstName,
        "lastName": user.lastName,
        "email": user.email,
        "phone": user.phone,
        "role": user.role.name.toUpperCase(),
        "isActive": user.isActive,
      };

      // Thêm departmentId nếu có
      if (departmentId != null) {
        body["departmentId"] = departmentId;
      }

      _logRequest(
        "UPDATE USER",
        url,
        headers: _headers(token!),
        body: jsonEncode(body),
      );

      final res = await http.put(
        Uri.parse(url),
        headers: _headers(token),
        body: jsonEncode(body),
      );

      _logResponse(res);

      if (res.statusCode != 200) {
        throw Exception("Update user failed");
      }
    } catch (e) {
      log("UPDATE USER ERROR: $e");
      rethrow;
    }
  }

  /// ================= TOGGLE ACTIVE =================
  Future<void> toggleUserActive(int id) async {
    if (id == 0) {
      log("ERROR: USER ID IS INVALID");
      throw Exception("User id is invalid");
    }

    try {
      final token = await _getToken();
      final url = "$baseUrl/admin/toggleUserActive/$id";

      _logRequest("TOGGLE USER ACTIVE", url, headers: _headers(token!));

      final res = await http.put(Uri.parse(url), headers: _headers(token));

      _logResponse(res);

      if (res.statusCode != 200) {
        throw Exception("Toggle active failed");
      }
    } catch (e) {
      log("TOGGLE ACTIVE ERROR: $e");
      log("USER ID: $id");
      rethrow;
    }
  }

  /// ================= IMPORT EXCEL =================
  Future<void> importExcelFile(PlatformFile file) async {
    try {
      final token = await _getToken();
      final url = "$baseUrl/admin/import";

      log("========== IMPORT EXCEL REQUEST ==========");
      log("URL: $url");
      log("FILE NAME: ${file.name}");

      final request = http.MultipartRequest("POST", Uri.parse(url));

      request.headers["Authorization"] = "Bearer $token";

      request.files.add(
        http.MultipartFile.fromBytes("file", file.bytes!, filename: file.name),
      );

      final res = await request.send();
      final body = await res.stream.bytesToString();

      log("STATUS: ${res.statusCode}");
      log("BODY: $body");
      log("STATUS: ${res.statusCode}");
      log("==========================================");

      if (res.statusCode != 200) {
        throw Exception("Import excel failed");
      }
    } catch (e) {
      log("IMPORT EXCEL ERROR: $e");
      rethrow;
    }
  }

  /// ================= DOWNLOAD TEMPLATE =================
  Future<http.Response> downloadTemplate() async {
    final token = await _getToken();
    final url = "$baseUrl/admin/import/template";

    _logRequest("DOWNLOAD TEMPLATE", url, headers: _headers(token!));

    final res = await http.get(
      Uri.parse(url),
      headers: _headers(token),
    );

    _logResponse(res, logBody: false);

    if (res.statusCode != 200) {
      throw Exception("Download template failed");
    }

    return res;
  }

  /// ================= CREATE USER =================
  Future<void> createUser(Map<String, dynamic> body) async {
    try {
      final token = await _getToken();
      final url = "$baseUrl/auth/register";

      _logRequest(
        "CREATE USER",
        url,
        headers: _headers(token!),
        body: jsonEncode(body),
      );

      final res = await http.post(
        Uri.parse(url),
        headers: _headers(token),
        body: jsonEncode(body),
      );

      _logResponse(res);

      if (res.statusCode != 200) {
        throw Exception("Create user failed: ${res.body}");
      }
    } catch (e) {
      log("CREATE USER ERROR: $e");
      rethrow;
    }
  }

  /// ================= FIND USERS FOR DEPARTMENT =================
  /// Backend: GET /api/admin/listUser?keyword=&role=&page=0&size=10
  /// Dùng để lấy danh sách user theo department có phân trang
  Future<Map<String, dynamic>> findUsersForDepartment({
    String? keyword,
    String? role,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final token = await _getToken();

      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }
      if (role != null && role.isNotEmpty) {
        queryParams['role'] = role;
      }

      final uri = Uri.parse("$baseUrl/admin/listUser").replace(queryParameters: queryParams);

      _logRequest("FIND USERS FOR DEPARTMENT", uri.toString(), headers: _headers(token!));

      final res = await http.get(uri, headers: _headers(token));

      _logResponse(res);

      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        final List<dynamic> content = data['content'] ?? data['data'] ?? [];

        return {
          'users': content.map((e) => UserModel.fromJson(e)).toList(),
          'page': data['page'] ?? page,
          'size': data['size'] ?? size,
          'totalElements': data['totalElements'] ?? 0,
          'totalPages': data['totalPages'] ?? 0,
        };
      }

      throw Exception("Find users for department failed");
    } catch (e) {
      log("FIND USERS FOR DEPARTMENT ERROR: $e");
      rethrow;
    }
  }

  /// ================= FIND USERS FOR DEPARTMENT ASSIGN =================
  /// Backend: GET /api/admin/listUser?keyword=&role=&page=0&size=10
  /// Dùng để assign user vào department
  Future<Map<String, dynamic>> findUsersForDepartmentAssign({
    String? keyword,
    String? role,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final token = await _getToken();

      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }
      if (role != null && role.isNotEmpty) {
        queryParams['role'] = role;
      }

      final uri = Uri.parse("$baseUrl/admin/listUser").replace(queryParameters: queryParams);

      _logRequest("FIND USERS FOR DEPARTMENT ASSIGN", uri.toString(), headers: _headers(token!));

      final res = await http.get(uri, headers: _headers(token));

      _logResponse(res);

      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        final List<dynamic> content = data['content'] ?? data['data'] ?? [];

        return {
          'users': content.map((e) => UserModel.fromJson(e)).toList(),
          'page': data['page'] ?? page,
          'size': data['size'] ?? size,
          'totalElements': data['totalElements'] ?? 0,
          'totalPages': data['totalPages'] ?? 0,
        };
      }

      throw Exception("Find users for department assign failed");
    } catch (e) {
      log("FIND USERS FOR DEPARTMENT ASSIGN ERROR: $e");
      rethrow;
    }
  }
}
