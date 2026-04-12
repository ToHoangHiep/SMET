// ============================================
// MODELS - Employee Dashboard
// Backend endpoints:
//   GET /api/user/dashboard/overview
//   GET /api/lms/enrollments/my-courses
//   GET /api/lms/live-sessions/live-sessions
//   GET /api/leaderboard
// ============================================

// ============================================
// USER DASHBOARD OVERVIEW
// Backend: UserDashboardOverviewResponse.java
//   Long courseId, String courseTitle, Double progress, Long resumeLessonId
// ============================================
class UserDashboardOverview {
  final int courseId;
  final String courseTitle;
  final double progress;
  final int resumeLessonId;

  UserDashboardOverview({
    required this.courseId,
    required this.courseTitle,
    required this.progress,
    required this.resumeLessonId,
  });

  factory UserDashboardOverview.fromJson(Map<String, dynamic> json) {
    return UserDashboardOverview(
      courseId: _parseInt(json['courseId']),
      courseTitle: json['courseTitle'] ?? '',
      progress: (json['progress'] ?? 0).toDouble(),
      resumeLessonId: _parseInt(json['resumeLessonId']),
    );
  }

  factory UserDashboardOverview.empty() => UserDashboardOverview(
        courseId: 0,
        courseTitle: '',
        progress: 0,
        resumeLessonId: 0,
      );

  bool get hasCourse => courseId != 0 && courseTitle.isNotEmpty;
}

// ============================================
// MY COURSE ITEM
// Backend: CourseListResponse.java
// ============================================
class MyCourse {
  final int id;
  final String title;
  final String description;
  final bool enrolled;
  final double progress;
  final EnrollmentStatus status;
  final bool certificateAvailable;
  final DeadlineStatus deadlineStatus;
  final DateTime? deadline;
  final bool overdue;
  final DateTime? enrolledAt;

  MyCourse({
    required this.id,
    required this.title,
    this.description = '',
    this.enrolled = false,
    this.progress = 0,
    this.status = EnrollmentStatus.notStarted,
    this.certificateAvailable = false,
    this.deadlineStatus = DeadlineStatus.none,
    this.deadline,
    this.overdue = false,
    this.enrolledAt,
  });

  factory MyCourse.fromJson(Map<String, dynamic> json) {
    return MyCourse(
      id: _parseInt(json['id']),
      title: json['title'] ?? 'Khóa học',
      description: json['description'] ?? '',
      enrolled: json['enrolled'] ?? false,
      progress: (json['progress'] ?? 0).toDouble(),
      status: EnrollmentStatusExtension.fromString(json['status']),
      certificateAvailable: json['certificateAvailable'] ?? false,
      deadlineStatus: DeadlineStatusExtension.fromString(json['deadlineStatus']),
      deadline: _parseDateTime(json['deadline']),
      overdue: json['overdue'] ?? false,
      enrolledAt: _parseDateTime(json['enrolledAt']),
    );
  }
}

enum EnrollmentStatus { notStarted, inProgress, completed, unknown }

extension EnrollmentStatusExtension on EnrollmentStatus {
  String get label {
    switch (this) {
      case EnrollmentStatus.notStarted:
        return 'Chưa bắt đầu';
      case EnrollmentStatus.inProgress:
        return 'Đang học';
      case EnrollmentStatus.completed:
        return 'Hoàn thành';
      case EnrollmentStatus.unknown:
        return 'Không xác định';
    }
  }

  static EnrollmentStatus fromString(String? s) {
    switch (s?.toUpperCase()) {
      case 'NOT_STARTED':
        return EnrollmentStatus.notStarted;
      case 'IN_PROGRESS':
        return EnrollmentStatus.inProgress;
      case 'COMPLETED':
        return EnrollmentStatus.completed;
      default:
        return EnrollmentStatus.unknown;
    }
  }
}

enum DeadlineStatus { onTime, dueSoon, overdue, none }

extension DeadlineStatusExtension on DeadlineStatus {
  static DeadlineStatus fromString(String? s) {
    switch (s?.toUpperCase()) {
      case 'ON_TIME':
        return DeadlineStatus.onTime;
      case 'DUE_SOON':
        return DeadlineStatus.dueSoon;
      case 'OVERDUE':
        return DeadlineStatus.overdue;
      default:
        return DeadlineStatus.none;
    }
  }
}

// ============================================
// LIVE SESSION ITEM
// Backend: LiveSessionResponse.java
// ============================================
class LiveSession {
  final int id;
  final String title;
  final String? meetingUrl;
  final String? hangoutLink;
  final DateTime startTime;
  final DateTime endTime;

  LiveSession({
    required this.id,
    required this.title,
    this.meetingUrl,
    this.hangoutLink,
    required this.startTime,
    required this.endTime,
  });

  factory LiveSession.fromJson(Map<String, dynamic> json) {
    return LiveSession(
      id: _parseInt(json['id']),
      title: json['title'] ?? '',
      meetingUrl: json['meetingUrl'],
      hangoutLink: json['hangoutLink'],
      startTime: _parseDateTime(json['startTime']) ?? DateTime.now(),
      endTime: _parseDateTime(json['endTime']) ?? DateTime.now(),
    );
  }

  String? get joinUrl => meetingUrl ?? hangoutLink;

  bool get isUpcoming => startTime.isAfter(DateTime.now());
  bool get isOngoing =>
      DateTime.now().isAfter(startTime) && DateTime.now().isBefore(endTime);
}

// ============================================
// LEADERBOARD ITEM
// Backend: LeaderboardItemResponse.java
// ============================================
class LeaderboardItem {
  final int userId;
  final String userName;
  final double avgScore;
  final int completedCourses;
  final double finalScore;
  final int rank;

  LeaderboardItem({
    required this.userId,
    required this.userName,
    this.avgScore = 0,
    this.completedCourses = 0,
    this.finalScore = 0,
    this.rank = 0,
  });

  factory LeaderboardItem.fromJson(Map<String, dynamic> json) {
    return LeaderboardItem(
      userId: _parseInt(json['userId']),
      userName: json['userName'] ?? '',
      avgScore: (json['avgScore'] ?? 0).toDouble(),
      completedCourses: _parseInt(json['completedCourses']),
      finalScore: (json['finalScore'] ?? 0).toDouble(),
      rank: _parseInt(json['rank']),
    );
  }
}

// ============================================
// HELPERS
// ============================================
int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}
