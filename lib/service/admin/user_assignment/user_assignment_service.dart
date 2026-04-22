import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smet/model/assignable_user_model.dart';
import 'package:smet/service/common/base_url.dart';

class UserAssignmentService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  Map<String, String> _headers(String token) {
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
      "Accept": "application/json",
    };
  }

  void _logRequest(String title, String url, {dynamic body}) {
    log("========== $title REQUEST ==========");
    log("URL: $url");
    if (body != null) log("BODY: $body");
  }

  void _logResponse(http.Response res) {
    log("STATUS: ${res.statusCode}");
    log("RESPONSE: ${res.body}");
    log("====================================");
  }

  /// GET /api/users/assignable
  /// Lay danh sach user co the gan (active=true)
  Future<AssignableUserPageResponse> getAssignableUsers({
    String? keyword,
    String? role,
    int? departmentId,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token not found");

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
      if (departmentId != null) {
        queryParams['departmentId'] = departmentId.toString();
      }
      // Backend mac dinh active=true, khong can truyen param

      final uri = Uri.parse("$baseUrl/users/assignable").replace(
        queryParameters: queryParams,
      );

      _logRequest("GET ASSIGNABLE USERS", uri.toString());

      final res = await http.get(uri, headers: _headers(token));
      _logResponse(res);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return AssignableUserPageResponse.fromJson(data as Map<String, dynamic>);
      }

      throw Exception("Get assignable users failed: HTTP ${res.statusCode}");
    } catch (e) {
      log("GET ASSIGNABLE USERS ERROR: $e");
      rethrow;
    }
  }

  Future<List<AssignableUser>> getAllAssignableUsers({
    String? keyword,
    String? role,
    int? departmentId,
  }) async {
    final allUsers = <AssignableUser>[];
    int currentPage = 0;
    const pageSize = 50;
    bool hasNext = true;

    while (hasNext) {
      final result = await getAssignableUsers(
        keyword: keyword,
        role: role,
        departmentId: departmentId,
        page: currentPage,
        size: pageSize,
      );
      allUsers.addAll(result.data);
      hasNext = result.hasNext;
      currentPage++;
    }

    return allUsers;
  }
}
