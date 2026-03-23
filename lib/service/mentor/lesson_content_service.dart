import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smet/service/common/base_url.dart';
import 'package:smet/model/learning_path_model.dart';

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

    print("CREATE CONTENT STATUS: ${res.statusCode}");
    print("CREATE CONTENT BODY: ${res.body}");

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("Create content failed");
    }
  }
}