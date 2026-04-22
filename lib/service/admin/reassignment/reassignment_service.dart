import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/model/user_model.dart';
import 'package:smet/model/bulk_assign_result_model.dart';
import 'package:smet/model/reassignment_error_model.dart';
import 'package:smet/service/common/base_url.dart';

class ReassignmentService {
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
  void _logRequest(String title, String url, {Map<String, String>? headers, dynamic body}) {
    log("========== $title REQUEST ==========");
    log("URL: $url");
    if (headers != null) log("HEADERS: $headers");
    if (body != null) log("BODY: $body");
  }

  void _logResponse(http.Response res, [String? title]) {
    log("STATUS: ${res.statusCode}");
    log("RESPONSE: ${res.body}");
    log("====================================");
  }

  /// listUser / page API: object có `data` hoặc `content`; một số API trả mảng trực tiếp.
  List<dynamic> _parseListFromAdminBody(dynamic decoded) {
    if (decoded is List<dynamic>) return decoded;
    if (decoded is Map<String, dynamic>) {
      final raw = decoded['data'] ?? decoded['content'];
      if (raw is List<dynamic>) return raw;
    }
    return [];
  }

  /// =================
  /// 1. Thử đổi phòng ban cho mentor
  /// Nếu thành công (200) → return null
  /// Nếu bị chặn (4xx) → parse lỗi, trả ReassignmentError
  /// =================
  Future<ReassignmentError?> tryChangeDepartment({
    required int userId,
    required int newDepartmentId,
    required String mentorName,
    UserModel? mentor,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception("Token not found");

    final url = "$baseUrl/admin/users/$userId";

    // Xây dựng body - gửi đầy đủ fields nếu có mentor, chỉ departmentId nếu không
    final Map<String, dynamic> bodyData = {
      "departmentId": newDepartmentId,
    };

    // Nếu có mentor info từ frontend, gửi kèm các trường bắt buộc
    if (mentor != null) {
      bodyData['firstName'] = mentor.firstName;
      bodyData['lastName'] = mentor.lastName;
      bodyData['email'] = mentor.email;
      bodyData['phone'] = mentor.phone;
      bodyData['role'] = mentor.role.name;
    }

    final body = jsonEncode(bodyData);

    _logRequest("TRY_CHANGE_DEPARTMENT", url, headers: _headers(token), body: body);

    try {
      final res = await http.put(
        Uri.parse(url),
        headers: _headers(token),
        body: body,
      );

      _logResponse(res, "TRY_CHANGE_DEPARTMENT");

      if (res.statusCode == 200) {
        return null; // Thành công, không có lỗi
      }

      // Parse error message
      String message = "Đã xảy ra lỗi";
      try {
        final bodyJson = jsonDecode(res.body);
        message = (bodyJson['message'] ?? bodyJson['error'] ?? message).toString();
      } catch (_) {
        message = res.body.isNotEmpty ? res.body : message;
      }

      // Kiểm tra có phải lỗi liên quan đến khóa học
      if (message.contains('khóa học') || message.contains('course')) {
        return ReassignmentError.fromMessage(message, userId, mentorName);
      }

      throw Exception(message);
    } on http.ClientException catch (e) {
      throw Exception("Network error: $e");
    }
  }

  /// =================
  /// 2. Lấy danh sách khóa học của một mentor (phục vụ hiển thị khi bị chặn)
  /// Dùng lại API list course với mentorId (tương đương isMine của mentor đó)
  /// =================
  Future<List<CourseModel>> getCoursesByMentor(int mentorId) async {
    final token = await _getToken();
    if (token == null) throw Exception("Token not found");

    final queryParams = {
      'mentorId': mentorId.toString(),
      'page': '0',
      'size': '100',
    };

    final uri = Uri.parse("$baseUrl/lms/courses").replace(queryParameters: queryParams);

    _logRequest("GET_COURSES_BY_MENTOR", uri.toString(), headers: _headers(token));

    try {
      final res = await http.get(uri, headers: _headers(token));

      _logResponse(res, "GET_COURSES_BY_MENTOR");

      if (res.statusCode == 200) {
        final bodyJson = jsonDecode(res.body);
        final List<dynamic> rawList = bodyJson['data'] ?? bodyJson['content'] ?? [];
        return rawList
            .map((e) => CourseModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      throw Exception("Failed to load courses: ${res.body}");
    } on http.ClientException catch (e) {
      throw Exception("Network error: $e");
    }
  }

  /// =================
  /// 3. Lấy danh sách mentor cùng phòng ban (trừ mentor hiện tại)
  /// =================
  Future<List<UserModel>> getMentorsByDepartment({
    required int departmentId,
    int? excludeUserId,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception("Token not found");

    final queryParams = <String, String>{
      'role': 'MENTOR',
      'departmentId': departmentId.toString(),
      'isActive': 'true',
      'size': '100',
    };

    if (excludeUserId != null) {
      // Backend không hỗ trợ excludeUserIds trên listUser, nên filter ở FE
    }

    final uri = Uri.parse("$baseUrl/admin/listUser").replace(queryParameters: queryParams);

    _logRequest("GET_MENTORS_BY_DEPARTMENT", uri.toString(), headers: _headers(token));

    try {
      final res = await http.get(uri, headers: _headers(token));

      _logResponse(res, "GET_MENTORS_BY_DEPARTMENT");

      if (res.statusCode == 200) {
        final bodyJson = jsonDecode(res.body);
        // Backend trả PageResponse: { "data": [...], "page", ... } — không phải mảng gốc.
        final List<dynamic> rawList = _parseListFromAdminBody(bodyJson);
        final users = rawList
            .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
            .toList();

        // Filter out the current mentor (can't reassign to themselves)
        if (excludeUserId != null) {
          return users.where((u) => u.id != excludeUserId).toList();
        }
        return users;
      }

      throw Exception("Failed to load mentors: ${res.body}");
    } on http.ClientException catch (e) {
      throw Exception("Network error: $e");
    }
  }

  /// =================
  /// 4. Preview bulk change mentor
  /// =================
  Future<List<BulkAssignResultModel>> previewBulkChange({
    required List<int> courseIds,
    required int newMentorId,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception("Token not found");

    final uri = Uri.parse("$baseUrl/lms/courses/bulk-change-mentor-preview")
        .replace(queryParameters: {
          'mentorId': newMentorId.toString(),
          'courseIds': courseIds.map((id) => id.toString()).toList(),
        });

    _logRequest("PREVIEW_BULK_CHANGE", uri.toString(), headers: _headers(token));

    try {
      final res = await http.get(uri, headers: _headers(token));

      _logResponse(res, "PREVIEW_BULK_CHANGE");

      if (res.statusCode == 200) {
        final List<dynamic> rawList = jsonDecode(res.body) as List<dynamic>;
        return rawList
            .map((e) => BulkAssignResultModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      throw Exception("Preview failed: ${res.body}");
    } on http.ClientException catch (e) {
      throw Exception("Network error: $e");
    }
  }

  /// =================
  /// 5. Apply bulk change mentor (thực hiện reassign)
  /// =================
  Future<List<BulkAssignResultModel>> applyBulkChange({
    required List<int> courseIds,
    required int newMentorId,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception("Token not found");

    final uri = Uri.parse("$baseUrl/lms/courses/bulk-change-mentor-safe")
        .replace(queryParameters: {
          'mentorId': newMentorId.toString(),
          'courseIds': courseIds.map((id) => id.toString()).toList(),
        });

    _logRequest("APPLY_BULK_CHANGE", uri.toString(), headers: _headers(token));

    try {
      final res = await http.put(uri, headers: _headers(token));

      _logResponse(res, "APPLY_BULK_CHANGE");

      if (res.statusCode == 200) {
        final List<dynamic> rawList = jsonDecode(res.body) as List<dynamic>;
        return rawList
            .map((e) => BulkAssignResultModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      throw Exception("Bulk reassign failed: ${res.body}");
    } on http.ClientException catch (e) {
      throw Exception("Network error: $e");
    }
  }
}
