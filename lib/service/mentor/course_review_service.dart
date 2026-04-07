import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/model/course_review_model.dart';
import 'package:smet/service/common/base_url.dart';

class CourseReviewService {
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

  /// Lấy danh sách học viên và kết quả quiz theo courseId
  /// Endpoint: GET /api/mentor/course-review/{courseId}
  Future<CourseReviewPageResponse> getCourseReview({
    required Long courseId,
    double? minScore,
    int page = 0,
    int size = 10,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("No auth token found. Please login again.");
    }

    final queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (minScore != null) {
      queryParams['minScore'] = minScore.toString();
    }

    final uri = Uri.parse("$baseUrl/mentor/course-review/${courseId.value}")
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: _headers(token));

    if (response.statusCode == 200) {
      return CourseReviewPageResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Lấy danh sách học viên thất bại: ${response.body}");
    }
  }
}
