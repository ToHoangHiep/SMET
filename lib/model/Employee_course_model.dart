class CourseDetail {
  final String id;
  final String title;
  final String description;

  // Mentor
  final int mentorId;
  final String mentorName;

  // Department
  final int? departmentId;
  final String? departmentName;

  // Status & Deadline
  final String? status;
  final String? deadlineStatus;
  final String? deadlineType;
  final int? defaultDeadlineDays;
  final String? fixedDeadline;

  // Counts
  final int moduleCount;
  final int lessonCount;

  // Enrollment (from backend)
  final bool enrolled;
  final int progress;
  final String enrollmentStatus;
  final DateTime? enrolledAt;
  final DateTime? deadline;
  final bool overdue;

  // Modules
  final List<ModuleDetail> modules;

  const CourseDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.mentorId,
    required this.mentorName,
    this.departmentId,
    this.departmentName,
    this.status,
    this.deadlineStatus,
    this.deadlineType,
    this.defaultDeadlineDays,
    this.fixedDeadline,
    required this.moduleCount,
    required this.lessonCount,
    this.enrolled = false,
    this.progress = 0,
    this.enrollmentStatus = 'NOT_STARTED',
    this.enrolledAt,
    this.deadline,
    this.overdue = false,
    required this.modules,
  });

  bool get isArchived => status?.toUpperCase() == 'ARCHIVED';
}

class ModuleDetail {
  final int id;
  final String title;
  final int orderIndex;
  final int lessonCount;
  final List<LessonDetail> lessons;
  final bool isExpanded;

  const ModuleDetail({
    required this.id,
    required this.title,
    required this.orderIndex,
    required this.lessonCount,
    required this.lessons,
    this.isExpanded = false,
  });
}

class LessonDetail {
  final int id;
  final String title;
  final int orderIndex;
  final List<LessonContentResponse> contents;

  const LessonDetail({
    required this.id,
    required this.title,
    required this.orderIndex,
    required this.contents,
  });
}

class LessonContentResponse {
  final int id;
  final String type;
  final String content;
  final int? orderIndex;

  const LessonContentResponse({
    required this.id,
    required this.type,
    required this.content,
    this.orderIndex,
  });
}
