// ============================================
// WRAPPER CHO SỐ NGUYÊN
// Vì Java backend dùng Long, JS mất precision nếu truyền trực tiếp int lớn
// ============================================
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

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
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

// ============================================
// GENERIC PAGE RESPONSE
// Backend: PageResponse<T> với content/data, totalElements, totalPages...
// ============================================
class PageResponse<T> {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int number;
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

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final List<dynamic>? rawList = json['data'] ?? json['content'];
    return PageResponse(
      content: rawList
              ?.map((e) => fromJsonT(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalElements: _parseInt(json['totalElements'] ?? 0),
      totalPages: _parseInt(json['totalPages'] ?? 0),
      number: _parseInt(json['number'] ?? 0),
      size: _parseInt(json['size'] ?? 0),
      first: json['first'] ?? true,
      last: json['last'] ?? true,
    );
  }

  factory PageResponse.empty() {
    return PageResponse(
      content: [],
      totalElements: 0,
      totalPages: 0,
      number: 0,
      size: 0,
      first: true,
      last: true,
    );
  }

  bool get hasNext => !last;
}

// ============================================
// COURSE RESPONSE (dùng cho list courses)
// Backend: GET /api/lms/courses trả CourseResponse (tương đương CourseModel)
// ============================================
class CourseResponse {
  final Long id;
  final String title;
  final String? description;
  final Long mentorId;
  final String mentorName;
  final int? departmentId;
  final String? departmentName;
  final String status;
  final bool published;
  final String? imageUrl;
  final int? moduleCount;
  final int? studentCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CourseResponse({
    required this.id,
    required this.title,
    this.description,
    required this.mentorId,
    required this.mentorName,
    this.departmentId,
    this.departmentName,
    required this.status,
    this.published = false,
    this.imageUrl,
    this.moduleCount,
    this.studentCount,
    this.createdAt,
    this.updatedAt,
  });

  factory CourseResponse.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      if (val is String && val.isNotEmpty) return DateTime.tryParse(val);
      return null;
    }

    return CourseResponse(
      id: _parseLong(json['id']),
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      mentorId: _parseLong(json['mentorId']),
      mentorName: (json['mentorName'] ?? '').toString(),
      departmentId: json['departmentId'],
      departmentName: json['departmentName']?.toString(),
      status: (json['status'] ?? '').toString(),
      published: json['published'] ?? json['isPublished'] ?? false,
      imageUrl: json['imageUrl']?.toString(),
      moduleCount: json['moduleCount'],
      studentCount: json['studentCount'],
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  String get statusDisplayName {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return 'Bản nháp';
      case 'PUBLISHED':
        return 'Đã xuất bản';
      case 'ARCHIVED':
        return 'Đã lưu trữ';
      default:
        return status;
    }
  }

  bool get isPublished => published || status.toUpperCase() == 'PUBLISHED';

  int get lessonCount => moduleCount ?? 0;

  CourseStatus get courseStatus {
    switch (status.toUpperCase()) {
      case 'PUBLISHED':
        return CourseStatus.PUBLISHED;
      case 'ARCHIVED':
        return CourseStatus.ARCHIVED;
      default:
        return CourseStatus.DRAFT;
    }
  }
}

// ============================================
// COURSE DETAIL RESPONSE
// Backend: GET /api/lms/courses/{id}
// ============================================
class CourseDetailResponse {
  final Long id;
  final String title;
  final String? description;
  final Long mentorId;
  final String mentorName;
  final int? departmentId;
  final String? departmentName;
  final String status;
  final bool published;
  final String? imageUrl;
  final int moduleCount;
  final int? studentCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? deadlineType;
  final int? defaultDeadlineDays;
  final DateTime? fixedDeadline;

  CourseDetailResponse({
    required this.id,
    required this.title,
    this.description,
    required this.mentorId,
    required this.mentorName,
    this.departmentId,
    this.departmentName,
    required this.status,
    this.published = false,
    this.imageUrl,
    this.moduleCount = 0,
    this.studentCount,
    this.createdAt,
    this.updatedAt,
    this.deadlineType,
    this.defaultDeadlineDays,
    this.fixedDeadline,
  });

  int get lessonCount => moduleCount;

  String get statusLabel {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return 'Bản nháp';
      case 'PUBLISHED':
        return 'Đã xuất bản';
      case 'ARCHIVED':
        return 'Đã lưu trữ';
      default:
        return status;
    }
  }

  bool get isPublished => published || status.toUpperCase() == 'PUBLISHED';

  CourseStatus get courseStatus {
    switch (status.toUpperCase()) {
      case 'PUBLISHED':
        return CourseStatus.PUBLISHED;
      case 'ARCHIVED':
        return CourseStatus.ARCHIVED;
      default:
        return CourseStatus.DRAFT;
    }
  }

  factory CourseDetailResponse.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      if (val is String && val.isNotEmpty) return DateTime.tryParse(val);
      return null;
    }

    return CourseDetailResponse(
      id: _parseLong(json['id']),
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      mentorId: _parseLong(json['mentorId']),
      mentorName: (json['mentorName'] ?? '').toString(),
      departmentId: json['departmentId'],
      departmentName: json['departmentName']?.toString(),
      status: (json['status'] ?? '').toString(),
      published: json['published'] ?? json['isPublished'] ?? false,
      imageUrl: json['imageUrl']?.toString(),
      moduleCount: _parseInt(json['moduleCount']),
      studentCount: json['studentCount'],
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      deadlineType: json['deadlineType']?.toString(),
      defaultDeadlineDays: json['defaultDeadlineDays'],
      fixedDeadline: parseDate(json['fixedDeadline']),
    );
  }
}

// ============================================
// CREATE COURSE REQUEST
// Backend: POST /api/lms/courses
// ============================================
class CreateCourseRequest {
  final String title;
  final String? description;
  final int? departmentId;
  final String? deadlineType;
  final int? defaultDeadlineDays;
  final String? fixedDeadline;
  final String? imageUrl;

  CreateCourseRequest({
    required this.title,
    this.description,
    this.departmentId,
    this.deadlineType,
    this.defaultDeadlineDays,
    this.fixedDeadline,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        if (description != null) 'description': description,
        if (departmentId != null) 'departmentId': departmentId,
        if (deadlineType != null) 'deadlineType': deadlineType,
        if (defaultDeadlineDays != null) 'defaultDeadlineDays': defaultDeadlineDays,
        if (fixedDeadline != null) 'fixedDeadline': fixedDeadline,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };
}

// ============================================
// UPDATE COURSE REQUEST
// Backend: PUT /api/lms/courses/{id}
// ============================================
class UpdateCourseRequest {
  final String title;
  final String? description;
  final String? status;
  final String? deadlineType;
  final int? defaultDeadlineDays;
  final String? imageUrl;
  final String? fixedDeadline;

  UpdateCourseRequest({
    required this.title,
    this.description,
    this.status,
    this.deadlineType,
    this.defaultDeadlineDays,
    this.imageUrl,
    this.fixedDeadline,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        if (description != null) 'description': description,
        if (status != null) 'status': status,
        if (deadlineType != null) 'deadlineType': deadlineType,
        if (defaultDeadlineDays != null) 'defaultDeadlineDays': defaultDeadlineDays,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (fixedDeadline != null) 'fixedDeadline': fixedDeadline,
      };
}

class CourseModel {
  final int id;
  final String title;
  final String? description;
  final int mentorId;
  final String mentorName;
  final int? departmentId;
  final String? departmentName;
  final String status;
  final String? deadlineType;
  final int? defaultDeadlineDays;
  final DateTime? fixedDeadline;
  final String? deadlineStatus;

  CourseModel({
    required this.id,
    required this.title,
    this.description,
    required this.mentorId,
    required this.mentorName,
    this.departmentId,
    this.departmentName,
    required this.status,
    this.deadlineType,
    this.defaultDeadlineDays,
    this.fixedDeadline,
    this.deadlineStatus,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return CourseModel(
      id: json['id'] ?? 0,
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      mentorId: json['mentorId'] ?? 0,
      mentorName: (json['mentorName'] ?? '').toString(),
      departmentId: json['departmentId'],
      departmentName: json['departmentName']?.toString(),
      status: (json['status'] ?? '').toString(),
      deadlineType: json['deadlineType']?.toString(),
      defaultDeadlineDays: json['defaultDeadlineDays'],
      fixedDeadline: parseDate(json['fixedDeadline']),
      deadlineStatus: json['deadlineStatus']?.toString(),
    );
  }

  String get statusDisplayName {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return 'Bản nháp';
      case 'PUBLISHED':
        return 'Đã xuất bản';
      case 'ARCHIVED':
        return 'Đã lưu trữ';
      default:
        return status;
    }
  }
}

class CoursePageResponse {
  final List<CourseModel> data;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool last;

  CoursePageResponse({
    required this.data,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.last,
  });

  factory CoursePageResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawList =
        (json['data'] ?? json['content']) as List<dynamic>? ?? [];

    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return CoursePageResponse(
      data: rawList
          .map((e) => CourseModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: parseInt(json['page']),
      size: parseInt(json['size']),
      totalElements: parseInt(json['totalElements']),
      totalPages: parseInt(json['totalPages']),
      last: json['last'] ?? true,
    );
  }

  bool get hasNext => !last;
  int get currentPage => page + 1;
}

// ============================================
// DEADLINE TYPE ENUM
// ============================================
enum DeadlineType {
  RELATIVE,
  FIXED;

  String get label {
    switch (this) {
      case DeadlineType.RELATIVE:
        return 'Tương đối';
      case DeadlineType.FIXED:
        return 'Ngày cố định';
    }
  }
}

// ============================================
// COURSE STATUS HELPER
// ============================================
enum CourseStatus {
  DRAFT,
  PUBLISHED,
  ARCHIVED;

  bool get isPublished => this == CourseStatus.PUBLISHED;
}

// ============================================
// MODULE RESPONSE
// Backend: GET /api/lms/modules/course/{courseId}
// ============================================
class ModuleResponse {
  final Long id;
  final String title;
  final int orderIndex;
  final List<LessonResponse> lessons;
  final Long? quizId;

  ModuleResponse({
    required this.id,
    required this.title,
    required this.orderIndex,
    List<LessonResponse>? lessons,
    this.quizId,
  }) : lessons = lessons ?? [];

  int get lessonCount => lessons.length;

  factory ModuleResponse.fromJson(Map<String, dynamic> json) {
    return ModuleResponse(
      id: _parseLong(json['id']),
      title: (json['title'] ?? '').toString(),
      orderIndex: _parseInt(json['orderIndex']),
      lessons: (json['lessons'] as List<dynamic>?)
              ?.map((e) => LessonResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      quizId: json['quizId'] != null ? _parseLong(json['quizId']) : null,
    );
  }
}

// ============================================
// LESSON RESPONSE
// Backend: GET /api/lms/lessons/module/{moduleId}
// ============================================
class LessonResponse {
  final Long id;
  final String title;
  final int orderIndex;
  final String? contentType;
  final String? content;
  final String? videoUrl;
  final Long? contentId;

  LessonResponse({
    required this.id,
    required this.title,
    required this.orderIndex,
    this.contentType,
    this.content,
    this.videoUrl,
    this.contentId,
  });

  factory LessonResponse.fromJson(Map<String, dynamic> json) {
    return LessonResponse(
      id: _parseLong(json['id']),
      title: (json['title'] ?? '').toString(),
      orderIndex: _parseInt(json['orderIndex']),
      contentType: json['contentType']?.toString(),
      content: json['content']?.toString(),
      videoUrl: json['videoUrl']?.toString(),
      contentId: json['contentId'] != null ? _parseLong(json['contentId']) : null,
    );
  }
}

// ============================================
// CREATE MODULE REQUEST
// Backend: POST /api/lms/modules
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

  Map<String, dynamic> toJson() => {
        'title': title,
        'orderIndex': orderIndex,
        'courseId': courseId.value,
      };
}

// ============================================
// CREATE LESSON REQUEST
// Backend: POST /api/lms/lessons
// ============================================
class CreateLessonRequest {
  final String title;
  final int orderIndex;
  final Long moduleId;
  final String contentType;
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

  Map<String, dynamic> toJson() => {
        'title': title,
        'orderIndex': orderIndex,
        'moduleId': moduleId.value,
        'contentType': contentType,
        if (content != null) 'content': content,
        if (videoUrl != null) 'videoUrl': videoUrl,
      };
}
