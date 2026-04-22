// ============================================
// MODELS - Mentor Attempt / Assignment Review Models
// Backend: AttemptService methods
//   GET /api/lms/attempts/{attemptId}
//   GET /api/lms/attempts/history/{quizId}
// NOTE: class Long được định nghĩa trong course_model.dart
// ============================================

import 'course_model.dart';

// ============================================
// ATTEMPT STATUS
// ============================================

enum AttemptStatus { IN_PROGRESS, SUBMITTED, AUTO_SUBMITTED }

extension AttemptStatusExtension on AttemptStatus {
  String get label {
    switch (this) {
      case AttemptStatus.IN_PROGRESS:
        return 'Đang làm';
      case AttemptStatus.SUBMITTED:
        return 'Đã nộp';
      case AttemptStatus.AUTO_SUBMITTED:
        return 'Hết giờ';
    }
  }

  static AttemptStatus fromString(String? value) {
    if (value == null) return AttemptStatus.IN_PROGRESS;
    return AttemptStatus.values.firstWhere(
      (e) => e.name == value.toUpperCase(),
      orElse: () => AttemptStatus.IN_PROGRESS,
    );
  }
}

// ============================================
// MENTOR ATTEMPT INFO (bài nộp của học viên)
// Backend: QuizAttemptModel -> AttemptResponse / AttemptHistoryResponse
// ============================================

class MentorAttemptInfo {
  final Long attemptId;
  final Long quizId;
  final String quizTitle;
  final Long courseId;
  final String courseTitle;
  final Long userId;
  final String userName;
  final String userEmail;
  final String? avatarUrl;
  final int attemptNumber;
  final AttemptStatus status;
  final double? score;
  final bool? passed;
  final bool isValid;
  final DateTime startedAt;
  final DateTime? expiresAt;
  final DateTime? submittedAt;

  MentorAttemptInfo({
    required this.attemptId,
    required this.quizId,
    required this.quizTitle,
    required this.courseId,
    required this.courseTitle,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.avatarUrl,
    required this.attemptNumber,
    required this.status,
    this.score,
    this.passed,
    required this.isValid,
    required this.startedAt,
    this.expiresAt,
    this.submittedAt,
  });

  factory MentorAttemptInfo.fromJson(Map<String, dynamic> json) {
    return MentorAttemptInfo(
      attemptId: Long(json['id'] as int? ?? json['attemptId'] as int? ?? 0),
      quizId: Long(json['quizId'] as int? ?? 0),
      quizTitle: json['quizTitle'] as String? ?? json['title'] as String? ?? '',
      courseId: Long(json['courseId'] as int? ?? 0),
      courseTitle: json['courseTitle'] as String? ?? '',
      userId: Long(json['userId'] as int? ?? json['studentId'] as int? ?? 0),
      userName: json['userName'] as String? ?? json['studentName'] as String? ?? '',
      userEmail: json['userEmail'] as String? ?? json['studentEmail'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      attemptNumber: json['attemptNumber'] as int? ?? 1,
      status: AttemptStatusExtension.fromString(json['status'] as String?),
      score: (json['score'] as num?)?.toDouble(),
      passed: json['passed'] as bool?,
      isValid: json['isValid'] as bool? ?? true,
      startedAt: _parseDateTime(json['startedAt']) ?? DateTime.now(),
      expiresAt: _parseDateTime(json['expiresAt']),
      submittedAt: _parseDateTime(json['submittedAt']),
    );
  }

  String get initials {
    final parts = userName.trim().split(' ');
    if (parts.isEmpty) return '??';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  String get statusLabel {
    switch (status) {
      case AttemptStatus.IN_PROGRESS:
        return 'Đang làm';
      case AttemptStatus.SUBMITTED:
        return 'Đã xem';
      case AttemptStatus.AUTO_SUBMITTED:
        return 'Hết giờ';
    }
  }

  bool get isPending => status == AttemptStatus.IN_PROGRESS;
  bool get isReviewed => submittedAt != null;
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

// ============================================
// ATTEMPT DETAIL (chi tiết bài nộp để chấm)
// Backend: AttemptQuestionResponse (list)
// ============================================

class MentorAttemptDetail {
  final MentorAttemptInfo attempt;
  final List<AttemptQuestionInfo> questions;
  final String? mentorFeedback;

  MentorAttemptDetail({
    required this.attempt,
    required this.questions,
    this.mentorFeedback,
  });

  factory MentorAttemptDetail.fromJson(Map<String, dynamic> json) {
    final questionsList = json['questions'] as List<dynamic>? ?? [];
    return MentorAttemptDetail(
      attempt: MentorAttemptInfo.fromJson(json),
      questions: questionsList
          .map((q) => AttemptQuestionInfo.fromJson(q as Map<String, dynamic>))
          .toList(),
      mentorFeedback: json['mentorFeedback'] as String?,
    );
  }
}

class AttemptQuestionInfo {
  final Long questionId;
  final String questionText;
  final String? studentAnswer; // selected option IDs, comma-separated
  final String? correctAnswer;
  final bool isCorrect;
  final String? feedback;
  final int maxScore;

  AttemptQuestionInfo({
    required this.questionId,
    required this.questionText,
    this.studentAnswer,
    this.correctAnswer,
    required this.isCorrect,
    this.feedback,
    required this.maxScore,
  });

  factory AttemptQuestionInfo.fromJson(Map<String, dynamic> json) {
    return AttemptQuestionInfo(
      questionId: Long(json['questionId'] as int? ?? json['id'] as int? ?? 0),
      questionText: json['questionText'] as String? ?? json['question'] as String? ?? '',
      studentAnswer: json['studentAnswer'] as String?,
      correctAnswer: json['correctAnswer'] as String?,
      isCorrect: json['isCorrect'] as bool? ?? false,
      feedback: json['feedback'] as String?,
      maxScore: json['maxScore'] as int? ?? 10,
    );
  }
}
