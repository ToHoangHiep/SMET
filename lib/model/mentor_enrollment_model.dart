// ============================================
// MODELS - Mentor Enrollment / Student Models
// Backend endpoints (cần bổ sung ở backend):
//   GET /api/lms/enrollments/courses/{courseId}  -- danh sách học viên
//   PUT /api/lms/enrollments/{enrollmentId}/extend-deadline
// NOTE: class Long được định nghĩa trong course_model.dart
// ============================================

import 'course_model.dart';

// ============================================
// ENROLLMENT STATUS
// ============================================

enum EnrollmentStatus { NOT_STARTED, IN_PROGRESS, COMPLETED }

extension EnrollmentStatusExtension on EnrollmentStatus {
  String get label {
    switch (this) {
      case EnrollmentStatus.NOT_STARTED:
        return 'Chưa bắt đầu';
      case EnrollmentStatus.IN_PROGRESS:
        return 'Đang học';
      case EnrollmentStatus.COMPLETED:
        return 'Hoàn thành';
    }
  }

  static EnrollmentStatus fromString(String? value) {
    if (value == null) return EnrollmentStatus.NOT_STARTED;
    return EnrollmentStatus.values.firstWhere(
      (e) => e.name == value.toUpperCase(),
      orElse: () => EnrollmentStatus.NOT_STARTED,
    );
  }
}

// ============================================
// MENTOR ENROLLMENT INFO (học viên trong khóa học)
// Backend: CourseEnrollmentModel -> EnrollmentResponse (cần tạo DTO)
// ============================================

class MentorEnrollmentInfo {
  final Long enrollmentId;
  final Long courseId;
  final String courseTitle;
  final Long userId;
  final String userName;
  final String userEmail;
  final String? avatarUrl;
  final EnrollmentStatus status;
  final int progress; // 0-100
  final DateTime enrolledAt;
  final DateTime? completedAt;
  final DateTime? deadline;
  final DateTime? extendedDeadline;
  final bool isOverdue;

  MentorEnrollmentInfo({
    required this.enrollmentId,
    required this.courseId,
    required this.courseTitle,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.avatarUrl,
    required this.status,
    required this.progress,
    required this.enrolledAt,
    this.completedAt,
    this.deadline,
    this.extendedDeadline,
    required this.isOverdue,
  });

  factory MentorEnrollmentInfo.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String?;
    final deadlineStr = json['deadline'];
    final extendedDeadlineStr = json['extendedDeadline'];
    final now = DateTime.now();

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      if (val is String && val.isNotEmpty) return DateTime.tryParse(val);
      return null;
    }

    final deadline = parseDate(deadlineStr);
    final extended = parseDate(extendedDeadlineStr);
    final effectiveDeadline = extended ?? deadline;

    return MentorEnrollmentInfo(
      enrollmentId: Long(json['enrollmentId'] as int? ?? json['id'] as int? ?? 0),
      courseId: Long(json['courseId'] as int? ?? 0),
      courseTitle: json['courseTitle'] as String? ?? '',
      userId: Long(json['userId'] as int? ?? 0),
      userName: json['userName'] as String? ?? json['name'] as String? ?? '',
      userEmail: json['userEmail'] as String? ?? json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      status: EnrollmentStatusExtension.fromString(statusStr),
      progress: json['progress'] as int? ?? 0,
      enrolledAt: parseDate(json['enrolledAt']) ?? DateTime.now(),
      completedAt: parseDate(json['completedAt']),
      deadline: deadline,
      extendedDeadline: extended,
      isOverdue: effectiveDeadline != null && effectiveDeadline.isBefore(now),
    );
  }

  String get initials {
    final parts = userName.trim().split(' ');
    if (parts.isEmpty) return '??';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  String get effectiveDeadlineLabel {
    if (extendedDeadline != null) return 'Đã gia hạn';
    if (deadline != null) return 'Deadline';
    return '';
  }
}

// ============================================
// ENROLLMENT PAGE RESPONSE
// Backend: PageResponse<MentorEnrollmentInfo>
// ============================================

class MentorEnrollmentPageResponse {
  final List<MentorEnrollmentInfo> content;
  final int totalElements;
  final int totalPages;
  final int number;
  final int size;
  final bool first;
  final bool last;

  MentorEnrollmentPageResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.number,
    required this.size,
    required this.first,
    required this.last,
  });

  factory MentorEnrollmentPageResponse.fromJson(Map<String, dynamic> json) {
    final contentList = json['content'] as List<dynamic>? ?? [];
    return MentorEnrollmentPageResponse(
      content: contentList
          .map((e) => MentorEnrollmentInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalElements: json['totalElements'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      number: json['number'] as int? ?? 0,
      size: json['size'] as int? ?? 0,
      first: json['first'] as bool? ?? true,
      last: json['last'] as bool? ?? true,
    );
  }
}

// ============================================
// COURSE ENROLLMENT STATS
// Used to populate correct course stats in mentor reports
// ============================================

class CourseEnrollmentStats {
  final int completedCourses;
  final int inProgressCourses;
  final int notStartedCourses;
  final int total;

  CourseEnrollmentStats({
    required this.completedCourses,
    required this.inProgressCourses,
    required this.notStartedCourses,
    required this.total,
  });

  factory CourseEnrollmentStats.empty() => CourseEnrollmentStats(
        completedCourses: 0,
        inProgressCourses: 0,
        notStartedCourses: 0,
        total: 0,
      );
}
