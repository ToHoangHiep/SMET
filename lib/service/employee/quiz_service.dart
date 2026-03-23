import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smet/model/quiz_model.dart';
import 'package:smet/service/common/base_url.dart';
import 'package:smet/service/common/auth_service.dart';
import 'dart:developer';

// ============================================================
// QUIZ SERVICE
//
// API Flow:
//  1. startAttempt(quizId)  → tạo attempt, trả attemptId
//  2. getAttemptQuestions(id) → lấy câu hỏi (sau khi start)
//  3. saveAnswer(attemptId, questionId, optionIds) → lưu đáp án
//  4. submitAttempt(attemptId) → nộp bài, trả kết quả
//  5. autoSubmit(attemptId)   → nộp tự động khi hết giờ
//  6. getAttemptHistory(quizId) → lịch sử thi
//  7. getQuizResultSummary(quizId) → tổng kết
// ============================================================

class QuizService {
  // ============================================================
  // ATTEMPT MANAGEMENT
  // ============================================================

  /// Bắt đầu làm bài — POST /api/lms/attempts/start/{quizId}
  /// Trả về attemptId để dùng cho các bước tiếp theo
  static Future<AttemptStartResult> startAttempt(String quizId) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("$baseUrl/lms/attempts/start/$quizId");

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      log("START ATTEMPT STATUS: ${response.statusCode}");
      log("START ATTEMPT BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return AttemptStartResult(
          attemptId: data['id']?.toString() ?? '',
          quizId: data['quiz']?['id']?.toString() ?? quizId,
          status: data['status'] ?? 'IN_PROGRESS',
        );
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body["message"] ?? "Không thể bắt đầu bài thi");
      }
    } catch (e) {
      log("QuizService.startAttempt failed: $e");
      rethrow;
    }
  }

  /// Lấy câu hỏi của attempt — GET /api/lms/attempts/{id}/questions
  /// page=0, size=999 để lấy tất cả một lần
  static Future<Quiz> getAttemptQuestions(String attemptId, String quizId) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse(
        "$baseUrl/lms/attempts/$attemptId/questions?page=0&size=999",
      );

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      log("GET QUESTIONS STATUS: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        final questions = list.map((q) => _parseQuestion(q)).toList();
        return Quiz(
          id: quizId,
          lessonId: quizId,
          title: 'Bài kiểm tra',
          timeLimitMinutes: 10,
          passingScore: 80,
          questions: questions,
        );
      } else {
        throw Exception("Không thể tải câu hỏi");
      }
    } catch (e) {
      log("QuizService.getAttemptQuestions failed: $e");
      rethrow;
    }
  }

  /// Lưu đáp án (draft) — POST /api/lms/attempts/{id}/answer
  /// selectedOptionIds: danh sách ID đáp án đã chọn, phân cách bằng ','
  static Future<void> saveAnswer(
    String attemptId,
    String questionId,
    List<String> selectedOptionIds,
  ) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("$baseUrl/lms/attempts/$attemptId/answer");

      final ids = selectedOptionIds.join(',');

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          'questionId': questionId,
          'selectedOptionIds': ids,
        },
      );

      log("SAVE ANSWER STATUS: ${response.statusCode}");
    } catch (e) {
      // Silent fail — lưu local vẫn có hiệu lực
      log("QuizService.saveAnswer failed (silent): $e");
    }
  }

  /// Nộp bài — POST /api/lms/attempts/{id}/submit
  /// Backend tự tính điểm và trả kết quả
  static Future<QuizResult> submitAttempt(
    String attemptId,
    String quizId,
    Map<String, List<String>> answers,
    Duration timeSpent,
  ) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("$baseUrl/lms/attempts/$attemptId/submit");

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      log("SUBMIT STATUS: ${response.statusCode}");
      log("SUBMIT BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseQuizResult(data, quizId, timeSpent);
      } else {
        throw Exception("Nộp bài thất bại");
      }
    } catch (e) {
      log("QuizService.submitAttempt failed: $e");
      rethrow;
    }
  }

  /// Nộp bài tự động khi hết giờ
  static Future<QuizResult> autoSubmit(
    String attemptId,
    String quizId,
    Map<String, List<String>> answers,
    Duration timeSpent,
  ) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("$baseUrl/lms/attempts/$attemptId/auto-submit");

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      log("AUTO SUBMIT STATUS: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseQuizResult(data, quizId, timeSpent);
      } else {
        throw Exception("Auto submit failed");
      }
    } catch (e) {
      log("QuizService.autoSubmit failed: $e");
      rethrow;
    }
  }

  // ============================================================
  // HISTORY & SUMMARY
  // ============================================================

  /// Lịch sử thi — GET /api/lms/attempts/history/{quizId}
  static Future<List<AttemptHistoryItem>> getAttemptHistory(String quizId) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("$baseUrl/lms/attempts/history/$quizId");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((a) => AttemptHistoryItem(
          attemptId: a['attemptId']?.toString() ?? '',
          attemptNumber: a['attemptNumber'] ?? 1,
          score: (a['score'] ?? 0).toDouble(),
          passed: a['passed'] ?? false,
          status: a['status'] ?? 'SUBMITTED',
          startedAt: DateTime.tryParse(a['startedAt'] ?? '') ?? DateTime.now(),
          submittedAt: a['submittedAt'] != null
              ? DateTime.tryParse(a['submittedAt'])
              : null,
        )).toList();
      } else {
        return [];
      }
    } catch (e) {
      log("QuizService.getAttemptHistory: $e");
      return [];
    }
  }

  /// Tổng kết kết quả — GET /api/lms/attempts/summary/{quizId}
  static Future<QuizSummary> getQuizSummary(String quizId) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("$baseUrl/lms/attempts/summary/$quizId");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return QuizSummary(
          quizId: quizId,
          totalAttempts: data['totalAttempts'] ?? 0,
          bestScore: (data['bestScore'] ?? 0).toDouble(),
          passed: data['passed'] ?? false,
        );
      } else {
        return QuizSummary(quizId: quizId, totalAttempts: 0, bestScore: 0, passed: false);
      }
    } catch (e) {
      log("QuizService.getQuizSummary: $e");
      return QuizSummary(quizId: quizId, totalAttempts: 0, bestScore: 0, passed: false);
    }
  }

  // ============================================================
  // PARSING HELPERS
  // ============================================================

  static QuizQuestion _parseQuestion(Map<String, dynamic> q) {
    return QuizQuestion(
      id: q['questionId']?.toString() ?? '',
      content: q['content'] ?? '',
      type: _parseQuestionType(q['type']),
      options: (q['options'] as List<dynamic>?)
              ?.map((o) => QuizOption(
                    id: o['id']?.toString() ?? '',
                    content: o['content'] ?? '',
                    isCorrect: false, // Không trả về đáp án đúng khi thi
                  ))
              .toList() ??
          [],
      point: 10,
    );
  }

  static QuestionType _parseQuestionType(String? type) {
    switch (type?.toUpperCase()) {
      case 'MULTIPLE':
      case 'MULTIPLECHOICE':
        return QuestionType.multiple;
      case 'TRUEFALSE':
      case 'TRUE_FALSE':
        return QuestionType.trueFalse;
      default:
        return QuestionType.single;
    }
  }

  static QuizResult _parseQuizResult(
    Map<String, dynamic> data,
    String quizId,
    Duration timeSpent,
  ) {
    return QuizResult(
      quizId: quizId,
      totalScore: ((data['score'] ?? 0) as num).round(),
      maxScore: 100,
      passed: data['passed'] ?? false,
      correctCount: _calcCorrectCount(data),
      totalQuestions: _calcTotalQuestions(data),
      timeSpent: timeSpent,
      questionResults: [],
    );
  }

  static int _calcCorrectCount(Map<String, dynamic> data) {
    // Backend trả score dạng phần trăm
    final score = (data['score'] ?? 0).toDouble();
    // Ước tính: score >= passingScore → đạt
    return (score / 100 * (data['totalQuestions'] ?? 10)).round();
  }

  static int _calcTotalQuestions(Map<String, dynamic> data) {
    return data['totalQuestions'] ?? 10;
  }
}

// ============================================================
// RESULT / DTO CLASSES
// ============================================================

class AttemptStartResult {
  final String attemptId;
  final String quizId;
  final String status;

  AttemptStartResult({
    required this.attemptId,
    required this.quizId,
    required this.status,
  });
}

class AttemptHistoryItem {
  final String attemptId;
  final int attemptNumber;
  final double score;
  final bool passed;
  final String status;
  final DateTime startedAt;
  final DateTime? submittedAt;

  AttemptHistoryItem({
    required this.attemptId,
    required this.attemptNumber,
    required this.score,
    required this.passed,
    required this.status,
    required this.startedAt,
    this.submittedAt,
  });

  double get percentage => score;
}

class QuizSummary {
  final String quizId;
  final int totalAttempts;
  final double bestScore;
  final bool passed;

  QuizSummary({
    required this.quizId,
    required this.totalAttempts,
    required this.bestScore,
    required this.passed,
  });
}
