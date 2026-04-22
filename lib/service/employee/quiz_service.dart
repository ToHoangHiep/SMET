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
        );
      }
      return null;
    } catch (e) {
      log("QuizService.getQuizByModule failed: $e");
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
  /// GET /api/lms/attempts/summary/{quizId} (đếm attempts chính xác)
  /// GET /api/lms/quizzes/{quizId} (lấy moduleId)
  /// GET /api/lms/lessons/modules/{moduleId}/progress (kiểm tra progress)
  static Future<QuizEligibility> checkQuizEligibility(String quizId) async {
    try {
      final token = await AuthService.getToken();

      // 1. Kiểm tra active attempt
      final activeUrl = Uri.parse("$baseUrl/lms/attempts/active/$quizId");
      final activeRes = await http.get(
        activeUrl,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (activeRes.statusCode == 200) {
        final body = activeRes.body.trim();
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
            log("JSON decode error in checkQuizEligibility active check: $e");
          }
        }
      }

      // 2. Lấy quiz info và summary song song
      final quizInfoFuture = getQuizInfo(quizId);
      final summaryFuture = getQuizSummary(quizId);

      final results = await Future.wait([quizInfoFuture, summaryFuture]);
      final quizInfo = results[0] as QuizInfo;
      final summary = results[1] as QuizSummary;

      // 3. Kiểm tra lesson progress nếu quiz có module
      String? moduleId;
      bool progressReady = true;
      try {
        final quizData = await http.get(
          Uri.parse("$baseUrl/lms/quizzes/$quizId"),
          headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"},
        );
        if (quizData.statusCode == 200) {
          final data = jsonDecode(quizData.body);
          final modId = data['moduleId'] ?? data['module_id'];
          if (modId != null) {
            moduleId = modId.toString();
          }
        }
      } catch (_) {}

      if (moduleId != null) {
        try {
          final progressRes = await http.get(
            Uri.parse("$baseUrl/lms/lessons/modules/$moduleId/progress"),
            headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"},
          );
          if (progressRes.statusCode == 200) {
            final progressData = jsonDecode(progressRes.body);
            final moduleProgress = (progressData is num) ? progressData.toDouble() : 0.0;
            progressReady = moduleProgress >= 0.8;
          }
        } catch (_) {}
      }

      // 4. Tính eligibility
      final remaining = quizInfo.maxAttempts != null
          ? quizInfo.maxAttempts! - summary.totalAttempts
          : null;

      return QuizEligibility(
        canStart: progressReady &&
            (quizInfo.maxAttempts == null || summary.totalAttempts < quizInfo.maxAttempts!),
        hasActiveAttempt: false,
        maxAttempts: quizInfo.maxAttempts,
        submittedAttempts: summary.totalAttempts,
        remainingAttempts: remaining,
        progressReady: progressReady,
        passed: summary.passed,
      );
    } catch (e) {
      log("QuizService.checkQuizEligibility failed: $e");
      return QuizEligibility(canStart: true, hasActiveAttempt: false, progressReady: true);
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
        final body = response.body.trim();
        if (body.isNotEmpty && body != 'null') {
          try {
            final data = jsonDecode(body);
            if (data != null && data['id'] != null) {
              final idStr = data['id']?.toString() ?? '';
              if (idStr.isNotEmpty) {
                return ActiveAttemptInfo(
                  attemptId: idStr,
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
          } catch (e) {
            log("JSON decode error in getActiveAttempt: $e");
          }
        }
      }
      return null;
    } catch (e) {
      log("QuizService.getActiveAttempt failed: $e");
      return null;
    }
  }

  /// Bắt đầu làm bài — POST /api/lms/attempts/start/{quizId}
  /// Trả về attemptId để dùng cho các bước tiếp theo.
  /// Lấy timeLimitMinutes thực từ quiz info (backend StartAttemptResponse không trả quiz info).
  static Future<AttemptStartResult> startAttempt(String quizId) async {
    try {
      final token = await AuthService.getToken();

      // Lấy quiz info trước để có timeLimitMinutes thực
      int actualTimeLimit = 10;
      try {
        final quizInfo = await getQuizInfo(quizId);
        actualTimeLimit = quizInfo.timeLimitMinutes > 0 ? quizInfo.timeLimitMinutes : 10;
      } catch (_) {}

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
        if (data == null) {
          throw Exception("Invalid response from server: null body");
        }
        final attemptIdStr = data['attemptId']?.toString();
        if (attemptIdStr == null || attemptIdStr.isEmpty) {
          throw Exception("Server did not return attemptId. Response: ${response.body}");
        }
        final quizData = data['quiz'] as Map<String, dynamic>?;
        return AttemptStartResult(
          attemptId: attemptIdStr,
          quizId: quizData?['id']?.toString() ?? quizId,
          quizTitle: quizData?['title'],
          quizDescription: quizData?['description'] ?? quizData?['content'],
          timeLimitMinutes: actualTimeLimit,
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
  static Future<Quiz> getAttemptQuestions(String attemptId, String quizId, {int? timeLimitMinutes}) async {
    if (attemptId.isEmpty) {
      throw Exception("attemptId is required to fetch questions");
    }
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
          timeLimitMinutes: timeLimitMinutes ?? 10,
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

  /// Lưu đáp án (draft) — POST /api/lms/attempts/{id}/answer?questionId=&selectedOptionIds=
  /// Backend dùng @RequestParam nên gửi qua query string
  /// throws Exception("Attempt already submitted") khi backend đã tự động nộp bài.
  static Future<void> saveAnswer(
    String attemptId,
    String questionId,
    List<String> selectedOptionIds,
  ) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse(
        "$baseUrl/lms/attempts/$attemptId/answer?questionId=$questionId&selectedOptionIds=${selectedOptionIds.join(',')}",
      );

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: jsonEncode({
          'questionId': questionId,
          'selectedOptionIds': selectedOptionIds,
        }),
      );

      log("SAVE ANSWER STATUS: ${response.statusCode}");
      log("SAVE ANSWER BODY: ${response.body}");

      if (response.statusCode == 400) {
        try {
          final body = jsonDecode(response.body);
          final message = body['message']?.toString().toLowerCase() ?? '';
          if (message.contains('already submitted') ||
              message.contains('attempt already')) {
            throw Exception('Attempt already submitted');
          }
        } catch (e) {
          if (e is Exception) rethrow;
        }
      }

      if (response.statusCode != 200) {
        throw Exception("Lưu đáp án thất bại: ${response.statusCode}");
      }
    } catch (e) {
      log("QuizService.saveAnswer failed: $e");
      rethrow;
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
        // Parse lỗi chi tiết từ backend
        final body = jsonDecode(response.body);
        final message = body["message"] ?? "Nộp bài thất bại";
        throw Exception(message);
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
          duration: a['duration'] as int?,
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
  // RESET
  // ============================================================

  /// Reset tiến độ quiz (hết lượt thi) — POST /api/lms/quizzes/reset/me/{quizId}
  static Future<bool> resetMyAttempt(String quizId) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("$baseUrl/lms/quizzes/reset/me/$quizId");

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      log("RESET ATTEMPT STATUS: ${response.statusCode}");

      if (response.statusCode == 200) {
        return true;
      } else {
        log("QuizService.resetMyAttempt failed: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      log("QuizService.resetMyAttempt failed: $e");
      return false;
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
    final rawScore = (data['score'] ?? 0) as num;

    // Xác định score đã là % hay raw điểm.
    // Nếu score > 100 hoặc có field 'percentage'/'percent' -> dùng trực tiếp.
    // Nếu score <= 100 -> coi là percentage (0-100 scale).
    double scoreAsPercent;
    final percentageField = data['percentage'] ?? data['percent'];
    if (percentageField != null) {
      scoreAsPercent = (percentageField as num).toDouble();
    } else if (rawScore > 100) {
      // Raw điểm > 100 → cần normalize về %
      final maxRawScore = _parseDoubleField(data, [
        'maxScore',
        'totalPoints',
        'maxPoints',
      ]);
      if (maxRawScore != null && maxRawScore > 0) {
        scoreAsPercent = (rawScore / maxRawScore) * 100;
      } else {
        scoreAsPercent = rawScore.toDouble();
      }
    } else {
      scoreAsPercent = rawScore.toDouble();
    }

    return QuizResult(
      quizId: quizId,
      totalScore: rawScore.round(),
      maxScore: 100,
      percentage: scoreAsPercent,
      passed: data['passed'] ?? false,
      correctCount: _calcCorrectCount(data, totalQuestions),
      totalQuestions: totalQuestions,
      timeSpent: timeSpent,
      questionResults: [],
    );
  }

  static double? _parseDoubleField(Map<String, dynamic> data, List<String> keys) {
    for (final k in keys) {
      final v = data[k];
      if (v == null) continue;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
    }
    return null;
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
  final int? duration; // seconds

  AttemptHistoryItem({
    required this.attemptId,
    required this.attemptNumber,
    required this.score,
    required this.passed,
    required this.status,
    required this.startedAt,
    this.submittedAt,
    this.duration,
  });

  double get percentage => score;

  String get durationText {
    if (duration == null) return '—';
    final mins = duration! ~/ 60;
    final secs = duration! % 60;
    return '${mins}m ${secs}s';
  }
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

  QuizInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.timeLimitMinutes,
    required this.passingScore,
    required this.questionCount,
    this.maxAttempts,
    this.showAnswer = false,
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
  final bool progressReady;
  final bool passed;

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
    this.progressReady = true,
    this.passed = false,
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
