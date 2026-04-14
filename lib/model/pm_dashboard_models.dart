// ============================================
// PM DASHBOARD - Data Models
// Backend endpoints:
//   GET /api/pm/dashboard              → PmDashboardResponse
//   GET /api/pm/dashboard/trends       → PmTrendResponse
//   GET /api/pm/dashboard/team         → PageResponse<UserCourseReviewResponse>
//   GET /api/pm/dashboard/risks        → PageResponse<PmRiskResponse>
//   GET /api/pm/dashboard/insights    → List<DashboardInsightModel>
// ============================================

// ============================================
// BACKEND: GET /api/pm/dashboard
// PmDashboardResponse.java
//   long totalUsers
//   long activeCourses
//   double completionRate
//   long overdueCount
//   long atRiskUsers
// ============================================
class PmDashboardSummary {
  final int totalUsers;
  final int activeCourses;
  final double completionRate;
  final int overdueCount;
  final int atRiskUsers;

  PmDashboardSummary({
    required this.totalUsers,
    required this.activeCourses,
    required this.completionRate,
    required this.overdueCount,
    required this.atRiskUsers,
  });

  factory PmDashboardSummary.fromJson(Map<String, dynamic> json) {
    return PmDashboardSummary(
      totalUsers: _parseInt(json['totalUsers']),
      activeCourses: _parseInt(json['activeCourses']),
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0.0,
      overdueCount: _parseInt(json['overdueCount']),
      atRiskUsers: _parseInt(json['atRiskUsers']),
    );
  }
}

// ============================================
// BACKEND: GET /api/pm/dashboard/trends
// PmTrendResponse.java
//   List<PmTrendPoint> enrollments
//   List<PmTrendPoint> completions
//
// PmTrendPoint.java
//   LocalDate date
//   long value
// ============================================
class PmTrendPoint {
  final DateTime date;
  final int value;

  PmTrendPoint({required this.date, required this.value});

  factory PmTrendPoint.fromJson(Map<String, dynamic> json) {
    return PmTrendPoint(
      date: _parseDate(json['date']) ?? DateTime.now(),
      value: _parseInt(json['value']),
    );
  }
}

class PmTrendData {
  final List<PmTrendPoint> enrollments;
  final List<PmTrendPoint> completions;

  PmTrendData({required this.enrollments, required this.completions});

  factory PmTrendData.fromJson(Map<String, dynamic> json) {
    return PmTrendData(
      enrollments: _parseList(json['enrollments'], PmTrendPoint.fromJson),
      completions: _parseList(json['completions'], PmTrendPoint.fromJson),
    );
  }
}

// ============================================
// BACKEND: GET /api/pm/dashboard/team
// Paginated — requires courseId, minScore
// PageResponse<UserCourseReviewResponse>
//   Long userId
//   String userName
//   String comment
//   Double avgScore
//   List<QuizItem> quizzes
// ============================================
class UserCourseReview {
  final int userId;
  final String userName;
  final String? comment;
  final double? avgScore;
  final List<QuizItem> quizzes;

  UserCourseReview({
    required this.userId,
    required this.userName,
    this.comment,
    this.avgScore,
    required this.quizzes,
  });

  factory UserCourseReview.fromJson(Map<String, dynamic> json) {
    return UserCourseReview(
      userId: _parseInt(json['userId']),
      userName: json['userName'] ?? '',
      comment: json['comment'],
      avgScore: (json['avgScore'] as num?)?.toDouble(),
      quizzes: _parseList(json['quizzes'], QuizItem.fromJson),
    );
  }
}

class QuizItem {
  final int quizId;
  final String quizTitle;
  final int moduleId;
  final String moduleTitle;
  final double? score;
  final String? status;

  QuizItem({
    required this.quizId,
    required this.quizTitle,
    required this.moduleId,
    required this.moduleTitle,
    this.score,
    this.status,
  });

  factory QuizItem.fromJson(Map<String, dynamic> json) {
    return QuizItem(
      quizId: _parseInt(json['quizId']),
      quizTitle: json['quizTitle'] ?? '',
      moduleId: _parseInt(json['moduleId']),
      moduleTitle: json['moduleTitle'] ?? '',
      score: (json['score'] as num?)?.toDouble(),
      status: json['status'],
    );
  }
}

// ============================================
// BACKEND: GET /api/pm/dashboard/risks
// Paginated
// PageResponse<PmRiskResponse>
//   Long userId, String userName
//   NotificationType type
//   String title, String message
//   Long referenceId, String referenceType
//   LocalDateTime createdAt
// ============================================
class PmRiskItem {
  final int userId;
  final String userName;
  final String riskType;
  final String title;
  final String message;
  final int? referenceId;
  final String? referenceType;
  final DateTime createdAt;

  PmRiskItem({
    required this.userId,
    required this.userName,
    required this.riskType,
    required this.title,
    required this.message,
    this.referenceId,
    this.referenceType,
    required this.createdAt,
  });

  factory PmRiskItem.fromJson(Map<String, dynamic> json) {
    return PmRiskItem(
      userId: _parseInt(json['userId']),
      userName: json['userName'] ?? '',
      riskType: json['type'] ?? 'UNKNOWN',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      referenceId: json['referenceId'] != null ? _parseInt(json['referenceId']) : null,
      referenceType: json['referenceType'],
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
    );
  }

  String get riskTypeLabel {
    switch (riskType) {
      case 'LOW_SCORE':
        return 'Điểm thấp';
      case 'INACTIVE':
        return 'Không hoạt động';
      case 'DEADLINE_WARNING':
        return 'Cảnh báo deadline';
      case 'NO_ATTEMPT':
        return 'Không làm bài';
      default:
        return riskType;
    }
  }

  int get riskLevel {
    switch (riskType) {
      case 'LOW_SCORE':
        return 1;
      case 'NO_ATTEMPT':
        return 2;
      case 'DEADLINE_WARNING':
        return 3;
      case 'INACTIVE':
        return 4;
      default:
        return 5;
    }
  }
}

// ============================================
// BACKEND: GET /api/pm/dashboard/insights
// List<DashboardInsightModel>
// ============================================
class DashboardInsight {
  final int id;
  final String insightKey;
  final String content;
  final String? actionLabel;
  final String? actionUrl;
  final DateTime createdAt;

  DashboardInsight({
    required this.id,
    required this.insightKey,
    required this.content,
    this.actionLabel,
    this.actionUrl,
    required this.createdAt,
  });

  factory DashboardInsight.fromJson(Map<String, dynamic> json) {
    return DashboardInsight(
      id: _parseInt(json['id']),
      insightKey: json['insightKey'] ?? '',
      content: json['content'] ?? '',
      actionLabel: json['actionLabel'],
      actionUrl: json['actionUrl'],
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
    );
  }
}

// ============================================
// GENERIC PAGE RESPONSE
// ============================================
class PageResponse<T> {
  final List<T> data;
  final int totalElements;
  final int totalPages;
  final int number;
  final int size;
  final bool first;
  final bool last;

  PageResponse({
    required this.data,
    required this.totalElements,
    required this.totalPages,
    required this.number,
    required this.size,
    required this.first,
    required this.last,
  });

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return PageResponse(
      data: _parseList(json['data'], fromJson),
      totalElements: _parseInt(json['totalElements']),
      totalPages: _parseInt(json['totalPages']),
      number: _parseInt(json['number']),
      size: _parseInt(json['size']),
      first: json['first'] ?? true,
      last: json['last'] ?? true,
    );
  }
}

// ============================================
// UTILITIES
// ============================================
int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }
  return null;
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }
  return null;
}

List<T> _parseList<T>(dynamic json, T Function(Map<String, dynamic>) fromJson) {
  if (json == null) return [];
  if (json is! List) return [];
  return json
      .map((e) {
        if (e is Map<String, dynamic>) return fromJson(e);
        return null;
      })
      .whereType<T>()
      .toList();
}
