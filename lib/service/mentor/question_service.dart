import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smet/model/learning_path_model.dart';
import 'package:smet/model/question_model.dart';
import 'package:smet/service/common/base_url.dart';

class MentorQuestionService {
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

  Future<QuestionModel> createQuestion(QuestionModel question) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("No auth token found. Please login again.");
    }

    final response = await http.post(
      Uri.parse("$baseUrl/lms/questions"),
      headers: _headers(token),
      body: jsonEncode(question.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return QuestionModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Create question failed: ${response.body}");
    }
  }

  Future<QuestionModel> updateQuestion(Long questionId, QuestionModel question) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("No auth token found. Please login again.");
    }

    final response = await http.put(
      Uri.parse("$baseUrl/lms/questions/${questionId.value}"),
      headers: _headers(token),
      body: jsonEncode(question.toJson()),
    );

    if (response.statusCode == 200) {
      return QuestionModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Update question failed: ${response.body}");
    }
  }

  Future<QuestionModel> getQuestionById(Long questionId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("No auth token found. Please login again.");
    }

    final response = await http.get(
      Uri.parse("$baseUrl/lms/questions/${questionId.value}"),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      return QuestionModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Get question failed: ${response.body}");
    }
  }

  Future<List<QuestionModel>> getQuestionsByQuiz(Long quizId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("No auth token found. Please login again.");
    }

    final response = await http.get(
      Uri.parse("$baseUrl/lms/questions/quiz/${quizId.value}"),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => QuestionModel.fromJson(e)).toList();
    } else {
      throw Exception("Get questions by quiz failed: ${response.body}");
    }
  }

  Future<void> deleteQuestion(Long questionId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("No auth token found. Please login again.");
    }

    final response = await http.delete(
      Uri.parse("$baseUrl/lms/questions/${questionId.value}"),
      headers: _headers(token),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Delete question failed: ${response.body}");
    }
  }
}