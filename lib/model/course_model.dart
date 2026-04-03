// ============================================
// MODELS - Course Models (Mentor side)
// ============================================

// ============================================
// ENUMS
// ============================================

enum CourseStatus { DRAFT, PUBLISHED, ARCHIVED }

extension CourseStatusExtension on CourseStatus {
  String get label {
    switch (this) {
      case CourseStatus.DRAFT:
        return 'Bản nháp';
      case CourseStatus.PUBLISHED:
        return 'Đã xuất bản';
      case CourseStatus.ARCHIVED:
        return 'Đã lưu trữ';
    }
  }

  String get apiValue {
    switch (this) {
      case CourseStatus.DRAFT:
        return 'DRAFT';
      case CourseStatus.PUBLISHED:
        return 'PUBLISHED';
      case CourseStatus.ARCHIVED:
        return 'ARCHIVED';
    }
  }

  static CourseStatus fromString(String? value) {
    if (value == null) return CourseStatus.DRAFT;
    return CourseStatus.values.firstWhere(
      (e) => e.name == value.toUpperCase(),
      orElse: () => CourseStatus.DRAFT,
    );
  }
}

enum DeadlineType { FIXED, RELATIVE }

extension DeadlineTypeExtension on DeadlineType {
  String get label {
    switch (this) {
      case DeadlineType.FIXED:
        return 'Ngày cố định';
      case DeadlineType.RELATIVE:
        return 'Tương đối (sau ngày đăng ký)';
    }
  }

  static DeadlineType fromString(String? value) {
    if (value == null) return DeadlineType.RELATIVE;
    return DeadlineType.values.firstWhere(
      (e) => e.name == value.toUpperCase(),
      orElse: () => DeadlineType.RELATIVE,
    );
  }
}

// ============================================
// REQUEST MODELS
// ============================================

class CreateModuleRequest {
  final String title;
  final int orderIndex;
  final Long courseId;

  CreateModuleRequest({
    required this.title,
    required this.orderIndex,
    required this.courseId,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'orderIndex': orderIndex,
      'courseId': courseId.value,
    };
  }
}

class CreateLessonRequest {
  final String title;
  final int orderIndex;
  final Long moduleId;

  // 🔥 thêm mới
  final String contentType; // TEXT | VIDEO | LINK
  final String? content;
  final String? videoUrl;

  CreateLessonRequest({
    required this.title,
    required this.orderIndex,
    required this.moduleId,
    required this.contentType,
    this.content,
    this.videoUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'orderIndex': orderIndex,
      'moduleId': moduleId.value,
      'contentType': contentType,
      'content': content,
      'videoUrl': videoUrl,
    };
  }
}

class CreateCourseRequest {
  final String title;
  final String description;
  final String? deadlineType;
  final int? defaultDeadlineDays;
  final String? fixedDeadline;

  CreateCourseRequest({
    required this.title,
    required this.description,
    this.deadlineType,
    this.defaultDeadlineDays,
    this.fixedDeadline,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'title': title, 'description': description};
    if (deadlineType != null) map['deadlineType'] = deadlineType;
    if (defaultDeadlineDays != null)
      map['defaultDeadlineDays'] = defaultDeadlineDays;
    if (fixedDeadline != null) map['fixedDeadline'] = fixedDeadline;
    return map;
  }
}

class UpdateCourseRequest {
  final String title;
  final String description;
  final String? status;
  final int? defaultDeadlineDays;
  final String? deadlineType;
  final String? fixedDeadline;

  UpdateCourseRequest({
    required this.title,
    required this.description,
    this.status,
    this.defaultDeadlineDays,
    this.deadlineType,
    this.fixedDeadline,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'title': title, 'description': description};
    if (status != null) map['status'] = status;
    if (defaultDeadlineDays != null)
      map['defaultDeadlineDays'] = defaultDeadlineDays;
    if (deadlineType != null) map['deadlineType'] = deadlineType;
    if (fixedDeadline != null) map['fixedDeadline'] = fixedDeadline;
    return map;
  }
}

// ============================================
// RESPONSE MODELS
// ============================================

/// Course list item (CourseResponse)
class CourseResponse {
  final Long id;
  final String title;
  final String description;
  final String? departmentName;
  final Long mentorId; // ID của mentor đã tạo khóa học
  final String mentorName;
  final bool published;
  final CourseStatus status;
  final int moduleCount;
  final int lessonCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CourseResponse({
    required this.id,
    required this.title,
    required this.description,
    this.departmentName,
    required this.mentorId,
    required this.mentorName,
    required this.published,
    required this.status,
    this.moduleCount = 0,
    this.lessonCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  String get statusLabel => status.label;
  bool get isDraft => status == CourseStatus.DRAFT;
  bool get isPublished => status == CourseStatus.PUBLISHED;
  bool get isArchived => status == CourseStatus.ARCHIVED;

  factory CourseResponse.fromJson(Map<String, dynamic> json) {
    return CourseResponse(
      id: _parseLong(json['id']),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      departmentName: json['departmentName'],
      mentorId: _parseLong(json['mentorId'] ?? json['mentor']?['id']),
      mentorName: json['mentorName'] ?? json['mentor']?['name'] ?? 'Mentor',
      published: json['published'] ?? false,
      status: CourseStatusExtension.fromString(json['status']),
      moduleCount: _parseInt(json['moduleCount']),
      lessonCount: _parseInt(json['lessonCount']),
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'])
              : null,
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'])
              : null,
    );
  }
}

/// Course detail (CourseDetailResponse)
class CourseDetailResponse {
  final Long id;
  final String title;
  final String description;
  final String? departmentName;
  final Long mentorId;
  final String mentorName;
  final bool published;
  final CourseStatus status;
  final List<ModuleResponse> modules;
  final int? defaultDeadlineDays;
  final DeadlineType? deadlineType;
  final DateTime? fixedDeadline;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CourseDetailResponse({
    required this.id,
    required this.title,
    required this.description,
    this.departmentName,
    required this.mentorId,
    required this.mentorName,
    required this.published,
    required this.status,
    this.modules = const [],
    this.defaultDeadlineDays,
    this.deadlineType,
    this.fixedDeadline,
    this.createdAt,
    this.updatedAt,
  });

  int get moduleCount => modules.length;
  int get lessonCount => modules.fold(0, (sum, m) => sum + m.lessonCount);

  bool get isDraft => status == CourseStatus.DRAFT;
  bool get isPublished => status == CourseStatus.PUBLISHED;
  bool get isArchived => status == CourseStatus.ARCHIVED;
  String get statusLabel => status.label;

  factory CourseDetailResponse.fromJson(Map<String, dynamic> json) {
    return CourseDetailResponse(
      id: _parseLong(json['id']),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      departmentName: json['departmentName'],
      mentorId: _parseLong(json['mentorId'] ?? json['mentor']?['id']),
      mentorName: json['mentorName'] ?? json['mentor']?['name'] ?? 'Mentor',
      published: json['published'] ?? false,
      status: CourseStatusExtension.fromString(json['status']),
      modules:
          (json['modules'] as List<dynamic>?)
              ?.map((e) => ModuleResponse.fromJson(e))
              .toList() ??
          [],
      defaultDeadlineDays: _parseIntNullable(json['defaultDeadlineDays']),
      deadlineType: DeadlineTypeExtension.fromString(json['deadlineType']),
      fixedDeadline:
          json['fixedDeadline'] != null
              ? DateTime.tryParse(json['fixedDeadline'])
              : null,
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'])
              : null,
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'])
              : null,
    );
  }
}

/// Module item trong course detail
class ModuleResponse {
  final Long id;
  final String title;
  final String? description;
  final int orderIndex;
  final List<LessonResponse> lessons;
  final DateTime? createdAt;
  /// Quiz cuối module (từ API GET /lms/modules/course/{id})
  final Long? quizId;

  ModuleResponse({
    required this.id,
    required this.title,
    this.description,
    required this.orderIndex,
    this.lessons = const [],
    this.createdAt,
    this.quizId,
  });

  int get lessonCount => lessons.length;

  factory ModuleResponse.fromJson(Map<String, dynamic> json) {
    return ModuleResponse(
      id: _parseLong(json['id']),
      title: json['title'] ?? '',
      description: json['description'],
      orderIndex: json['orderIndex'] ?? 0,
      lessons:
          (json['lessons'] as List<dynamic>?)
              ?.map((e) => LessonResponse.fromJson(e))
              .toList() ??
          [],
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'])
              : null,
      quizId: json['quizId'] != null ? _parseLong(json['quizId']) : null,
    );
  }
}

/// Lesson item trong module
class LessonResponse {
  final Long id;
  final String title;
  final String? description;
  final String? videoUrl;
  final String? contentType; // TEXT | VIDEO | LINK
  final String? content;
  final Long? contentId;
  final int? durationMinutes;
  final int orderIndex;
  final DateTime? createdAt;

  LessonResponse({
    required this.id,
    required this.title,
    this.description,
    this.videoUrl,
    this.contentType,
    this.content,
    this.contentId,
    this.durationMinutes,
    required this.orderIndex,
    this.createdAt,
  });

 factory LessonResponse.fromJson(Map<String, dynamic> json) {
  final contents = (json['contents'] as List?) ?? [];
  final firstContent =
      contents.isNotEmpty ? Map<String, dynamic>.from(contents.first) : null;

  final type = firstContent?['type']?.toString();
  final rawContent = firstContent?['content']?.toString();
  final rawContentId = firstContent?['id'];

  /// Backend từng lưu VIDEO id kèm query (?si=...) do YouTubeUtil substring sau youtu.be/.
  final sanitizedVideo =
      type == 'VIDEO' ? _stripYoutubeIdQueryIfBare(rawContent) : null;

  return LessonResponse(
    id: _parseLong(json['id']),
    title: json['title'] ?? '',
    description: json['description'],
    contentId: rawContentId != null ? _parseLong(rawContentId) : null,
    videoUrl: type == 'VIDEO' ? sanitizedVideo : null,
    contentType: type,
    content: type == 'TEXT' || type == 'LINK' ? rawContent : null,
    durationMinutes: _parseIntNullable(json['durationMinutes']),
    orderIndex: json['orderIndex'] ?? 0,
    createdAt:
        json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'])
            : null,
  );
}
}

/// Paginated response wrapper
class PageResponse<T> {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int number; // current page (0-indexed)
  final int size;
  final bool first;
  final bool last;

  PageResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.number,
    required this.size,
    required this.first,
    required this.last,
  });

  bool get hasNext => !last;
  bool get hasPrevious => !first;
  int get currentPage => number + 1;

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    // Backend uses "data" but some endpoints use "content"
    final List<dynamic>? rawList =
        (json['data'] ?? json['content']) as List<dynamic>?;
    return PageResponse(
      content:
          rawList?.map((e) => fromJsonT(e as Map<String, dynamic>)).toList() ??
          [],
      totalElements: _parseInt(json['totalElements'] ?? json['total']),
      totalPages: _parseInt(json['totalPages']),
      number: _parseInt(json['number'] ?? json['page']),
      size: _parseInt(json['size']),
      first: json['first'] ?? (json['page'] == 0),
      last: json['last'] ?? true,
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

int? _parseIntNullable(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

Long _parseLong(dynamic value) {
  if (value == null) return Long(0);
  if (value is int) return Long(value);
  if (value is double) return Long(value.toInt());
  if (value is String) {
    final parsed = int.tryParse(value);
    return Long(parsed ?? 0);
  }
  return Long(0);
}

/// Wrapper cho số nguyên (vì JS ko có Long)
class Long {
  final int value;
  Long(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Long && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value.toString();
}

/// Nếu backend lưu bare video ID kèm query (?si=...), strip query để chỉ giữ 11-char ID.
String? _stripYoutubeIdQueryIfBare(String? raw) {
  if (raw == null || raw.isEmpty) return raw;
  // Nếu là full URL → không strip, để _convertYoutubeUrl xử lý
  if (raw.contains('/') || raw.contains('youtube.com') || raw.contains('youtu.be')) {
    return raw;
  }
  // Là bare ID, strip query/fragment
  final q = raw.indexOf('?');
  if (q != -1) return raw.substring(0, q);
  final h = raw.indexOf('#');
  if (h != -1) return raw.substring(0, h);
  return raw;
}
