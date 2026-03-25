import 'dart:convert';
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

    final response = await http.post(
      Uri.parse("$baseUrl/lms/quizzes"),
      headers: _headers(token),
      body: jsonEncode(quiz.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return QuizModel.fromJson(jsonDecode(response.body));
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

  Future<QuizModel> getFinalQuizByCourse(Long courseId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("No auth token found. Please login again.");
    }

    final response = await http.get(
      Uri.parse("$baseUrl/lms/quizzes/course/${courseId.value}/final"),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      return QuizModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Get final quiz failed: ${response.body}");
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
}