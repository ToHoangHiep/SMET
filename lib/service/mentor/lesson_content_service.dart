import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smet/service/common/base_url.dart';

class LessonContentService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  Future<void> createContent(int lessonId, Map<String, dynamic> body) async {
    final token = await _getToken();

    final url = "$baseUrl/lms/lessons/$lessonId/contents";

    final res = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );

    print("CREATE CONTENT URL: $url");
    print("CREATE CONTENT BODY: ${jsonEncode(body)}");
    print("CREATE CONTENT STATUS: ${res.statusCode}");
    print("CREATE CONTENT RESPONSE: ${res.body}");

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("Create content failed: ${res.body}");
    }
  }

  Future<void> updateContent(
    int lessonId,
    int contentId,
    Map<String, dynamic> body,
  ) async {
    final token = await _getToken();

    final url = "$baseUrl/lms/lessons/$lessonId/contents/$contentId";

    final res = await http.put(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );

    print("UPDATE CONTENT URL: $url");
    print("UPDATE CONTENT BODY: ${jsonEncode(body)}");
    print("UPDATE CONTENT STATUS: ${res.statusCode}");
    print("UPDATE CONTENT RESPONSE: ${res.body}");

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("Update content failed: ${res.body}");
    }
  }
}
