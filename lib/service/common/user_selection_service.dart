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
  final String? fixedRole;

  const UserSelectionConfig({
    required this.endpoint,
    this.requiresDepartmentId = false,
    this.fixedRole,
  });
}

UserSelectionConfig _getConfig(UserSelectionContext context) {
  switch (context) {
    case UserSelectionContext.departmentProjectManager:
      return const UserSelectionConfig(
        endpoint: '/users/department/managers',
        fixedRole: 'PROJECT_MANAGER',
      );
    case UserSelectionContext.departmentMembers:
      return const UserSelectionConfig(
        endpoint: '/users/department/members',
      );
    case UserSelectionContext.projectLead:
      return const UserSelectionConfig(
        endpoint: '/users/for-project',
        requiresDepartmentId: true,
        fixedRole: 'USER',
      );

    case UserSelectionContext.projectMentor:
      return const UserSelectionConfig(
        endpoint: '/users/for-project',
        requiresDepartmentId: true,
        fixedRole: 'MENTOR',
      );

    case UserSelectionContext.projectMembers:
      return const UserSelectionConfig(
        endpoint: '/users/for-project',
        requiresDepartmentId: true,
        fixedRole: 'USER',
      );
  }
}

Future<List<UserModel>> fetchSelectableUsers(
  UserSelectionContext context, {
  int? departmentId,
  String? keyword,
  List<int>? excludeUserIds,
  bool? assigned,
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

  // Truyen role xuong API (thay vi filter phia client)
  if (config.fixedRole != null) {
    queryParams['role'] = config.fixedRole!;
  }

  if (excludeUserIds != null && excludeUserIds.isNotEmpty) {
    queryParams['excludeUserIds'] = excludeUserIds.join(',');
  }

  // Thêm departmentId nếu cần
  if (config.requiresDepartmentId && departmentId != null) {
    queryParams['departmentId'] = departmentId.toString();
  }

  // Thêm filter assigned nếu cần (áp dụng cho department managers và department members)
  // assigned=true: chỉ user đã được assign (đã có phòng ban)
  // assigned=false: chỉ user chưa được assign (chưa có phòng ban)
  // assigned=null: lấy tất cả (để client filter)
  if (assigned != null) {
    queryParams['assigned'] = assigned.toString();
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
    final dynamic rawData = jsonDecode(response.body);

    List<dynamic> content;
    if (rawData is List) {
      content = rawData;
    } else if (rawData is Map<String, dynamic>) {
      final data = rawData;
      content = data['content'] ?? data['data'] ?? [];
    } else {
      content = [];
    }

    final users = content.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();

    // Chỉ filter inactive user phía client
    // Role đã được filter bởi backend qua tham số 'role'
    return users.where((u) => u.isActive).toList();
  } else {
    throw Exception('Failed to load users: ${response.statusCode}');
  }
}
