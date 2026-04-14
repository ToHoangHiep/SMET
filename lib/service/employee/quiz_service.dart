import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smet/model/Employee_quiz_model.dart';
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
  // QUIZ INFO & ELIGIBILITY
  // ============================================================

  /// Lấy quiz theo module — GET /api/lms/quizzes/module/{moduleId}
  static Future<QuizInfo?> getQuizByModule(String moduleId) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("$baseUrl/lms/quizzes/module/$moduleId");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return QuizInfo(
          id: data['id']?.toString() ?? '',
          title: data['title'] ?? 'Bài kiểm tra',
          description: data['description'] ?? '',
          timeLimitMinutes: data['timeLimitMinutes'] ?? 10,
          passingScore: data['passingScore'] ?? 70,
          questionCount: data['questionCount'] ?? 0,
          maxAttempts: data['maxAttempts'],
          showAnswer: data['showAnswer'] ?? false,
          isFinalQuiz: data['isFinalQuiz'] ?? false,
        );
      }
      return null;
    } catch (e) {
      log("QuizService.getQuizByModule failed: $e");
      return null;
    }
  }

  /// Lấy quiz cuối khóa — GET /api/lms/quizzes/course/{courseId}/final
  static Future<QuizInfo?> getFinalQuiz(String courseId) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("$baseUrl/lms/quizzes/course/$courseId/final");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return QuizInfo(
          id: data['id']?.toString() ?? '',
          title: data['title'] ?? 'Bài kiểm tra cuối khóa',
          description: data['description'] ?? '',
          timeLimitMinutes: data['timeLimitMinutes'] ?? 10,
          passingScore: data['passingScore'] ?? 70,
          questionCount: data['questionCount'] ?? 0,
          maxAttempts: data['maxAttempts'],
          showAnswer: data['showAnswer'] ?? false,
          isFinalQuiz: true,
        );
      }
      return null;
    } catch (e) {
      log("QuizService.getFinalQuiz failed: $e");
      return null;
    }
  }

  /// Lấy thông tin quiz — GET /api/lms/quizzes/{quizId}
  static Future<QuizInfo> getQuizInfo(String quizId) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("$baseUrl/lms/quizzes/$quizId");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      log("GET QUIZ INFO STATUS: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return QuizInfo(
          id: data['id']?.toString() ?? quizId,
          title: data['title'] ?? 'Bài kiểm tra',
          description: data['description'] ?? data['content'] ?? '',
          timeLimitMinutes: data['timeLimitMinutes'] ?? data['timeLimit'] ?? 10,
          passingScore: data['passingScore'] ?? data['passing_score'] ?? 70,
          questionCount: data['questionCount'] ?? data['totalQuestions'] ?? data['questions']?.length ?? 0,
          maxAttempts: data['maxAttempts'] ?? data['max_attempts'],
          showAnswer: data['showAnswer'] ?? data['show_answer'] ?? false,
          isFinalQuiz: data['isFinalQuiz'] ?? data['is_final_quiz'] ?? false,
        );
      } else {
        throw Exception("Không thể tải thông tin bài quiz");
      }
    } catch (e) {
      log("QuizService.getQuizInfo failed: $e");
      rethrow;
    }
  }

  /// Kiểm tra eligibility + lấy attempt đang làm dở (nếu có)
  /// GET /api/lms/attempts/active/{quizId}
  static Future<QuizEligibility> checkQuizEligibility(String quizId) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("$baseUrl/lms/attempts/active/$quizId");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      log("CHECK ELIGIBILITY STATUS: ${response.statusCode}");

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.isNotEmpty) {
          try {
            final data = jsonDecode(body);
            if (data != null && data['id'] != null) {
              return QuizEligibility(
                canStart: true,
                hasActiveAttempt: true,
                activeAttemptId: data['id']?.toString(),
                status: data['status'] ?? 'IN_PROGRESS',
                startedAt: data['startedAt'] != null
                    ? DateTime.tryParse(data['startedAt'])
                    : null,
                expiresAt: data['expiresAt'] != null
                    ? DateTime.tryParse(data['expiresAt'])
                    : null,
              );
            }
          } catch (e) {
            log("JSON decode error in checkQuizEligibility: $e");
          }
        }
      }

      // Không có attempt đang làm → kiểm tra max attempts
      final quizInfo = await getQuizInfo(quizId);
      final history = await getAttemptHistory(quizId);
      final submittedCount = history.where((a) => a.status == 'SUBMITTED').length;

      return QuizEligibility(
        canStart: quizInfo.maxAttempts == null || submittedCount < quizInfo.maxAttempts!,
        hasActiveAttempt: false,
        maxAttempts: quizInfo.maxAttempts,
        submittedAttempts: submittedCount,
        remainingAttempts: quizInfo.maxAttempts != null
            ? quizInfo.maxAttempts! - submittedCount
            : null,
      );
    } catch (e) {
      log("QuizService.checkQuizEligibility failed: $e");
      return QuizEligibility(canStart: true, hasActiveAttempt: false);
    }
  }

  /// Lấy attempt đang làm dở (nếu có)
  static Future<ActiveAttemptInfo?> getActiveAttempt(String quizId) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("$baseUrl/lms/attempts/active/$quizId");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      log("GET ACTIVE ATTEMPT STATUS: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['id'] != null) {
          return ActiveAttemptInfo(
            attemptId: data['id']?.toString() ?? '',
            status: data['status'] ?? 'IN_PROGRESS',
            startedAt: data['startedAt'] != null
                ? DateTime.tryParse(data['startedAt'])
                : null,
            expiresAt: data['expiresAt'] != null
                ? DateTime.tryParse(data['expiresAt'])
                : null,
          );
        }
      }
      return null;
    } catch (e) {
      log("QuizService.getActiveAttempt failed: $e");
      return null;
    }
  }

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
        final quizData = data['quiz'] as Map<String, dynamic>?;
        return AttemptStartResult(
          attemptId: data['id']?.toString() ?? '',
          quizId: quizData?['id']?.toString() ?? quizId,
          quizTitle: quizData?['title'],
          quizDescription: quizData?['description'] ?? quizData?['content'],
          timeLimitMinutes: quizData?['timeLimitMinutes'] ?? quizData?['timeLimit'] ?? 10,
          passingScore: quizData?['passingScore'] ?? quizData?['passing_score'] ?? 70,
          questionCount: quizData?['questionCount'] ?? quizData?['questions']?.length ?? 0,
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
    Duration timeSpent, {
    /// Số câu thực tế đang làm (khi backend không trả totalQuestions trong body submit)
    int? questionCountFallback,
  }) async {
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
        return _parseQuizResult(
          data,
          quizId,
          timeSpent,
          questionCountFallback: questionCountFallback,
        );
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
    Duration timeSpent, {
    int? questionCountFallback,
  }) async {
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
        return _parseQuizResult(
          data,
          quizId,
          timeSpent,
          questionCountFallback: questionCountFallback,
        );
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
    Duration timeSpent, {
    int? questionCountFallback,
  }) {
    final totalQuestions = _resolveTotalQuestions(data, questionCountFallback);
    return QuizResult(
      quizId: quizId,
      totalScore: ((data['score'] ?? 0) as num).round(),
      maxScore: 100,
      passed: data['passed'] ?? false,
      correctCount: _calcCorrectCount(data, totalQuestions),
      totalQuestions: totalQuestions,
      timeSpent: timeSpent,
      questionResults: [],
    );
  }

  static int? _parseIntField(Map<String, dynamic> data, List<String> keys) {
    for (final k in keys) {
      final v = data[k];
      if (v == null) continue;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
    }
    return null;
  }

  static int _resolveTotalQuestions(
    Map<String, dynamic> data,
    int? questionCountFallback,
  ) {
    final fromApi = _parseIntField(data, [
      'totalQuestions',
      'totalQuestionCount',
      'questionCount',
      'numberOfQuestions',
      'total',
    ]);
    if (fromApi != null && fromApi > 0) return fromApi;
    if (questionCountFallback != null && questionCountFallback > 0) {
      return questionCountFallback;
    }
    return 0;
  }

  static int _calcCorrectCount(Map<String, dynamic> data, int totalQuestions) {
    final explicit = _parseIntField(data, [
      'correctCount',
      'correctAnswers',
      'correctQuestionCount',
      'rightAnswers',
    ]);
    if (explicit != null) return explicit;

    if (totalQuestions <= 0) return 0;
    final score = (data['score'] ?? 0).toDouble();
    return (score / 100 * totalQuestions).round();
  }
}

// ============================================================
// RESULT / DTO CLASSES
// ============================================================

class AttemptStartResult {
  final String attemptId;
  final String quizId;
  final String? quizTitle;
  final String? quizDescription;
  final int timeLimitMinutes;
  final int passingScore;
  final int questionCount;
  final String status;

  AttemptStartResult({
    required this.attemptId,
    required this.quizId,
    this.quizTitle,
    this.quizDescription,
    this.timeLimitMinutes = 10,
    this.passingScore = 70,
    this.questionCount = 0,
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

class QuizInfo {
  final String id;
  final String title;
  final String description;
  final int timeLimitMinutes;
  final int passingScore;
  final int questionCount;
  final int? maxAttempts;
  final bool showAnswer;
  final bool isFinalQuiz;

  QuizInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.timeLimitMinutes,
    required this.passingScore,
    required this.questionCount,
    this.maxAttempts,
    this.showAnswer = false,
    this.isFinalQuiz = false,
  });
}

class QuizEligibility {
  final bool canStart;
  final bool hasActiveAttempt;
  final String? activeAttemptId;
  final String? status;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final int? maxAttempts;
  final int? submittedAttempts;
  final int? remainingAttempts;

  QuizEligibility({
    required this.canStart,
    required this.hasActiveAttempt,
    this.activeAttemptId,
    this.status,
    this.startedAt,
    this.expiresAt,
    this.maxAttempts,
    this.submittedAttempts,
    this.remainingAttempts,
  });
}

class ActiveAttemptInfo {
  final String attemptId;
  final String status;
  final DateTime? startedAt;
  final DateTime? expiresAt;

  ActiveAttemptInfo({
    required this.attemptId,
    required this.status,
    this.startedAt,
    this.expiresAt,
  });
}
