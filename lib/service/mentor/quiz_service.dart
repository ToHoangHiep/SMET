import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smet/core/utils/quiz_csv_parser.dart';
import 'package:smet/core/utils/quiz_excel_exporter.dart';
import 'package:smet/model/learning_path_model.dart';
import 'package:smet/model/option_model.dart';
import 'package:smet/model/question_model.dart';
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

  /// Import quiz từ file CSV đã parse.
  ///
  /// Flow: (1) tạo quiz metadata → (2) tạo từng question với options.
  /// Nếu bước (2) thất bại giữa chừng, sẽ cleanup quiz đã tạo ở bước (1).
  ///
  /// Dùng [parsedData] đã được parse từ CSV bằng [QuizCsvParser.parse].
  /// Truyền [moduleId] / [courseId] để gắn quiz vào đúng ngữ cảnh.
  Future<QuizModel> importQuizFromCsv({
    required ParsedQuizData parsedData,
    Long? moduleId,
    Long? courseId,
  }) async {
    dev.log(
      '[MentorQuizService.importQuizFromCsv] START\n${parsedData.toDebugString()}',
      name: 'QuizDebug',
    );

    final quiz = QuizModel(
      title: parsedData.title,
      timeLimitMinutes: parsedData.timeLimitMinutes,
      passingScore: parsedData.passingScore,
      maxAttempts: parsedData.maxAttempts,
      questionCount: parsedData.questionCount,
      showAnswer: parsedData.showAnswer,
      moduleId: moduleId,
      courseId: courseId,
    );

    final createdQuiz = await createQuiz(quiz);
    if (createdQuiz.id == null) {
      throw Exception('Tạo quiz thất bại');
    }

    final createdQuestionIds = <Long>[];
    try {
      for (int i = 0; i < parsedData.questions.length; i++) {
        final pq = parsedData.questions[i];
        final createdQuestion = await _createQuestionFromParsed(createdQuiz.id!, pq, i);
        if (createdQuestion.id == null) {
          throw Exception('Tạo câu hỏi ${i + 1} không trả về ID');
        }
        createdQuestionIds.add(createdQuestion.id!);
      }
    } catch (e) {
      try {
        await deleteQuiz(createdQuiz.id!);
      } catch (_) {
        for (final qid in createdQuestionIds) {
          try {
            await _deleteQuestionById(qid);
          } catch (_) {}
        }
      }
      rethrow;
    }

    dev.log(
      '[MentorQuizService.importQuizFromCsv] DONE quizId=${createdQuiz.id!.value} '
      'questions=${createdQuestionIds.length}',
      name: 'QuizDebug',
    );

    return createdQuiz;
  }

  Future<QuestionModel> _createQuestionFromParsed(
    Long quizId,
    ParsedQuestion pq,
    int index,
  ) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("No auth token found. Please login again.");
    }

    final optionsJson = pq.options
        .map((o) => {
              'content': o.content,
              'isCorrect': o.isCorrect,
            })
        .toList();

    final body = {
      'quizId': quizId.value,
      'content': pq.content,
      'type': pq.type,
      'options': optionsJson,
    };

    final response = await http.post(
      Uri.parse("$baseUrl/lms/questions/with-options"),
      headers: _headers(token),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return QuestionModel(
        id: json['id'] != null ? Long(json['id']) : null,
        content: json['content'] ?? '',
        type: json['type'],
        quizId: quizId,
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
    } else {
      throw Exception("Tạo câu hỏi ${index + 1} thất bại: ${response.body}");
    }
  }

  Future<void> _deleteQuestionById(Long questionId) async {
    final token = await _getToken();
    if (token == null) return;
    try {
      await http.delete(
        Uri.parse("$baseUrl/lms/questions/${questionId.value}"),
        headers: _headers(token),
      );
    } catch (_) {}
  }

  /// Gửi file Excel đã chuyển từ ParsedQuizData lên backend để import vào quiz có sẵn.
  ///
  /// Backend endpoint: POST /api/lms/quizzes/{quizId}/import
  /// Body: multipart file Excel (.xlsx)
  Future<void> importQuizToServer(Long quizId, ParsedQuizData parsedData) async {
    dev.log(
      '[MentorQuizService.importQuizToServer] START quizId=${quizId.value} '
      'questions=${parsedData.questionCount}',
      name: 'QuizDebug',
    );

    final token = await _getToken();
    if (token == null) {
      throw Exception("No auth token found. Please login again.");
    }

    final excelBytes = QuizExcelExporter.exportToExcel(parsedData);
    final uri = Uri.parse("$baseUrl/lms/quizzes/${quizId.value}/import");

    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    // multipart request KHÔNG set Content-Type: application/json
    // http library sẽ tự set Content-Type: multipart/form-data; boundary=...
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        excelBytes,
        filename: 'quiz_import.xlsx',
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    dev.log(
      '[MentorQuizService.importQuizToServer] status=${response.statusCode} '
      'body: ${response.body}',
      name: 'QuizDebug',
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Import quiz failed: ${response.body}");
    }

    dev.log(
      '[MentorQuizService.importQuizToServer] DONE',
      name: 'QuizDebug',
    );
  }
}
