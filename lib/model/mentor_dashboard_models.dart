// ============================================
// MENTOR DASHBOARD - Data Models
// Backend endpoints:
//   GET /api/mentor/dashboard/summary  → MentorDashboardSummary
//   GET /api/mentor/dashboard/progress → MentorDashboardProgress
//   GET /api/lms/live-sessions/course/{courseId} → List<LiveSession>
// ============================================

// ============================================
// BACKEND: GET /api/mentor/dashboard/summary
// MentorDashboardSummaryResponse.java
//   long totalCourses
//   long totalLearners
//   long unreadNotifications
//   long upcomingDeadlines
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
      totalCourses: (json['totalCourses'] as num?)?.toInt() ?? 0,
      totalLearners: (json['totalLearners'] as num?)?.toInt() ?? 0,
      unreadNotifications: (json['unreadNotifications'] as num?)?.toInt() ?? 0,
      upcomingDeadlines: (json['upcomingDeadlines'] as num?)?.toInt() ?? 0,
    );
  }
}

// ============================================
// BACKEND: GET /api/mentor/dashboard/progress
// MentorProgressResponse.java
//   long notStarted
//   long inProgress
//   long completed
// ============================================

class MentorDashboardProgress {
  final int notStarted;
  final int inProgress;
  final int completed;

  MentorDashboardProgress({
    required this.notStarted,
    required this.inProgress,
    required this.completed,
  });

  factory MentorDashboardProgress.fromJson(Map<String, dynamic> json) {
    return MentorDashboardProgress(
      notStarted: (json['notStarted'] as num?)?.toInt() ?? 0,
      inProgress: (json['inProgress'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
    );
  }
}

// ============================================
// BACKEND: GET /api/lms/live-sessions/course/{courseId}
// LiveSessionResponse.java
//   Long id, String title, String meetingUrl, String hangoutLink
//   LocalDateTime startTime, LocalDateTime endTime
// ============================================

class MentorLiveSession {
  final int id;
  final String title;
  final String? meetingUrl;
  final String? hangoutLink;
  final DateTime startTime;
  final DateTime endTime;

  MentorLiveSession({
    required this.id,
    required this.title,
    this.meetingUrl,
    this.hangoutLink,
    required this.startTime,
    required this.endTime,
  });

  factory MentorLiveSession.fromJson(Map<String, dynamic> json) {
    return MentorLiveSession(
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
