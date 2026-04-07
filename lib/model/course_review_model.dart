// ============================================
// MODEL - Course Review Response (Backend: UserCourseReviewResponse)
// Endpoint: GET /api/mentor/course-review/{courseId}
// ============================================

import 'package:smet/model/course_model.dart';

// ============================================
// COURSE REVIEW ITEM (Danh sách học viên)
// ============================================

class CourseReviewItem {
  final Long userId;
  final String userName;
  final String? comment;
  final double? avgScore;
  final List<QuizItem> quizzes;

  CourseReviewItem({
    required this.userId,
    required this.userName,
    this.comment,
    this.avgScore,
    required this.quizzes,
  });

  factory CourseReviewItem.fromJson(Map<String, dynamic> json) {
    return CourseReviewItem(
      userId: Long(json['userId'] as int? ?? 0),
      userName: json['userName'] as String? ?? '',
      comment: json['comment'] as String?,
      avgScore: (json['avgScore'] as num?)?.toDouble(),
      quizzes:
          (json['quizzes'] as List<dynamic>?)
              ?.map((e) => QuizItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  String get initials {
    final parts = userName.trim().split(' ');
    if (parts.isEmpty) return '??';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  int get totalQuestions {
    int count = 0;
    for (final quiz in quizzes) {
      count += quiz.questions.length;
    }
    return count;
  }

  int get correctAnswers {
    int count = 0;
    for (final quiz in quizzes) {
      for (final q in quiz.questions) {
        if (q.isCorrect) count++;
      }
    }
    return count;
  }

  double? get overallAccuracy {
    if (totalQuestions == 0) return null;
    return (correctAnswers / totalQuestions) * 100;
  }
}

// ============================================
// QUIZ ITEM (Bài quiz của học viên)
// ============================================

class QuizItem {
  final Long quizId;
  final String quizTitle;
  final Long? moduleId;
  final String? moduleTitle;
  final double? score;
  final String status;
  final List<QuestionItem> questions;

  QuizItem({
    required this.quizId,
    required this.quizTitle,
    this.moduleId,
    this.moduleTitle,
    this.score,
    required this.status,
    required this.questions,
  });

  factory QuizItem.fromJson(Map<String, dynamic> json) {
    return QuizItem(
      quizId: Long(json['quizId'] as int? ?? 0),
      quizTitle: json['quizTitle'] as String? ?? '',
      moduleId: json['moduleId'] != null ? Long(json['moduleId'] as int) : null,
      moduleTitle: json['moduleTitle'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      status: json['status'] as String? ?? '',
      questions:
          (json['questions'] as List<dynamic>?)
              ?.map((e) => QuestionItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  bool get isPassed => status == 'SUBMITTED' || status == 'AUTO_SUBMITTED';
}

// ============================================
// QUESTION ITEM (Câu hỏi trong quiz)
// ============================================

class QuestionItem {
  final Long questionId;
  final String content;
  final Set<Long> correctAnswers;
  final Set<Long> selectedAnswers;
  final bool isCorrect;

  QuestionItem({
    required this.questionId,
    required this.content,
    required this.correctAnswers,
    required this.selectedAnswers,
    required this.isCorrect,
  });

  factory QuestionItem.fromJson(Map<String, dynamic> json) {
    return QuestionItem(
      questionId: Long(json['questionId'] as int? ?? 0),
      content: json['content'] as String? ?? '',
      correctAnswers: _parseLongSet(json['correctAnswers']),
      selectedAnswers: _parseLongSet(json['selectedAnswers']),
      isCorrect:
          json['correct'] as bool? ?? json['isCorrect'] as bool? ?? false,
    );
  }

  static Set<Long> _parseLongSet(dynamic value) {
    if (value == null) return {};
    if (value is List) {
      return value.map((e) => Long(e as int)).toSet();
    }
    return {};
  }
}

// ============================================
// PAGE RESPONSE (Phân trang từ backend)
// ============================================

class CourseReviewPageResponse {
  final List<CourseReviewItem> items;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  CourseReviewPageResponse({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  factory CourseReviewPageResponse.fromJson(Map<String, dynamic> json) {
    final content = json['data'] as List<dynamic>? ?? [];
    return CourseReviewPageResponse(
      items:
          content
              .map((e) => CourseReviewItem.fromJson(e as Map<String, dynamic>))
              .toList(),
      page: json['page'] as int? ?? 0,
      size: json['size'] as int? ?? 10,
      totalElements: json['totalElements'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }
}
