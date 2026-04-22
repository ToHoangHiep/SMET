// ============================================
// MODELS - Data models for Course Structure
// ============================================

/// Trạng thái của bài học
enum LessonStatus {
  draft,     // Bản nháp
  published, // Công khai
  hidden,    // Ẩn
}

extension LessonStatusExtension on LessonStatus {
  String get label {
    switch (this) {
      case LessonStatus.draft:
        return 'Bản nháp';
      case LessonStatus.published:
        return 'Công khai';
      case LessonStatus.hidden:
        return 'Ẩn';
    }
  }

  String get colorHex {
    switch (this) {
      case LessonStatus.draft:
        return 'FFA500'; // Orange
      case LessonStatus.published:
        return '4CAF50'; // Green
      case LessonStatus.hidden:
        return '9E9E9E'; // Grey
    }
  }
}

/// Trạng thái của chương
enum ChapterStatus {
  draft,
  published,
}

extension ChapterStatusExtension on ChapterStatus {
  String get label {
    switch (this) {
      case ChapterStatus.draft:
        return 'Bản nháp';
      case ChapterStatus.published:
        return 'Công khai';
    }
  }
}

/// Model cho một bài học trong chương
class CourseLesson {
  final String id;
  final String title;
  final String? description;
  final String? videoUrl;
  final int? durationMinutes;
  final LessonStatus status;
  final int orderIndex;

  const CourseLesson({
    required this.id,
    required this.title,
    this.description,
    this.videoUrl,
    this.durationMinutes,
    this.status = LessonStatus.draft,
    required this.orderIndex,
  });

  CourseLesson copyWith({
    String? id,
    String? title,
    String? description,
    String? videoUrl,
    int? durationMinutes,
    LessonStatus? status,
    int? orderIndex,
  }) {
    return CourseLesson(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}

/// Model cho một chương trong khóa học
class CourseChapter {
  final String id;
  final String title;
  final String? description;
  final ChapterStatus status;
  final int orderIndex;
  final List<CourseLesson> lessons;

  const CourseChapter({
    required this.id,
    required this.title,
    this.description,
    this.status = ChapterStatus.draft,
    required this.orderIndex,
    this.lessons = const [],
  });

  CourseChapter copyWith({
    String? id,
    String? title,
    String? description,
    ChapterStatus? status,
    int? orderIndex,
    List<CourseLesson>? lessons,
  }) {
    return CourseChapter(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      orderIndex: orderIndex ?? this.orderIndex,
      lessons: lessons ?? this.lessons,
    );
  }

  /// Tạo bài học mới với id tự động
  CourseLesson createLesson({
    required String title,
    String? description,
    String? videoUrl,
  }) {
    return CourseLesson(
      id: '${id}_lesson_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      videoUrl: videoUrl,
      orderIndex: lessons.length + 1,
    );
  }
}

/// Model chính cho cấu trúc khóa học
class CourseStructure {
  final List<CourseChapter> chapters;

  const CourseStructure({this.chapters = const []});

  CourseStructure copyWith({List<CourseChapter>? chapters}) {
    return CourseStructure(chapters: chapters ?? this.chapters);
  }

  int get totalChapters => chapters.length;

  int get totalLessons => chapters.fold(0, (sum, ch) => sum + ch.lessons.length);

  int get totalDurationMinutes => chapters.fold(
    0,
    (sum, ch) => sum + ch.lessons.fold(0, (s, l) => s + (l.durationMinutes ?? 0)),
  );
}
