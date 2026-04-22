import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smet/model/learning_path_model.dart';
import 'package:smet/model/quiz_model.dart';
import 'package:smet/service/common/base_url.dart';

class MentorQuizService {
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

  Future<QuizModel> createQuiz(QuizModel quiz) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("No auth token found. Please login again.");
    }

    final uri = Uri.parse("$baseUrl/lms/quizzes");
    final body = jsonEncode(quiz.toJson());
    dev.log(
      '[MentorQuizService.createQuiz] POST $uri\n'
      '  body: $body\n'
      '  (moduleId/courseId trong body quyết định quiz gắn module hay final)',
      name: 'QuizDebug',
    );

    final response = await http.post(uri, headers: _headers(token), body: body);

    dev.log(
      '[MentorQuizService.createQuiz] status=${response.statusCode}\n'
      '  body: ${response.body.length > 800 ? "${response.body.substring(0, 800)}..." : response.body}',
      name: 'QuizDebug',
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final parsed = QuizModel.fromJson(jsonDecode(response.body));
      dev.log(
        '[MentorQuizService.createQuiz] parsed id=${parsed.id?.value} '
        'moduleId=${parsed.moduleId?.value} courseId=${parsed.courseId?.value}',
        name: 'QuizDebug',
      );
      return parsed;
    } else {
      throw Exception("Create quiz failed: ${response.body}");
    }
  }

  Future<QuizModel> updateQuiz(Long quizId, QuizModel quiz) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("No auth token found. Please login again.");
    }

    final response = await http.put(
      Uri.parse("$baseUrl/lms/quizzes/${quizId.value}"),
      headers: _headers(token),
      body: jsonEncode(quiz.toJson()),
    );

    if (response.statusCode == 200) {
      return QuizModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Update quiz failed: ${response.body}");
    }
  }

  Future<QuizModel> getQuizById(Long quizId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("No auth token found. Please login again.");
    }

    final response = await http.get(
      Uri.parse("$baseUrl/lms/quizzes/${quizId.value}"),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      return QuizModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Get quiz failed: ${response.body}");
    }
  }

  Future<QuizModel> getQuizByModule(Long moduleId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("No auth token found. Please login again.");
    }

    final response = await http.get(
      Uri.parse("$baseUrl/lms/quizzes/module/${moduleId.value}"),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      return QuizModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Get module quiz failed: ${response.body}");
    }
  }

  Future<void> deleteQuiz(Long quizId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("No auth token found. Please login again.");
    }

    final response = await http.delete(
      Uri.parse("$baseUrl/lms/quizzes/${quizId.value}"),
      headers: _headers(token),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Delete quiz failed: ${response.body}");
    }
  }

  Future<void> validateQuiz(Long quizId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("No auth token found. Please login again.");
    }

    final response = await http.post(
      Uri.parse("$baseUrl/lms/quizzes/${quizId.value}/validate"),
      headers: _headers(token),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Validate quiz failed: ${response.body}");
    }
  }

  /** Lấy danh sách tất cả quiz của mentor hiện tại. */
  Future<List<QuizModel>> getMyQuizzes() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("No auth token found. Please login again.");
    }

    final response = await http.get(
      Uri.parse("$baseUrl/lms/quizzes/my"),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => QuizModel.fromJson(e)).toList();
    } else {
      throw Exception("Get my quizzes failed: ${response.body}");
    }
  }

  /** Lấy chi tiết quiz kèm câu hỏi và đáp án đúng (dùng cho edit/view). */
  Future<QuizModel> getQuizWithQuestions(Long quizId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("No auth token found. Please login again.");
    }

    final response = await http.get(
      Uri.parse("$baseUrl/lms/quizzes/${quizId.value}/with-questions"),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      return QuizModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Get quiz with questions failed: ${response.body}");
    }
  }
}
