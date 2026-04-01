// ============================================
// MODELS - Mentor Live Session Models
// Backend: GET/POST/PUT/DELETE /api/lms/live-sessions
// Backend: GET /api/lms/courses
// NOTE: class Long được định nghĩa trong course_model.dart
// ============================================

import 'course_model.dart';

// ============================================
// LIVE SESSION MODEL
// Backend: LiveSessionResponse
// ============================================

class LiveSessionInfo {
  final Long id;
  final Long courseId;
  final String title;
  final String? meetingUrl;
  final String? hangoutLink;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? googleEventId;

  LiveSessionInfo({
    required this.id,
    required this.courseId,
    required this.title,
    this.meetingUrl,
    this.hangoutLink,
    this.startTime,
    this.endTime,
    this.googleEventId,
  });

  factory LiveSessionInfo.fromJson(Map<String, dynamic> json) {
    return LiveSessionInfo(
      id: Long(json['id'] as int),
      courseId: Long(json['courseId'] as int? ?? 0),
      title: json['title'] as String? ?? '',
      meetingUrl: json['meetingUrl'] as String?,
      hangoutLink: json['hangoutLink'] as String?,
      startTime: _parseDateTime(json['startTime']),
      endTime: _parseDateTime(json['endTime']),
      googleEventId: json['googleEventId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.value,
      'courseId': courseId.value,
      'title': title,
      'meetingUrl': meetingUrl,
      'hangoutLink': hangoutLink,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }

  String get statusLabel {
    if (startTime == null || endTime == null) return 'Không xác định';
    final now = DateTime.now();
    if (now.isBefore(startTime!)) return 'Sắp diễn ra';
    if (now.isAfter(endTime!)) return 'Đã kết thúc';
    return 'Đang diễn ra';
  }

  bool get isUpcoming => startTime != null && DateTime.now().isBefore(startTime!);
  bool get isOngoing =>
      startTime != null && endTime != null &&
      DateTime.now().isAfter(startTime!) && DateTime.now().isBefore(endTime!);
  bool get isPast => endTime != null && DateTime.now().isAfter(endTime!);
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

// ============================================
// CREATE LIVE SESSION REQUEST
// ============================================

class CreateLiveSessionRequest {
  final Long courseId;
  final String title;
  final String startTime; // ISO 8601 string
  final String endTime;   // ISO 8601 string

  CreateLiveSessionRequest({
    required this.courseId,
    required this.title,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId.value,
      'title': title,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}

// ============================================
// UPDATE LIVE SESSION REQUEST
// ============================================

class UpdateLiveSessionRequest {
  final String title;
  final String startTime;
  final String endTime;

  UpdateLiveSessionRequest({
    required this.title,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}

// ============================================
// COURSE SIMPLE RESPONSE (for dropdown)
// Backend: CourseResponse
// ============================================

class MentorCourseSimple {
  final Long id;
  final String title;
  final String status;

  MentorCourseSimple({
    required this.id,
    required this.title,
    required this.status,
  });

  factory MentorCourseSimple.fromJson(Map<String, dynamic> json) {
    return MentorCourseSimple(
      id: Long(json['id'] as int),
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }

  bool get isPublished => status == 'PUBLISHED';
}

// ============================================
// LIVE SESSION TYPE (for calendar)
// ============================================

enum LiveSessionType {
  liveSession,
  workshop,
  deadline,
}

extension LiveSessionTypeExtension on LiveSessionType {
  String get label {
    switch (this) {
      case LiveSessionType.liveSession:
        return 'Live Session';
      case LiveSessionType.workshop:
        return 'Workshop';
      case LiveSessionType.deadline:
        return 'Deadline';
    }
  }

  static LiveSessionType fromString(String? value) {
    if (value == null) return LiveSessionType.liveSession;
    switch (value.toUpperCase()) {
      case 'WORKSHOP':
        return LiveSessionType.workshop;
      case 'DEADLINE':
        return LiveSessionType.deadline;
      default:
        return LiveSessionType.liveSession;
    }
  }
}

// ============================================
// CALENDAR EVENT (unified model for schedule view)
// ============================================

class CalendarEvent {
  final Long id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final LiveSessionType type;
  final Long? courseId;
  final String? courseTitle;
  final String? meetingUrl;
  final String? location;
  final String? participants;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.courseId,
    this.courseTitle,
    this.meetingUrl,
    this.location,
    this.participants,
  });
}
