class DashboardSummary {
  final int totalUsers;
  final int totalDepartments;
  final int totalCourses;
  final int totalProjects;
  final int totalEnrollments;
  final int activeUsers;
  final double completionRate;
  final int overdueCount;

  DashboardSummary({
    this.totalUsers = 0,
    this.totalDepartments = 0,
    this.totalCourses = 0,
    this.totalProjects = 0,
    this.totalEnrollments = 0,
    this.activeUsers = 0,
    this.completionRate = 0.0,
    this.overdueCount = 0,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalUsers: json['totalUsers'] ?? 0,
      totalDepartments: json['totalDepartments'] ?? 0,
      totalCourses: json['totalCourses'] ?? 0,
      totalProjects: json['totalProjects'] ?? 0,
      totalEnrollments: json['totalEnrollments'] ?? 0,
      activeUsers: json['activeUsers'] ?? 0,
      completionRate: (json['completionRate'] ?? 0).toDouble(),
      overdueCount: json['overdueCount'] ?? 0,
    );
  }
}

class DashboardTrendPoint {
  final String date;
  final int count;

  DashboardTrendPoint({required this.date, required this.count});

  factory DashboardTrendPoint.fromJson(Map<String, dynamic> json) {
    return DashboardTrendPoint(
      date: json['date'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class DashboardTrend {
  final List<DashboardTrendPoint> users;
  final List<DashboardTrendPoint> enrollments;
  final List<DashboardTrendPoint> completions;

  DashboardTrend({
    this.users = const [],
    this.enrollments = const [],
    this.completions = const [],
  });

  factory DashboardTrend.fromJson(Map<String, dynamic> json) {
    return DashboardTrend(
      users: (json['users'] as List?)?.map((e) => DashboardTrendPoint.fromJson(e)).toList() ?? [],
      enrollments: (json['enrollments'] as List?)?.map((e) => DashboardTrendPoint.fromJson(e)).toList() ?? [],
      completions: (json['completions'] as List?)?.map((e) => DashboardTrendPoint.fromJson(e)).toList() ?? [],
    );
  }
}

class DashboardAlert {
  final String type;
  final String message;
  final String actionUrl;
  final int count;

  DashboardAlert({
    required this.type,
    required this.message,
    required this.actionUrl,
    required this.count,
  });

  factory DashboardAlert.fromJson(Map<String, dynamic> json) {
    return DashboardAlert(
      type: json['type'] ?? '',
      message: json['message'] ?? '',
      actionUrl: json['actionUrl'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class LeaderboardItem {
  final int userId;
  final String userName;
  final double avgScore;
  final int completedCourses;
  final double finalScore;

  LeaderboardItem({
    required this.userId,
    required this.userName,
    required this.avgScore,
    required this.completedCourses,
    required this.finalScore,
  });

  factory LeaderboardItem.fromJson(Map<String, dynamic> json) {
    return LeaderboardItem(
      userId: json['userId'] ?? 0,
      userName: json['userName'] ?? '',
      avgScore: (json['avgScore'] ?? 0).toDouble(),
      completedCourses: json['completedCourses'] ?? 0,
      finalScore: (json['finalScore'] ?? 0).toDouble(),
    );
  }
}

class CoursePerformance {
  final int courseId;
  final String courseTitle;
  final int enrollments;
  final double completionRate;

  CoursePerformance({
    required this.courseId,
    required this.courseTitle,
    required this.enrollments,
    required this.completionRate,
  });

  factory CoursePerformance.fromJson(Map<String, dynamic> json) {
    return CoursePerformance(
      courseId: json['courseId'] ?? 0,
      courseTitle: json['courseTitle'] ?? '',
      enrollments: json['enrollments'] ?? 0,
      completionRate: (json['completionRate'] ?? 0).toDouble(),
    );
  }
}

class DashboardPerformance {
  final List<LeaderboardItem> topUsers;
  final List<LeaderboardItem> lowUsers;
  final List<CoursePerformance> coursePerformance;

  DashboardPerformance({
    this.topUsers = const [],
    this.lowUsers = const [],
    this.coursePerformance = const [],
  });

  factory DashboardPerformance.fromJson(Map<String, dynamic> json) {
    return DashboardPerformance(
      topUsers: (json['topUsers'] as List?)?.map((e) => LeaderboardItem.fromJson(e)).toList() ?? [],
      lowUsers: (json['lowUsers'] as List?)?.map((e) => LeaderboardItem.fromJson(e)).toList() ?? [],
      coursePerformance: (json['coursePerformance'] as List?)?.map((e) => CoursePerformance.fromJson(e)).toList() ?? [],
    );
  }
}

class DashboardInsight {
  final String type;
  final String message;
  final String recommendation;
  final String severity; // HIGH, MEDIUM, LOW

  DashboardInsight({
    required this.type,
    required this.message,
    required this.recommendation,
    required this.severity,
  });

  factory DashboardInsight.fromJson(Map<String, dynamic> json) {
    return DashboardInsight(
      type: json['type'] ?? '',
      message: json['message'] ?? '',
      recommendation: json['recommendation'] ?? '',
      severity: json['severity'] ?? 'LOW',
    );
  }
}
