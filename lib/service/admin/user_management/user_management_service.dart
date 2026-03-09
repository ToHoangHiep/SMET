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

  void _logResponse(http.Response res) {
    log("STATUS: ${res.statusCode}");
    log("RESPONSE: ${res.body}");
    log("====================================");
  }

  /// ================= GET USERS =================
  Future<List<UserModel>> getUsers() async {
    try {
      final token = await _getToken();
      final url = "$baseUrl/admin/listUser";

      _logRequest("GET USERS", url, headers: _headers(token!));

      final res = await http.get(Uri.parse(url), headers: _headers(token));

      _logResponse(res);

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => UserModel.fromJson(e)).toList();
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
}
