// ============================================
// MODELS - Learning Path Models
// ============================================

import 'course_model.dart';

// Re-export Long from course_model.dart for convenience
export 'course_model.dart' show Long;

/// Parse int/long từ JSON (backend có thể trả int hoặc double)
int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

/// Parse Long từ JSON (vì Java backend dùng Long, JavaScript mất precision)
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

/// Page response cho list Learning Paths
/// Backend: PageResponse<T> với fields: data, page, size, totalElements, totalPages, last
class LearningPathPageResponse {
  final List<LearningPathResponse> content;
  final int totalElements;
  final int totalPages;
  final int number;
  final int size;
  final bool first;
  final bool last;

  LearningPathPageResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.number,
    required this.size,
    required this.first,
    required this.last,
  });

  factory LearningPathPageResponse.fromJson(Map<String, dynamic> json) {
    // Backend trả: data[] hoặc content[]
    final List<dynamic>? rawList = json['data'] ?? json['content'];

    // Map page / number (backend dùng 'page')
    int parsedPage = _parseInt(json['page'] ?? json['number'] ?? 0);

    return LearningPathPageResponse(
      content: rawList
              ?.map((e) => LearningPathResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalElements: _parseInt(json['totalElements'] ?? rawList?.length ?? 0),
      totalPages: _parseInt(json['totalPages'] ?? 1),
      number: parsedPage,
      size: _parseInt(json['size'] ?? 10),
      first: json['first'] ?? true,
      last: json['last'] ?? false,
    );
  }

  factory LearningPathPageResponse.empty() {
    return LearningPathPageResponse(
      content: [],
      totalElements: 0,
      totalPages: 0,
      number: 0,
      size: 10,
      first: true,
      last: true,
    );
  }

  bool get hasNext => !last;
}

/// Request model để tạo Learning Path
class LearningPathCreateRequest {
  final String title;
  final String description;
  final List<CourseOrderRequest> courses;

  LearningPathCreateRequest({
    required this.title,
    required this.description,
    this.courses = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      if (courses.isNotEmpty)
        'courses': courses.map((c) => c.toJson()).toList(),
    };
  }
}

/// Request model cho thứ tự khóa học trong Learning Path
class CourseOrderRequest {
  final Long courseId;
  final int orderIndex;

  CourseOrderRequest({
    required this.courseId,
    required this.orderIndex,
  });

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'orderIndex': orderIndex,
    };
  }
}

/// Model hiển thị Learning Path (dùng cho list)
/// Backend: LearningPathResponse.java
class LearningPathResponse {
  final Long id;
  final String title;
  final String description;
  final Long? createdById;
  final String? createdByName;
  final List<Long> departmentIds;
  final List<String> departmentNames;
  final List<Long> userIds;
  final List<Long> projectIds;
  final List<CourseItemResponse> courses;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LearningPathResponse({
    required this.id,
    required this.title,
    required this.description,
    this.createdById,
    this.createdByName,
    this.departmentIds = const [],
    this.departmentNames = const [],
    this.userIds = const [],
    this.projectIds = const [],
    this.courses = const [],
    this.createdAt,
    this.updatedAt,
  });

  int get courseCount => courses.length;
  int get totalModules => courses.fold(0, (sum, c) => sum + (c.moduleCount ?? 0));

  factory LearningPathResponse.fromJson(Map<String, dynamic> json) {
    return LearningPathResponse(
      id: _parseLong(json['id']),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      createdById: json['createdById'] != null ? _parseLong(json['createdById']) : null,
      createdByName: json['createdByName']?.toString(),
      departmentIds: (json['departmentIds'] as List<dynamic>?)
              ?.map((e) => _parseLong(e))
              .toList() ??
          [],
      departmentNames: (json['departmentNames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      userIds: (json['userIds'] as List<dynamic>?)
              ?.map((e) => _parseLong(e))
              .toList() ??
          [],
      projectIds: (json['projectIds'] as List<dynamic>?)
              ?.map((e) => _parseLong(e))
              .toList() ??
          [],
      courses: (json['courses'] as List<dynamic>?)
              ?.map((e) => CourseItemResponse.fromJson(e))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }
}

/// Model chi tiết Learning Path
class LearningPathDetailResponse {
  final Long id;
  final String title;
  final String description;
  final List<CourseItemDetail> courses;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LearningPathDetailResponse({
    required this.id,
    required this.title,
    required this.description,
    this.courses = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory LearningPathDetailResponse.fromJson(Map<String, dynamic> json) {
    return LearningPathDetailResponse(
      id: _parseLong(json['id']),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      courses: (json['courses'] as List<dynamic>?)
              ?.map((e) => CourseItemDetail.fromJson(e))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }
}

/// Course item trong Learning Path (dùng cho list)
/// Backend: LearningPathResponse.CourseItem
class CourseItemResponse {
  final Long relationId;
  final Long courseId;
  final String courseTitle;
  final int orderIndex;
  final String? mentorName;
  final int? moduleCount;

  CourseItemResponse({
    required this.relationId,
    required this.courseId,
    required this.courseTitle,
    required this.orderIndex,
    this.mentorName,
    this.moduleCount,
  });

  factory CourseItemResponse.fromJson(Map<String, dynamic> json) {
    return CourseItemResponse(
      relationId: _parseLong(json['relationId']),
      courseId: _parseLong(json['courseId']),
      courseTitle: json['courseTitle'] ?? '',
      orderIndex: json['orderIndex'] ?? 0,
      mentorName: json['mentorName'],
      moduleCount: _parseInt(json['moduleCount']),
    );
  }
}

/// Course item trong Learning Path Detail
/// Backend: LearningPathDetailResponse.CourseItem
/// DELETE /{pathId}/courses/{relationId} - dùng relationId (không phải courseId)
class CourseItemDetail {
  final Long courseId;
  final Long relationId;
  final String title;
  final String? mentorName;
  final int? moduleCount;
  final int orderIndex;
  // Computed: lessonCount = moduleCount (backend moduleCount đại diện cho số bài học)
  final int? lessonCount;

  CourseItemDetail({
    required this.courseId,
    required this.relationId,
    required this.title,
    this.mentorName,
    this.moduleCount,
    required this.orderIndex,
    this.lessonCount,
  });

  factory CourseItemDetail.fromJson(Map<String, dynamic> json) {
    return CourseItemDetail(
      courseId: _parseLong(json['courseId']),
      relationId: _parseLong(json['relationId']),
      title: json['title'] ?? '',
      mentorName: json['mentorName'],
      moduleCount: _parseInt(json['moduleCount']),
      orderIndex: json['orderIndex'] ?? 0,
      lessonCount: _parseInt(json['lessonCount']),
    );
  }
}


