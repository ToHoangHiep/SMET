import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smet/model/project_model.dart';
import 'package:smet/service/common/base_url.dart';
import 'package:smet/service/common/auth_service.dart';
import 'dart:developer';

class ProjectService {
  static String get _baseUrl => baseUrl;

  /// GET ALL PROJECTS
  static Future<List<ProjectModel>> getAll() async {
    final token = await AuthService.getToken();
    final url = Uri.parse("$_baseUrl/projects/listProject");

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    log("GET ALL PROJECTS STATUS: ${response.statusCode}");

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ProjectModel.fromJson(json)).toList();
    } else {
      throw Exception("Cannot get projects");
    }
  }

  /// GET PROJECT BY ID
  static Future<ProjectModel> getById(int id) async {
    final token = await AuthService.getToken();
    final url = Uri.parse("$_baseUrl/projects/findProject/$id");

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
    String status = 'DRAFT',
    int? userId,
  }) async {
    final token = await AuthService.getToken();
    final url = Uri.parse("$_baseUrl/projects/createProject");

    final bodyMap = {
      'title': title,
      'description': description,
      'departmentId': departmentId,
      'status': status,
    };

    // Thêm createdBy nếu có (để set người tạo project)
    if (userId != null) {
      bodyMap['createdBy'] = userId;
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

  /// UPDATE PROJECT
  static Future<ProjectModel> update({
    required int id,
    required String title,
    String? description,
    required int departmentId,
    String status = 'DRAFT',
  }) async {
    final token = await AuthService.getToken();
    final url = Uri.parse("$_baseUrl/projects/updateProject/$id");

    final response = await http.put(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'departmentId': departmentId,
        'status': status,
      }),
    );

    log("UPDATE PROJECT STATUS: ${response.statusCode}");

    if (response.statusCode == 200) {
      return ProjectModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Cannot update project");
    }
  }

  /// DELETE PROJECT
  static Future<void> delete(int id) async {
    final token = await AuthService.getToken();
    final url = Uri.parse("$_baseUrl/projects/$id");

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
    final url = Uri.parse("$_baseUrl/projects/$id/status");

    final response = await http.patch(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        'status': status,
      }),
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
