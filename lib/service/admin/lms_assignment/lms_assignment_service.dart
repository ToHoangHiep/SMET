import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smet/model/assignment_result_model.dart';
import 'package:smet/service/common/base_url.dart';

class LmsAssignmentService {
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

  String _formatDate(DateTime date) {
    return date.toIso8601String();
  }

  /// POST /api/lms/enrollments/assign
  /// Gan course cho nhieu user
  Future<AssignmentResult> assignCourses({
    required List<int> userIds,
    required List<int> courseIds,
    Long? projectId,
    DateTime? dueDate,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token not found");

      final url = "$baseUrl/lms/enrollments/assign";
      final body = <String, dynamic>{
        'userIds': userIds,
        'courseIds': courseIds,
      };
      if (projectId != null) body['projectId'] = projectId.value;
      if (dueDate != null) body['dueDate'] = _formatDate(dueDate);

      _logRequest("ASSIGN COURSES", url, body: body);

      final res = await http.post(
        Uri.parse(url),
        headers: _headers(token),
        body: jsonEncode(body),
      );
      _logResponse(res);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return AssignmentResult.fromJson(data as Map<String, dynamic>);
      }

      throw Exception("Assign courses failed: HTTP ${res.statusCode} - ${res.body}");
    } catch (e) {
      log("ASSIGN COURSES ERROR: $e");
      rethrow;
    }
  }

  /// POST /api/lms/learning-paths/assign
  /// Gan learning path cho nhieu user
  Future<AssignmentResult> assignLearningPaths({
    required List<int> userIds,
    required List<int> learningPathIds,
    Long? projectId,
    DateTime? dueDate,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token not found");

      final url = "$baseUrl/lms/learning-paths/assign";
      final body = <String, dynamic>{
        'userIds': userIds,
        'learningPathIds': learningPathIds,
      };
      if (projectId != null) body['projectId'] = projectId.value;
      if (dueDate != null) body['dueDate'] = _formatDate(dueDate);

      _logRequest("ASSIGN LEARNING PATHS", url, body: body);

      final res = await http.post(
        Uri.parse(url),
        headers: _headers(token),
        body: jsonEncode(body),
      );
      _logResponse(res);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return AssignmentResult.fromJson(data as Map<String, dynamic>);
      }

      throw Exception("Assign learning paths failed: HTTP ${res.statusCode} - ${res.body}");
    } catch (e) {
      log("ASSIGN LEARNING PATHS ERROR: $e");
      rethrow;
    }
  }
}

/// Wrapper cho so nguyen (vì JS ko co Long)
class Long {
  final int value;
  Long(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Long && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value.toString();
}
