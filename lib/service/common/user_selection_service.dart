import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:smet/model/user_model.dart';
import 'package:smet/service/common/base_url.dart';
import 'package:smet/service/common/auth_service.dart';

/// Enum để xác định context khi chọn user - map với API mới
enum UserSelectionContext {
  /// Admin: Chọn Project Manager cho Department (lấy user có role PROJECT_MANAGER)
  departmentProjectManager,

  /// Admin: Thêm Members vào Department (lấy user có role USER + MENTOR)
  departmentMembers,

  /// PM: Chọn Lead cho Project (lấy user có role USER)
  projectLead,

  /// PM: Chọn Mentor cho Project (lấy user có role MENTOR)
  projectMentor,

  /// PM: Thêm Users vào Project (lấy user có role USER)
  projectMembers,
}

/// Map Flutter enum → API endpoint
class UserSelectionConfig {
  final String endpoint;
  final bool requiresDepartmentId;

  const UserSelectionConfig({
    required this.endpoint,
    this.requiresDepartmentId = false,
  });
}

UserSelectionConfig _getConfig(UserSelectionContext context) {
  switch (context) {
    case UserSelectionContext.departmentProjectManager:
      return const UserSelectionConfig(
        endpoint: '/users/department/managers',
      );
    case UserSelectionContext.departmentMembers:
      return const UserSelectionConfig(
        endpoint: '/users/department/members',
      );
    case UserSelectionContext.projectLead:
      return const UserSelectionConfig(
        endpoint: '/users/for-project',
        requiresDepartmentId: true,
      );

    case UserSelectionContext.projectMentor:
      return const UserSelectionConfig(
        endpoint: '/users/for-project',
        requiresDepartmentId: true,
      );

    case UserSelectionContext.projectMembers:
      return const UserSelectionConfig(
        endpoint: '/users/for-project',
        requiresDepartmentId: true,
      );
  }
}

Future<List<UserModel>> fetchSelectableUsers(
  UserSelectionContext context, {
  int? departmentId,
  String? keyword,
  List<int>? excludeUserIds,
  int page = 0,
  int size = 100,
}) async {
  final token = await AuthService.getToken();
  if (token == null) throw Exception("Token not found");

  final config = _getConfig(context);

  log("Fetching selectable users with context: $context");
  log("Config: endpoint=${config.endpoint}, requiresDeptId=${config.requiresDepartmentId}");

  // Build query params
  final queryParams = <String, String>{
    'page': page.toString(),
    'size': size.toString(),
  };

  if (keyword != null && keyword.isNotEmpty) {
    queryParams['keyword'] = keyword;
  }

  if (excludeUserIds != null && excludeUserIds.isNotEmpty) {
    queryParams['excludeUserIds'] = excludeUserIds.join(',');
  }

  // Thêm departmentId nếu cần
  if (config.requiresDepartmentId && departmentId != null) {
    queryParams['departmentId'] = departmentId.toString();
  }

  // NOTE: Backend /users/department/managers, /users/department/members, /users/for-project
  // KHONG ho tro param 'role'. Filter theo role se duoc thuc hien phia client.

  final uri = Uri.parse("$baseUrl${config.endpoint}").replace(
    queryParameters: queryParams,
  );

  log("URL: $uri");

  final response = await http.get(
    uri,
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );

  log("Response status: ${response.statusCode}");
  log("Response body: ${response.body}");

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = jsonDecode(response.body);

    // Backend trả về PageResponse nên cần extract content/data
    List<dynamic> content = data['content'] ?? data['data'] ?? [];

    final users = content.map((e) => UserModel.fromJson(e)).toList();

    // Filter theo role ở phía client — backend khong ho tro role param
    switch (context) {
      case UserSelectionContext.departmentProjectManager:
        return users.where((u) => u.role.name == 'PROJECT_MANAGER').toList();

      case UserSelectionContext.departmentMembers:
        return users
            .where((u) =>
                u.role.name == 'MENTOR' || u.role.name == 'USER')
            .toList();

      case UserSelectionContext.projectLead:
        return users.where((u) => u.role.name == 'USER').toList();

      case UserSelectionContext.projectMentor:
        return users.where((u) => u.role.name == 'MENTOR').toList();

      case UserSelectionContext.projectMembers:
        return users.where((u) => u.role.name == 'USER').toList();
    }
  } else {
    throw Exception('Failed to load users: ${response.statusCode}');
  }
}
