import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smet/model/project_member_model.dart';
import 'package:smet/service/common/base_url.dart';
import 'package:smet/service/common/auth_service.dart';
import 'dart:developer';

class ProjectMemberService {
  static String get _baseUrl => baseUrl;

  /// GET MEMBERS BY PROJECT
  static Future<List<ProjectMemberModel>> getByProject(int projectId) async {
    final token = await AuthService.getToken();
    final url = Uri.parse("$_baseUrl/project-members/findProject/$projectId");

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    log("GET MEMBERS BY PROJECT $projectId STATUS: ${response.statusCode}");

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ProjectMemberModel.fromJson(json)).toList();
    } else {
      throw Exception("Cannot get project members");
    }
  }

  /// ADD MEMBER TO PROJECT
  static Future<ProjectMemberModel> addMember({
    required int projectId,
    required int userId,
    required String role,
  }) async {
    final token = await AuthService.getToken();
    final url = Uri.parse("$_baseUrl/project-members/addProjectMember");

    final bodyJson = {
      'projectId': projectId,
      'userId': userId,
      'role': role,
    };

    log("========== ADD MEMBER TO PROJECT ==========");
    log("URL: $url");
    log("TOKEN: ${token?.substring(0, 20)}...");
    log("BODY: $bodyJson");

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(bodyJson),
    );

    log("ADD MEMBER STATUS: ${response.statusCode}");
    log("ADD MEMBER RESPONSE: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return ProjectMemberModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Cannot add project member");
    }
  }

  /// UPDATE MEMBER
  static Future<ProjectMemberModel> updateMember({
    required int id,
    required int userId,
    required String role,
  }) async {
    final token = await AuthService.getToken();
    final url = Uri.parse("$_baseUrl/project-members/updateProjectMember/$id");

    final response = await http.put(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        'userId': userId,
        'role': role,
      }),
    );

    log("UPDATE MEMBER STATUS: ${response.statusCode}");

    if (response.statusCode == 200) {
      return ProjectMemberModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Cannot update project member");
    }
  }

  /// DELETE MEMBER
  static Future<void> deleteMember(int id) async {
    final token = await AuthService.getToken();
    final url = Uri.parse("$_baseUrl/project-members/$id");

    final response = await http.delete(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    log("DELETE MEMBER STATUS: ${response.statusCode}");

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Cannot delete project member");
    }
  }

  /// REMOVE MEMBER FROM PROJECT by userId
  static Future<void> removeMember({
    required int projectId,
    required int userId,
  }) async {
    // First get all members of this project
    final members = await getByProject(projectId);
    
    // Find the member with matching userId
    final memberToRemove = members.where((m) => m.userId == userId).firstOrNull;
    
    if (memberToRemove != null) {
      await deleteMember(memberToRemove.id);
    }
  }

  /// GET PROJECT WITH MEMBERS (returns single Map)
  static Future<Map<String, dynamic>> getProjectWithMembers(int projectId) async {
    final token = await AuthService.getToken();
    final url = Uri.parse("$_baseUrl/project-members/findProject/$projectId");

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    log("GET PROJECT WITH MEMBERS $projectId STATUS: ${response.statusCode}");
    log("GET PROJECT WITH MEMBERS RESPONSE: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      
      // Xử lý khi response là Array (có thể empty hoặc có phần tử)
      if (decoded is List) {
        if (decoded.isEmpty) {
          return {}; // Trả về empty map nếu không có data
        }
        // Nếu là array với 1 phần tử, lấy phần tử đầu tiên
        if (decoded.first is Map) {
          return Map<String, dynamic>.from(decoded.first);
        }
      }
      
      // Xử lý khi response là Map
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      
      return {};
    } else {
      throw Exception("Cannot get project members");
    }
  }

  /// GET MEMBERS BY PROJECT (returns List<Map>) - Legacy
  static Future<List<Map<String, dynamic>>> getMembers(int projectId) async {
    final token = await AuthService.getToken();
    final url = Uri.parse("$_baseUrl/project-members/findProject/$projectId");

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    log("GET MEMBERS $projectId STATUS: ${response.statusCode}");

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception("Cannot get project members");
    }
  }

  /// ADD MULTIPLE MEMBERS
  static Future<List<ProjectMemberModel>> addMultipleMembers({
    required int projectId,
    required List<Map<String, dynamic>> members,
  }) async {
    final List<ProjectMemberModel> results = [];

    for (final member in members) {
      try {
        final result = await addMember(
          projectId: projectId,
          userId: member['userId'],
          role: member['role'],
        );
        results.add(result);
      } catch (e) {
        log("Error adding member: $e");
      }
    }

    return results;
  }

  /// GET USERS FOR PROJECT (NEW API)
  /// Endpoint: /api/users/for-project?departmentId=xxx&keyword=xxx&excludeUserIds=xxx&page=0&size=100
  static Future<List<Map<String, dynamic>>> getUsersForProject({
    required int departmentId,
    String? keyword,
    List<int>? excludeUserIds,
    int page = 0,
    int size = 100,
  }) async {
    final result = await getUsersForProjectPaginated(
      departmentId: departmentId,
      keyword: keyword,
      excludeUserIds: excludeUserIds,
      page: page,
      size: size,
    );
    return result['users'] as List<Map<String, dynamic>>;
  }

  /// GET USERS FOR PROJECT với phân trang (trả về đủ thông tin page/total)
  /// Dùng cho UI "Chọn thành viên" có search + pagination
  static Future<Map<String, dynamic>> getUsersForProjectPaginated({
    required int departmentId,
    String? keyword,
    List<int>? excludeUserIds,
    String? role, // Filter by role: ADMIN, PROJECT_MANAGER, MENTOR, USER
    int page = 0,
    int size = 10,
  }) async {
    try {
      final token = await AuthService.getToken();
      final queryParams = <String, String>{
        'departmentId': departmentId.toString(),
        'page': page.toString(),
        'size': size.toString(),
      };
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }
      if (excludeUserIds != null && excludeUserIds.isNotEmpty) {
        queryParams['excludeUserIds'] = excludeUserIds.join(',');
      }
      if (role != null && role.isNotEmpty) {
        queryParams['role'] = role;
      }
      final uri = Uri.parse("$baseUrl/users/for-project").replace(queryParameters: queryParams);

      log("========== GET USERS FOR PROJECT (PAGINATED) ==========");
      log("URL: $uri");

      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      log("GET USERS FOR PROJECT STATUS: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map) {
          return {'users': <Map<String, dynamic>>[], 'page': 0, 'size': size, 'totalElements': 0, 'totalPages': 0};
        }
        final usersList = decoded['content'] ?? decoded['data'];
        final list = usersList != null ? List<Map<String, dynamic>>.from(usersList) : <Map<String, dynamic>>[];
        return {
          'users': list,
          'page': decoded['page'] ?? page,
          'size': decoded['size'] ?? size,
          'totalElements': decoded['totalElements'] ?? 0,
          'totalPages': decoded['totalPages'] ?? 0,
        };
      }
      return {'users': <Map<String, dynamic>>[], 'page': 0, 'size': size, 'totalElements': 0, 'totalPages': 0};
    } catch (e) {
      log("GET USERS FOR PROJECT ERROR: $e");
      return {'users': <Map<String, dynamic>>[], 'page': 0, 'size': 10, 'totalElements': 0, 'totalPages': 0};
    }
  }

  /// Legacy: GET SELECTABLE USERS (giữ lại để tương thích ngược nếu cần)
  @Deprecated('Use getUsersForProject instead')
  static Future<List<Map<String, dynamic>>> getSelectableUsers({
    required String context,
  }) async {
    return getUsersForProject(
      departmentId: 1, // Sẽ được cập nhật sau
      keyword: null,
    );
  }
}
