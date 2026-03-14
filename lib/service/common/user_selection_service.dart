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

/// Enum mirror từ backend - dùng để xác định context khi chọn user
enum UserSelectionContext {
  /// Admin: Chọn Project Manager cho Department
  departmentProjectManager,

  /// Admin: Thêm Members vào Department (USER + MENTOR)
  departmentMembers,

  /// PM: Chọn Lead cho Project
  projectLead,

  /// PM: Thêm Mentors vào Project
  projectMentors,

  /// PM: Thêm Users vào Project
  projectMembers,
}

/// Map Flutter enum → backend string (UserSelectionContext enum name)
String toApiValue(UserSelectionContext context) {
  switch (context) {
    case UserSelectionContext.departmentProjectManager:
      return 'DEPARTMENT_PROJECT_MANAGER';
    case UserSelectionContext.departmentMembers:
      return 'DEPARTMENT_MEMBERS';
    case UserSelectionContext.projectLead:
      return 'PROJECT_LEAD';
    case UserSelectionContext.projectMentors:
      return 'PROJECT_MENTORS';
    case UserSelectionContext.projectMembers:
      return 'PROJECT_MEMBERS';
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
/// );
/// ```
Future<List<UserModel>> fetchSelectableUsers(
    UserSelectionContext context) async {
  final token = await AuthService.getToken();
  if (token == null) throw Exception("Token not found");

  log("TOKEN: $token");
  log("Fetching selectable users with context: ${toApiValue(context)}");

  final uri = Uri.parse("$baseUrl/users/selectable").replace(
    queryParameters: {'context': toApiValue(context)},
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
    final List data = jsonDecode(response.body);
    return data.map((e) => UserModel.fromJson(e)).toList();
  } else {
    throw Exception('Failed to load users: ${response.statusCode}');
  }
}
