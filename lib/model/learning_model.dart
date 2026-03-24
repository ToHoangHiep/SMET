// ============================================
// MODELS - Data models for Learning Workspace
// ============================================

import 'package:flutter/foundation.dart';

class LearningCourse {
  final String id;
  final String title;
  final String courseId;
  final double progressPercent;
  final List<LearningModule> modules;

  const LearningCourse({
    required this.id,
    required this.title,
    required this.courseId,
    required this.progressPercent,
    required this.modules,
  });
}

class LearningModule {
  final String id;
  final String title;
  final bool isLocked;
  final bool isCompleted;
  final bool isExpanded;
  final List<Lesson> lessons;
  final VoidCallback? onToggle;

  const LearningModule({
    required this.id,
    required this.title,
    required this.isLocked,
    required this.isCompleted,
    required this.isExpanded,
    required this.lessons,
    this.onToggle,
  });
}

class Lesson {
  final String id;
  final String title;
  final String moduleId;
  final int durationMinutes;
  final bool isCompleted;
  final bool isCurrent;
  final LessonContent? content;

  const Lesson({
    required this.id,
    required this.title,
    required this.moduleId,
    required this.durationMinutes,
    required this.isCompleted,
    required this.isCurrent,
    this.content,
  });
}

class LessonContent {
  final String id;
  final String title;
  final String? videoUrl;
  final String? thumbnailUrl;
  final int videoDurationSeconds;
  final int currentPositionSeconds;
  final String level;
  final String description;
  final List<String> keyTakeaways;
  final List<LessonResource> resources;
  final List<Discussion> discussions;
  final String? transcript;
  final Lesson? nextLesson;

  const LessonContent({
    required this.id,
    required this.title,
    this.videoUrl,
    this.thumbnailUrl,
    required this.videoDurationSeconds,
    required this.currentPositionSeconds,
    required this.level,
    required this.description,
    required this.keyTakeaways,
    required this.resources,
    required this.discussions,
    this.transcript,
    this.nextLesson,
  });
}

class LessonResource {
  final String id;
  final String title;
  final String type; // 'pdf', 'link', 'video'
  final String? url;
  final String? fileSize;

  const LessonResource({
    required this.id,
    required this.title,
    required this.type,
    this.url,
    this.fileSize,
  });
}

class Discussion {
  final String id;
  final String userName;
  final String? avatarUrl;
  final String comment;
  final String timeAgo;
  final int replyCount;

  const Discussion({
    required this.id,
    required this.userName,
    this.avatarUrl,
    required this.comment,
    required this.timeAgo,
    required this.replyCount,
  });
}

class User {
  final String id;
  final String name;
  final String? avatarUrl;
  final String learnerId;

  const User({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.learnerId,
  });
}

// ============================================
// ENUMS
// ============================================

enum LessonTab {
  overview,
  resources,
  discussion,
  transcripts,
}

extension LessonTabExtension on LessonTab {
  String get label {
    switch (this) {
      case LessonTab.overview:
        return 'Tổng quan';
      case LessonTab.resources:
        return 'Tài liệu';
      case LessonTab.discussion:
        return 'Thảo luận';
      case LessonTab.transcripts:
        return 'Bản dịch';
    }
  }

  String get icon {
    switch (this) {
      case LessonTab.overview:
        return 'description';
      case LessonTab.resources:
        return 'folder_zip';
      case LessonTab.discussion:
        return 'forum';
      case LessonTab.transcripts:
        return 'history';
    }
  }
}
