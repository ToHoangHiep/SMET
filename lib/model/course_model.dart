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

// ============================================
// COURSE QUIZ RESPONSE (for admin approval preview)
// Backend: GET /api/lms/quizzes/course/{courseId}
// ============================================
class CourseQuizResponse {
  final Long id;
  final String title;
  final int? passingScore;
  final int? timeLimitMinutes;
  final int? maxAttempts;
  final int? questionCount;
  final bool? showAnswer;
  final Long? moduleId;
  final String? moduleTitle;
  final List<CourseQuizQuestionResponse>? questions;

  CourseQuizResponse({
    required this.id,
    required this.title,
    this.passingScore,
    this.timeLimitMinutes,
    this.maxAttempts,
    this.questionCount,
    this.showAnswer,
    this.moduleId,
    this.moduleTitle,
    this.questions,
  });

  factory CourseQuizResponse.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'];
    return CourseQuizResponse(
      id: Long(json['id']),
      title: (json['title'] ?? '').toString(),
      passingScore: _parseInt(json['passingScore']),
      timeLimitMinutes: _parseInt(json['timeLimitMinutes']),
      maxAttempts: json['maxAttempts'],
      questionCount: json['questionCount'],
      showAnswer: json['showAnswer'],
      moduleId: json['moduleId'] != null ? Long(json['moduleId']) : null,
      moduleTitle: json['moduleTitle']?.toString(),
      questions: rawQuestions == null
          ? null
          : (rawQuestions as List)
              .map((e) => CourseQuizQuestionResponse.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}

class CourseQuizQuestionResponse {
  final Long id;
  final String content;
  final String? type;
  final Long? lessonId;
  final List<CourseQuizOptionResponse>? options;

  CourseQuizQuestionResponse({
    required this.id,
    required this.content,
    this.type,
    this.lessonId,
    this.options,
  });

  factory CourseQuizQuestionResponse.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    return CourseQuizQuestionResponse(
      id: Long(json['id']),
      content: (json['content'] ?? '').toString(),
      type: json['type']?.toString(),
      lessonId: json['lessonId'] != null ? Long(json['lessonId']) : null,
      options: rawOptions == null
          ? null
          : (rawOptions as List)
              .map((e) => CourseQuizOptionResponse.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}

class CourseQuizOptionResponse {
  final Long id;
  final String content;
  final bool? isCorrect;

  CourseQuizOptionResponse({
    required this.id,
    required this.content,
    this.isCorrect,
  });

  factory CourseQuizOptionResponse.fromJson(Map<String, dynamic> json) {
    return CourseQuizOptionResponse(
      id: Long(json['id']),
      content: (json['content'] ?? '').toString(),
      isCorrect: json['isCorrect'],
    );
  }
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
      content:
          rawList?.map((e) => fromJsonT(e as Map<String, dynamic>)).toList() ??
          [],
      totalElements: _parseInt(
        json['totalElements'] ?? json['totalElements'] ?? 0,
      ),
      totalPages: _parseInt(json['totalPages'] ?? 0),
      number: _parseInt(json['number'] ?? json['page'] ?? 0),
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

  /// Level 1=Beginner, 2=Intermediate, 3=Advanced
  final int? level;

  /// Total duration in minutes (sum of all lesson durations)
  final int? durationMinutes;

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
    this.level,
    this.durationMinutes,
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
      level: json['level'],
      durationMinutes: json['durationMinutes'],
    );
  }

  String get statusDisplayName {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return 'Bản nháp';
      case 'PENDING':
        return 'Chờ duyệt';
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
      case 'PENDING':
        return CourseStatus.PENDING;
      default:
        return CourseStatus.DRAFT;
    }
  }
}

// ============================================
// COURSE MODULE DETAIL (nested in CourseDetailResponse)
// Backend: CourseDetailResponse.ModuleDetail
// ============================================
class CourseModuleDetail {
  final Long id;
  final String title;
  final int? orderIndex;
  final int? lessonCount;
  final List<CourseLessonDetail>? lessons;

  CourseModuleDetail({
    required this.id,
    required this.title,
    this.orderIndex,
    this.lessonCount,
    this.lessons,
  });

  factory CourseModuleDetail.fromJson(Map<String, dynamic> json) {
    final rawLessons = json['lessons'];
    return CourseModuleDetail(
      id: _parseLong(json['id']),
      title: (json['title'] ?? '').toString(),
      orderIndex: _parseInt(json['orderIndex']),
      lessonCount: _parseInt(json['lessonCount']),
      lessons: rawLessons == null
          ? null
          : (rawLessons as List)
              .map((e) => CourseLessonDetail.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}

// ============================================
// COURSE LESSON DETAIL (nested in CourseModuleDetail)
// Backend: CourseDetailResponse.LessonDetail
// ============================================
class CourseLessonDetail {
  final Long id;
  final String title;
  final int? orderIndex;
  final List<LessonContentResponse>? contents;

  CourseLessonDetail({
    required this.id,
    required this.title,
    this.orderIndex,
    this.contents,
  });

  factory CourseLessonDetail.fromJson(Map<String, dynamic> json) {
    final rawContents = json['contents'];
    return CourseLessonDetail(
      id: _parseLong(json['id']),
      title: (json['title'] ?? '').toString(),
      orderIndex: _parseInt(json['orderIndex']),
      contents: rawContents == null
          ? null
          : (rawContents as List)
              .map((e) => LessonContentResponse.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
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
  final String? departmentCode;
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

  /// Level 1=Beginner, 2=Intermediate, 3=Advanced
  final int? level;

  /// Total duration in minutes
  final int? durationMinutes;

  /// Nested module details from backend
  final List<CourseModuleDetail>? modules;

  CourseDetailResponse({
    required this.id,
    required this.title,
    this.description,
    required this.mentorId,
    required this.mentorName,
    this.departmentId,
    this.departmentName,
    this.departmentCode,
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
    this.level,
    this.durationMinutes,
    this.modules,
  });

  int get lessonCount {
    final mods = modules;
    if (mods == null) return moduleCount;
    return mods.fold(0, (sum, m) => sum + (m.lessons?.length ?? 0));
  }

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
      case 'PENDING':
        return CourseStatus.PENDING;
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
      departmentCode: json['departmentCode']?.toString(),
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
      level: json['level'],
      durationMinutes: json['durationMinutes'],
      modules: _parseModules(json['modules']),
    );
  }

  static List<CourseModuleDetail>? _parseModules(dynamic raw) {
    if (raw == null) return null;
    if (raw is! List) return null;
    return raw
        .map((e) => CourseModuleDetail.fromJson(e as Map<String, dynamic>))
        .toList();
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

  /// Level 1=Beginner, 2=Intermediate, 3=Advanced
  final int? level;

  CreateCourseRequest({
    required this.title,
    this.description,
    this.departmentId,
    this.deadlineType,
    this.defaultDeadlineDays,
    this.fixedDeadline,
    this.imageUrl,
    this.level,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    if (description != null) 'description': description,
    if (departmentId != null) 'departmentId': departmentId,
    if (deadlineType != null) 'deadlineType': deadlineType,
    if (defaultDeadlineDays != null) 'defaultDeadlineDays': defaultDeadlineDays,
    if (fixedDeadline != null) 'fixedDeadline': fixedDeadline,
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (level != null) 'level': level,
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

  /// Level 1=Beginner, 2=Intermediate, 3=Advanced
  final int? level;

  UpdateCourseRequest({
    required this.title,
    this.description,
    this.status,
    this.deadlineType,
    this.defaultDeadlineDays,
    this.imageUrl,
    this.fixedDeadline,
    this.level,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    if (description != null) 'description': description,
    if (status != null) 'status': status,
    if (deadlineType != null) 'deadlineType': deadlineType,
    if (defaultDeadlineDays != null) 'defaultDeadlineDays': defaultDeadlineDays,
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (fixedDeadline != null) 'fixedDeadline': fixedDeadline,
    if (level != null) 'level': level,
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
      case 'PENDING':
        return 'Chờ duyệt';
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
      data:
          rawList
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
// Backend: CourseStatus enum: DRAFT, PENDING, PUBLISHED, ARCHIVED
// ============================================
enum CourseStatus {
  DRAFT,
  PENDING,
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
      lessons:
          (json['lessons'] as List<dynamic>?)
              ?.map((e) => LessonResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      quizId: json['quizId'] != null ? _parseLong(json['quizId']) : null,
    );
  }
}

// ============================================
// LESSON CONTENT TYPE ENUM
// Backend: LessonContentType (TEXT, VIDEO, LINK)
// ============================================
enum LessonContentType {
  TEXT,
  VIDEO,
  LINK;

  String get label {
    switch (this) {
      case LessonContentType.TEXT:
        return 'Văn bản';
      case LessonContentType.VIDEO:
        return 'Video';
      case LessonContentType.LINK:
        return 'Tài liệu';
    }
  }
}

// ============================================
// LESSON CONTENT RESPONSE
// Backend: LessonContentResponse trong mảng contents
// ============================================
class LessonContentResponse {
  final Long id;
  final LessonContentType type;
  final String? content;
  final int orderIndex;
  final String? thumbnailUrl;

  LessonContentResponse({
    required this.id,
    required this.type,
    this.content,
    required this.orderIndex,
    this.thumbnailUrl,
  });

  factory LessonContentResponse.fromJson(Map<String, dynamic> json) {
    // Backend trả về type dạng String ("TEXT", "VIDEO", "LINK")
    LessonContentType parseType(dynamic value) {
      if (value == null) return LessonContentType.TEXT;
      final str = value.toString().toUpperCase();
      for (final t in LessonContentType.values) {
        if (t.name == str) return t;
      }
      return LessonContentType.TEXT;
    }

    return LessonContentResponse(
      id: _parseLong(json['id']),
      type: parseType(json['type']),
      content: json['content']?.toString(),
      orderIndex: _parseInt(json['orderIndex']),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
    );
  }

  // Lấy video URL từ content (backend lưu youtube video id)
  String? get videoUrl {
    if (type == LessonContentType.VIDEO && content != null) {
      return 'https://www.youtube.com/watch?v=$content';
    }
    return null;
  }

  // Lấy youtube video id từ content
  String? get youtubeVideoId => content;
}

// ============================================
// LESSON RESPONSE
// Backend: GET /api/lms/lessons/module/{moduleId}
// Backend trả về: { id, title, orderIndex, contents: [...], isCompleted }
// ============================================
class LessonResponse {
  final Long id;
  final String title;
  final int orderIndex;
  final List<LessonContentResponse> contents;
  final bool isCompleted;

  /// Duration in minutes — returned by backend
  final int? durationMinutes;

  // Deprecated fields - giữ lại để tương thích ngược
  // Sử dụng firstContent để lấy thông tin thay thế
  @Deprecated('Use contents instead')
  final String? contentType;
  @Deprecated('Use contents.firstOrNull?.content instead')
  final String? content;
  @Deprecated('Use contents.firstOrNull?.videoUrl instead')
  final String? videoUrl;
  @Deprecated('Use contents.firstOrNull?.id instead')
  final Long? contentId;

  LessonResponse({
    required this.id,
    required this.title,
    required this.orderIndex,
    this.contents = const [],
    this.isCompleted = false,
    this.durationMinutes,
    // Deprecated params - không parse từ JSON nữa
    this.contentType,
    this.content,
    this.videoUrl,
    this.contentId,
  });

  factory LessonResponse.fromJson(Map<String, dynamic> json) {
    // Parse mảng contents từ backend
    final List<LessonContentResponse> parsedContents =
        (json['contents'] as List<dynamic>?)
            ?.map(
              (e) => LessonContentResponse.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        [];

    // Sắp xếp theo orderIndex
    parsedContents.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return LessonResponse(
      id: _parseLong(json['id']),
      title: (json['title'] ?? '').toString(),
      orderIndex: _parseInt(json['orderIndex']),
      contents: parsedContents,
      isCompleted: json['isCompleted'] ?? false,
      durationMinutes: json['durationMinutes'],
    );
  }

  // Helper: lấy content đầu tiên
  LessonContentResponse? get firstContent =>
      contents.isNotEmpty ? contents.first : null;

  // Helper: lấy content type của content đầu tiên
  LessonContentType? get primaryType => firstContent?.type;

  // Helper: lấy content text của content đầu tiên
  String? get primaryContent => firstContent?.content;

  // Helper: lấy video URL của content đầu tiên
  String? get primaryVideoUrl => firstContent?.videoUrl;

  // Helper: lấy youtube video id của content đầu tiên
  String? get youtubeVideoId => firstContent?.youtubeVideoId;

  // Helper: lấy content id của content đầu tiên
  Long? get primaryContentId => firstContent?.id;

  // Helper: kiểm tra có content nào không
  bool get hasContent => contents.isNotEmpty;

  // Helper: kiểm tra có video không
  bool get hasVideo => contents.any((c) => c.type == LessonContentType.VIDEO);

  // Helper: lấy tất cả video content
  List<LessonContentResponse> get videoContents =>
      contents.where((c) => c.type == LessonContentType.VIDEO).toList();

  // Helper: lấy tất cả text content
  List<LessonContentResponse> get textContents =>
      contents.where((c) => c.type == LessonContentType.TEXT).toList();

  // Helper: lấy tất cả link content
  List<LessonContentResponse> get linkContents =>
      contents.where((c) => c.type == LessonContentType.LINK).toList();
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
// durationMinutes is required (backend validates @Min(1))
// ============================================
class CreateLessonRequest {
  final String title;
  final int orderIndex;
  final Long moduleId;
  final String contentType;
  final String? content;
  final String? videoUrl;

  /// Duration in minutes — REQUIRED by backend
  final int? durationMinutes;

  CreateLessonRequest({
    required this.title,
    required this.orderIndex,
    required this.moduleId,
    required this.contentType,
    this.content,
    this.videoUrl,
    this.durationMinutes,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'orderIndex': orderIndex,
    'moduleId': moduleId.value,
    'contentType': contentType,
    if (content != null) 'content': content,
    if (videoUrl != null) 'videoUrl': videoUrl,
    if (durationMinutes != null) 'durationMinutes': durationMinutes,
  };
}
