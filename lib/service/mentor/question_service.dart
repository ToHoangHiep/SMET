import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smet/model/learning_path_model.dart';
import 'package:smet/model/option_model.dart';
import 'package:smet/model/question_model.dart';
import 'package:smet/service/common/base_url.dart';

/// Service gọi QuestionController backend.
/// Backend endpoints (base: /api/lms/questions):
///   POST   /with-options          → tạo câu hỏi kèm options
///   PUT    /{id}/with-options    → cập nhật câu hỏi kèm options
///   DELETE /{id}                 → xóa câu hỏi
///   GET    /quiz/{quizId}        → lấy danh sách câu hỏi theo quiz
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

  // ================================================================
  // CREATE — POST /api/lms/questions/with-options
  // Backend: CreateQuestionWithOptionsRequest { quizId, content, type, lessonId, options[] }
  // ================================================================
  Future<QuestionModel> createQuestion(QuestionModel question) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("No auth token found. Please login again.");
    }

    if (question.quizId == null) {
      throw Exception("quizId is required to create a question.");
    }

    final optionsJson = (question.options ?? [])
        .map((o) => {
              'content': o.content,
              'isCorrect': o.isCorrect,
            })
        .toList();

    final body = {
      'quizId': question.quizId!.value,
      'content': question.content,
      'type': question.type ?? 'SINGLE_CHOICE',
      if (question.lessonId != null) 'lessonId': question.lessonId!.value,
      'options': optionsJson,
    };

    final response = await http.post(
      Uri.parse("$baseUrl/lms/questions/with-options"),
      headers: _headers(token),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return _parseQuestionResponse(response.body);
    } else {
      throw Exception("Create question failed: ${response.body}");
    }
  }

  // ================================================================
  // UPDATE — PUT /api/lms/questions/{id}/with-options
  // Backend: UpdateQuestionWithOptionsRequest { content, type, lessonId, options[] }
  // options[].id = null → tạo mới, options[].id = giá trị → cập nhật
  // ================================================================
  Future<QuestionModel> updateQuestion(Long questionId, QuestionModel question) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("No auth token found. Please login again.");
    }

    final optionsJson = (question.options ?? [])
        .map((o) => {
              if (o.id != null) 'id': o.id!.value,
              'content': o.content,
              'isCorrect': o.isCorrect,
            })
        .toList();

    final body = {
      'content': question.content,
      'type': question.type ?? 'SINGLE_CHOICE',
      if (question.lessonId != null) 'lessonId': question.lessonId!.value,
      'options': optionsJson,
    };

    final response = await http.put(
      Uri.parse("$baseUrl/lms/questions/${questionId.value}/with-options"),
      headers: _headers(token),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return _parseQuestionResponse(response.body);
    } else {
      throw Exception("Update question failed: ${response.body}");
    }
  }

  // ================================================================
  // GET BY QUIZ — GET /api/lms/questions/quiz/{quizId}
  // Backend: List<QuestionResponse> { id, content, type, lessonId, options[] }
  // ================================================================
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
      return data.map((e) => _parseQuestionResponse(e)).toList();
    } else {
      throw Exception("Get questions by quiz failed: ${response.body}");
    }
  }

  // ================================================================
  // DELETE — DELETE /api/lms/questions/{id}
  // ================================================================
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

  // ================================================================
  // PARSE — QuestionResponse { id, content, type, lessonId, options[] }
  // ================================================================
  QuestionModel _parseQuestionResponse(dynamic data) {
    final Map<String, dynamic> json;
    if (data is String) {
      json = jsonDecode(data);
    } else {
      json = data as Map<String, dynamic>;
    }

    return QuestionModel(
      id: json['id'] != null ? Long(json['id']) : null,
      content: json['content'] ?? '',
      lessonId: json['lessonId'] != null
          ? Long(json['lessonId'])
          : (json['lesson_id'] != null ? Long(json['lesson_id']) : null),
      type: json['type'],
      quizId: json['quizId'] != null
          ? Long(json['quizId'])
          : (json['quiz_id'] != null ? Long(json['quiz_id']) : null),
      options: json['options'] != null
          ? (json['options'] as List)
              .map((o) => OptionModel(
                    id: o['id'] != null ? Long(o['id']) : null,
                    content: o['content'] ?? '',
                    isCorrect: o['isCorrect'] ?? false,
                  ))
              .toList()
          : null,
    );
  }
}
