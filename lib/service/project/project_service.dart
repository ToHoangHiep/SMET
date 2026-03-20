import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smet/model/project_model.dart';
import 'package:smet/service/common/base_url.dart';
import 'package:smet/service/common/auth_service.dart';
import 'dart:developer';

class ProjectService {
  static String get _baseUrl => baseUrl;

  /// GET ALL PROJECTS (có phân trang, tìm kiếm, lọc theo status)
  static Future<List<ProjectModel>> getAll({
    String? keyword,
    String? status,
    int page = 0,
    int size = 10,
  }) async {
    final token = await AuthService.getToken();
    
    // Build query params
    final queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (keyword != null && keyword.isNotEmpty) {
      queryParams['keyword'] = keyword;
    }
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    
    final uri = Uri.parse("$_baseUrl/projects/get").replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    log("GET ALL PROJECTS STATUS: ${response.statusCode}");

    if (response.statusCode == 200) {
      // Backend trả về PageResponse nên cần extract content
      final Map<String, dynamic> data = jsonDecode(response.body);
      // Backend có thể trả về 'content' hoặc 'data' tùy version
      final List<dynamic> content = data['content'] ?? data['data'] ?? [];
      log("PROJECTS RESPONSE: ${response.body}");
      return content.map((json) => ProjectModel.fromJson(json)).toList();
    } else {
      throw Exception("Cannot get projects");
    }
  }

  /// GET PROJECT BY ID
  static Future<ProjectModel> getById(int id) async {
    final token = await AuthService.getToken();
    final url = Uri.parse("$_baseUrl/projects/get/$id");

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    log("GET PROJECT $id STATUS: ${response.statusCode}");

    if (response.statusCode == 200) {
      return ProjectModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Cannot get project");
    }
  }

  /// CREATE PROJECT
  static Future<ProjectModel> create({
    required String title,
    String? description,
    required int departmentId,
    required int leaderId,
    List<int>? memberIds,
    String status = 'INACTIVE',
  }) async {
    final token = await AuthService.getToken();
    final url = Uri.parse("$_baseUrl/projects/create");

    final bodyMap = {
      'title': title,
      'description': description,
      'departmentId': departmentId,
      'leaderId': leaderId,
      'status': status,
    };

    // Thêm memberIds nếu có
    if (memberIds != null && memberIds.isNotEmpty) {
      bodyMap['memberIds'] = memberIds;
    }

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(bodyMap),
    );

    log("CREATE PROJECT STATUS: ${response.statusCode}");
    log("CREATE PROJECT BODY: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return ProjectModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Cannot create project");
    }
  }

  /// UPDATE PROJECT (title, description, members)
  static Future<ProjectModel> update({
    required int id,
    required String title,
    String? description,
    required int departmentId,
    required int leaderId,
    List<int>? memberIds,
  }) async {
    final token = await AuthService.getToken();
    final url = Uri.parse("$_baseUrl/projects/update/$id");

    final bodyMap = {
      'title': title,
      'description': description,
      'departmentId': departmentId,
      'leaderId': leaderId,
    };

    // Thêm memberIds nếu có
    if (memberIds != null && memberIds.isNotEmpty) {
      bodyMap['memberIds'] = memberIds;
    }

    final response = await http.put(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(bodyMap),
    );

    log("UPDATE PROJECT STATUS: ${response.statusCode}");

    if (response.statusCode == 200) {
      return ProjectModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Cannot update project");
    }
  }

  /// DELETE PROJECT (chỉ xóa được khi status là INACTIVE)
  static Future<void> delete(int id) async {
    final token = await AuthService.getToken();
    final url = Uri.parse("$_baseUrl/projects/delete/$id");

    final response = await http.delete(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    log("DELETE PROJECT STATUS: ${response.statusCode}");
    log("DELETE PROJECT BODY: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Cannot delete project");
    }
  }

  /// UPDATE PROJECT STATUS
  static Future<ProjectModel> updateStatus(int id, String status) async {
    final token = await AuthService.getToken();
    final url = Uri.parse("$_baseUrl/projects/update/$id/status?status=$status");

    final response = await http.patch(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    log("UPDATE PROJECT STATUS STATUS: ${response.statusCode}");
    log("UPDATE PROJECT STATUS BODY: ${response.body}");

    if (response.statusCode == 200) {
      return ProjectModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Cannot update project status");
    }
  }
}
