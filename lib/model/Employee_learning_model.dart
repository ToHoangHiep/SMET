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
  final String? finalQuizId; // quiz cuối khóa
  /// Final quiz đã pass (điểm >= passingScore)
  final bool finalQuizPassed;

  const LearningCourse({
    required this.id,
    required this.title,
    required this.courseId,
    required this.progressPercent,
    required this.modules,
    this.finalQuizId,
    this.finalQuizPassed = false,
  });
}

class LearningModule {
  final String id;
  final String title;
  final bool isLocked;
  final bool isCompleted;
  final bool isExpanded;
  final double progress; // 0.0 - 1.0
  final List<Lesson> lessons;
  final String? quizId; // quiz ở cuối module
  /// Quiz đã pass (điểm >= passingScore) → hiển thị xanh ✓
  /// Quiz chưa làm / chưa pass → hiển thị xám / đỏ
  final bool quizPassed;
  final VoidCallback? onToggle;

  const LearningModule({
    required this.id,
    required this.title,
    required this.isLocked,
    required this.isCompleted,
    required this.isExpanded,
    this.progress = 0.0,
    required this.lessons,
    this.quizId,
    this.quizPassed = false,
    this.onToggle,
  });
}

enum LessonType { video, text, link, quiz }

class Lesson {
  final String id;
  final String title;
  final String moduleId;
  final int durationMinutes;
  final bool isCompleted;
  final bool isCurrent;
  final LessonType lessonType;
  final LessonContent? content;

  const Lesson({
    required this.id,
    required this.title,
    required this.moduleId,
    required this.durationMinutes,
    required this.isCompleted,
    required this.isCurrent,
    this.lessonType = LessonType.video,
    this.content,
  });
}

class LessonContent {
  final String id;
  final String title;
  final String? youtubeVideoId;
  final String? thumbnailUrl;
  final int videoDurationSeconds;
  final int currentPositionSeconds;
  final String level;
  final String description;
  final String? content;
  final String? contentType;
  final List<String> keyTakeaways;
  final List<LessonResource> resources;
  final List<Discussion> discussions;
  final String? transcript;
  final Lesson? nextLesson;
  final bool isCompleted;

  const LessonContent({
    required this.id,
    required this.title,
    this.youtubeVideoId,
    this.thumbnailUrl,
    required this.videoDurationSeconds,
    required this.currentPositionSeconds,
    required this.level,
    required this.description,
    this.content,
    this.contentType,
    required this.keyTakeaways,
    required this.resources,
    required this.discussions,
    this.transcript,
    this.nextLesson,
    this.isCompleted = false,
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
  final int id;
  final int senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final String content;
  final DateTime createdAt;
  final int replyCount;

  const Discussion({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    required this.content,
    required this.createdAt,
    this.replyCount = 0,
  });

  String get timeAgo => _formatTimeAgo(createdAt);

  static String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years năm trước';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months tháng trước';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  Discussion copyWith({
    int? id,
    int? senderId,
    String? senderName,
    String? senderAvatarUrl,
    String? content,
    DateTime? createdAt,
    int? replyCount,
  }) {
    return Discussion(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      replyCount: replyCount ?? this.replyCount,
    );
  }
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
  discussion,
}

extension LessonTabExtension on LessonTab {
  String get label {
    switch (this) {
      case LessonTab.overview:
        return 'Tổng quan';
      case LessonTab.discussion:
        return 'Thảo luận';
    }
  }

  String get icon {
    switch (this) {
      case LessonTab.overview:
        return 'description';
      case LessonTab.discussion:
        return 'forum';
    }
  }
}
