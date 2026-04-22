import 'package:flutter/material.dart';

enum NotificationType {
  assignment,
  deadline,
  progress,
  quiz,
  liveSession,
  system,
}

extension NotificationTypeDisplay on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.assignment:
        return 'Bài tập';
      case NotificationType.deadline:
        return 'Deadline';
      case NotificationType.progress:
        return 'Tiến độ';
      case NotificationType.quiz:
        return 'Bài kiểm tra';
      case NotificationType.liveSession:
        return 'Buổi học trực tiếp';
      case NotificationType.system:
        return 'Hệ thống';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.assignment:
        return Icons.assignment_outlined;
      case NotificationType.deadline:
        return Icons.timer_outlined;
      case NotificationType.progress:
        return Icons.trending_up;
      case NotificationType.quiz:
        return Icons.quiz_outlined;
      case NotificationType.liveSession:
        return Icons.live_tv_outlined;
      case NotificationType.system:
        return Icons.settings_outlined;
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.assignment:
        return const Color(0xFF137FEC);
      case NotificationType.deadline:
        return Colors.orange;
      case NotificationType.progress:
        return Colors.green;
      case NotificationType.quiz:
        return Colors.purple;
      case NotificationType.liveSession:
        return Colors.red;
      case NotificationType.system:
        return Colors.grey;
    }
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final String? actionUrl;
  final String? referenceType;
  final String? referenceId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.actionUrl,
    this.referenceType,
    this.referenceId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['id'] ?? 0).toString(),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: _parseType(json['type']),
      isRead: json['isRead'] ?? false,
      createdAt: _parseDateTime(json['createdAt']),
      actionUrl: json['actionUrl'],
      referenceType: json['referenceType'],
      referenceId: json['referenceId']?.toString(),
    );
  }

  static NotificationType _parseType(dynamic value) {
    if (value == null) return NotificationType.system;
    final str = value.toString().toUpperCase();
    return NotificationType.values.firstWhere(
      (e) => e.name.toUpperCase() == str,
      orElse: () => NotificationType.system,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.name.toUpperCase(),
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'actionUrl': actionUrl,
      'referenceType': referenceType,
      'referenceId': referenceId,
    };
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      actionUrl: actionUrl,
      referenceType: referenceType,
      referenceId: referenceId,
    );
  }
}
