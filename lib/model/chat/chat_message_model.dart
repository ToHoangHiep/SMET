import 'package:flutter/foundation.dart';

/// Loại ngữ cảnh chat
enum ChatContextType {
  COURSE,
  PROJECT,
  LESSON,
}

/// Extension để hiển thị tên
extension ChatContextTypeExtension on ChatContextType {
  String get value {
    switch (this) {
      case ChatContextType.COURSE:
        return 'COURSE';
      case ChatContextType.PROJECT:
        return 'PROJECT';
      case ChatContextType.LESSON:
        return 'LESSON';
    }
  }

  String get displayName {
    switch (this) {
      case ChatContextType.COURSE:
        return 'Khóa học';
      case ChatContextType.PROJECT:
        return 'Dự án';
      case ChatContextType.LESSON:
        return 'Bài học';
    }
  }
}

/// Model cho tin nhắn chat
/// Backend: ChatMessageResponse
@immutable
class ChatMessageModel {
  final int id;
  final String clientMessageId;
  final int roomId;
  final int senderId;
  final String senderName;
  final String content;
  final String? type;
  final DateTime createdAt;

  const ChatMessageModel({
    required this.id,
    required this.clientMessageId,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.type,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    return ChatMessageModel(
      id: json['id'] ?? 0,
      clientMessageId: json['clientMessageId']?.toString() ?? '',
      roomId: json['roomId'] ?? 0,
      senderId: json['senderId'] ?? 0,
      senderName: json['senderName']?.toString() ?? 'Unknown',
      content: json['content']?.toString() ?? '',
      type: json['type']?.toString(),
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientMessageId': clientMessageId,
      'roomId': roomId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Lấy chữ cái đầu của tên người gửi
  String get senderInitials {
    final parts = senderName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  /// Format thời gian hiển thị
  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} phút';
    } else if (diff.inDays < 1) {
      return '${diff.inHours} giờ';
    } else if (diff.inDays == 1) {
      return 'Hôm qua';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessageModel &&
        other.id == id &&
        other.clientMessageId == clientMessageId;
  }

  @override
  int get hashCode => id.hashCode ^ clientMessageId.hashCode;
}
