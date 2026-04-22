// ============================================
// MODELS - Mentor Dashboard mới theo thiết kế
// Backend: /api/mentor/dashboard/summary
// Backend: /api/mentor/dashboard/progress
// ============================================

// Note: Long class reused from course_model.dart
// Note: CourseResponse reused from course_model.dart

// ============================================
// SUMMARY CARDS
// ============================================
class MentorDashboardSummary {
  final int totalCourses;
  final int totalLearners;
  final int unreadNotifications;
  final int upcomingDeadlines;

  MentorDashboardSummary({
    required this.totalCourses,
    required this.totalLearners,
    required this.unreadNotifications,
    required this.upcomingDeadlines,
  });

  factory MentorDashboardSummary.fromJson(Map<String, dynamic> json) {
    return MentorDashboardSummary(
      totalCourses: (json['totalCourses'] ?? 0).toInt(),
      totalLearners: (json['totalLearners'] ?? 0).toInt(),
      unreadNotifications: (json['unreadNotifications'] ?? 0).toInt(),
      upcomingDeadlines: (json['upcomingDeadlines'] ?? 0).toInt(),
    );
  }

  factory MentorDashboardSummary.empty() => MentorDashboardSummary(
        totalCourses: 0,
        totalLearners: 0,
        unreadNotifications: 0,
        upcomingDeadlines: 0,
      );
}

// ============================================
// PROGRESS RESPONSE (Pie Chart)
// ============================================
class MentorProgress {
  final int notStarted;
  final int inProgress;
  final int completed;

  MentorProgress({
    required this.notStarted,
    required this.inProgress,
    required this.completed,
  });

  factory MentorProgress.fromJson(Map<String, dynamic> json) {
    return MentorProgress(
      notStarted: (json['notStarted'] ?? 0).toInt(),
      inProgress: (json['inProgress'] ?? 0).toInt(),
      completed: (json['completed'] ?? 0).toInt(),
    );
  }

  factory MentorProgress.empty() => MentorProgress(
        notStarted: 0,
        inProgress: 0,
        completed: 0,
      );

  int get total => notStarted + inProgress + completed;

  double get notStartedPercent => total > 0 ? (notStarted / total) * 100 : 0;
  double get inProgressPercent => total > 0 ? (inProgress / total) * 100 : 0;
  double get completedPercent => total > 0 ? (completed / total) * 100 : 0;
}

// ============================================
// ALERT ITEM
// ============================================
enum AlertType {
  deadline,
  inactive,
  lowScore,
  noAttempt,
}

extension AlertTypeExtension on AlertType {
  String get label {
    switch (this) {
      case AlertType.deadline:
        return 'Cảnh báo deadline';
      case AlertType.inactive:
        return 'Không hoạt động';
      case AlertType.lowScore:
        return 'Điểm thấp';
      case AlertType.noAttempt:
        return 'Chưa làm bài cuối';
    }
  }

  String get shortLabel {
    switch (this) {
      case AlertType.deadline:
        return 'Deadline';
      case AlertType.inactive:
        return 'Không hoạt động';
      case AlertType.lowScore:
        return 'Điểm thấp';
      case AlertType.noAttempt:
        return 'Chưa thi';
    }
  }
}

class MentorAlert {
  final int? userId;
  final String userName;
  final int? courseId;
  final String courseTitle;
  final AlertType type;
  final int? daysLeft;
  final double? score;

  MentorAlert({
    this.userId,
    required this.userName,
    this.courseId,
    required this.courseTitle,
    required this.type,
    this.daysLeft,
    this.score,
  });

  factory MentorAlert.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['type'] as String? ?? '').toUpperCase();
    AlertType alertType;
    switch (typeStr) {
      case 'DEADLINE':
        alertType = AlertType.deadline;
        break;
      case 'INACTIVE':
        alertType = AlertType.inactive;
        break;
      case 'LOW_SCORE':
        alertType = AlertType.lowScore;
        break;
      case 'NO_ATTEMPT':
        alertType = AlertType.noAttempt;
        break;
      default:
        alertType = AlertType.deadline;
    }

    return MentorAlert(
      userId: json['userId']?.toInt(),
      userName: json['userName'] ?? '',
      courseId: json['courseId']?.toInt(),
      courseTitle: json['courseTitle'] ?? '',
      type: alertType,
      daysLeft: json['daysLeft']?.toInt(),
      score: json['score'] != null ? (json['score'] as num).toDouble() : null,
    );
  }

  String get displayValue {
    switch (type) {
      case AlertType.deadline:
      case AlertType.inactive:
        return daysLeft != null ? '${daysLeft}d' : '';
      case AlertType.lowScore:
        return score != null ? '${score!.toStringAsFixed(0)}%' : '';
      case AlertType.noAttempt:
        return '';
    }
  }
}

// ============================================
// COURSE PROGRESS ITEM (cho stacked bar chart)
// ============================================
class CourseProgressItem {
  final String title;
  final int enrolledCount;
  final double avgProgress;

  CourseProgressItem({
    required this.title,
    required this.enrolledCount,
    required this.avgProgress,
  });
}
