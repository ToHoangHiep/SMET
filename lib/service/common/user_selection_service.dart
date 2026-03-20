import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:smet/model/user_model.dart';
import 'package:smet/service/common/base_url.dart';
import 'package:smet/service/common/auth_service.dart';

/// Get user by ID
Future<UserModel?> getUserById(int userId) async {
  final token = await AuthService.getToken();
  if (token == null) throw Exception("Token not found");

  final response = await http.get(
    Uri.parse("$baseUrl/users/$userId"),
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return UserModel.fromJson(data);
  }
  return null;
}

/// Enum để xác định context khi chọn user - map với API mới
enum UserSelectionContext {
  /// Admin: Chọn Project Manager cho Department (lấy user có role PROJECT_MANAGER)
  departmentProjectManager,

  /// Admin: Thêm Members vào Department (lấy user có role USER + MENTOR)
  departmentMembers,

  /// PM: Chọn Lead cho Project (lấy user có role PROJECT_MANAGER)
  projectLead,

  /// PM: Thêm Mentors vào Project (lấy user có role MENTOR)
  projectMentors,

  /// PM: Thêm Users vào Project (lấy user có role USER)
  projectMembers,
}

/// Map Flutter enum → API endpoint và query params
class UserSelectionConfig {
  final String endpoint;
  final String? roleFilter;
  final bool requiresDepartmentId;

  const UserSelectionConfig({
    required this.endpoint,
    this.roleFilter,
    this.requiresDepartmentId = false,
  });
}

UserSelectionConfig _getConfig(UserSelectionContext context) {
  switch (context) {
    case UserSelectionContext.departmentProjectManager:
      // Backend: /api/users/department/managers - lấy PROJECT_MANAGER
      return const UserSelectionConfig(
        endpoint: '/users/department/managers',
        roleFilter: 'PROJECT_MANAGER',
      );
    case UserSelectionContext.departmentMembers:
      // Backend: /api/users/department/members - lấy USER và MENTOR
      return const UserSelectionConfig(
        endpoint: '/users/department/members',
        roleFilter: null,
      );
    case UserSelectionContext.projectLead:
      // Backend: /api/users/for-project với role=PROJECT_MANAGER
      return const UserSelectionConfig(
        endpoint: '/users/for-project',
        roleFilter: 'PROJECT_MANAGER',
        requiresDepartmentId: true,
      );
    case UserSelectionContext.projectMentors:
      // Backend: /api/users/for-project với role=MENTOR
      return const UserSelectionConfig(
        endpoint: '/users/for-project',
        roleFilter: 'MENTOR',
        requiresDepartmentId: true,
      );
    case UserSelectionContext.projectMembers:
      // Backend: /api/users/for-project với role=USER
      return const UserSelectionConfig(
        endpoint: '/users/for-project',
        roleFilter: 'USER',
        requiresDepartmentId: true,
      );
  }
}

/// API call lấy danh sách user có thể chọn theo context
///
/// Ví dụ sử dụng:
/// ```dart
/// // Admin: Chọn PM cho Department
/// final pmList = await fetchSelectableUsers(
///     UserSelectionContext.departmentProjectManager,
/// );
///
/// // PM: Thêm Mentors vào Project
/// final mentors = await fetchSelectableUsers(
///     UserSelectionContext.projectMentors,
///     departmentId: 1,
/// );
/// ```
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
  log("Config: endpoint=${config.endpoint}, role=${config.roleFilter}, requiresDeptId=${config.requiresDepartmentId}");

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

  // Thêm role parameter lên backend nếu có
  if (config.roleFilter != null) {
    queryParams['role'] = config.roleFilter!;
  }

  // Thêm departmentId nếu cần
  if (config.requiresDepartmentId && departmentId != null) {
    queryParams['departmentId'] = departmentId.toString();
  }

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

    // Filter role ở client nếu cần
    if (config.roleFilter != null) {
      return users.where((u) => u.role.name == config.roleFilter).toList();
    }

    // Filter cho departmentMembers: chỉ lấy MENTOR và USER
    if (context == UserSelectionContext.departmentMembers) {
      return users.where((u) =>
        u.role.name == 'MENTOR' || u.role.name == 'USER'
      ).toList();
    }

    return users;
  } else {
    throw Exception('Failed to load users: ${response.statusCode}');
  }
}
