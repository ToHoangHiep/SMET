import 'package:flutter/foundation.dart';

/// Model cho preview phòng chat (dùng trong danh sách chat)
/// Backend: ChatRoomPreviewResponse
@immutable
class ChatRoomPreviewModel {
  final int roomId;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final String? participantName;
  final String? contextName;
  final String? contextType;

  const ChatRoomPreviewModel({
    required this.roomId,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.participantName,
    this.contextName,
    this.contextType,
  });

  factory ChatRoomPreviewModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    return ChatRoomPreviewModel(
      roomId: json['roomId'] ?? 0,
      lastMessage: json['lastMessage']?.toString(),
      lastMessageTime: parseDate(json['lastMessageTime']),
      unreadCount: json['unreadCount'] ?? 0,
      participantName: json['otherUserName']?.toString(),
      contextName: json['contextName']?.toString(),
      contextType: json['contextType']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'unreadCount': unreadCount,
      'otherUserName': participantName,
      'contextName': contextName,
      'contextType': contextType,
    };
  }

  bool get hasUnread => unreadCount > 0;

  String get formattedTime {
    if (lastMessageTime == null) return '';

    final now = DateTime.now();
    final diff = now.difference(lastMessageTime!);

    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}p';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}gi';
    } else if (diff.inDays == 1) {
      return 'H qua';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}ng';
    } else {
      return '${lastMessageTime!.day}/${lastMessageTime!.month}';
    }
  }

  String get messagePreview {
    if (lastMessage == null || lastMessage!.isEmpty) {
      return 'Chưa có tin nhắn';
    }
    if (lastMessage!.length <= 50) return lastMessage!;
    return '${lastMessage!.substring(0, 50)}...';
  }

  String get participantInitials {
    final name = participantName?.trim() ?? '';
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  String get displayName {
    return participantName?.trim().isNotEmpty == true
        ? participantName!.trim()
        : 'Không rõ';
  }

  String get contextBadge {
    if (contextName != null && contextName!.trim().isNotEmpty) {
      return contextName!;
    }
    final ctx = contextType?.trim() ?? '';
    if (ctx.isEmpty) return '';
    switch (ctx.toUpperCase()) {
      case 'COURSE':
        return 'Khóa học';
      case 'PROJECT':
        return 'Dự án';
      case 'LESSON':
        return 'Bài học';
      default:
        return ctx;
    }
  }

  ChatRoomPreviewModel copyWith({
    int? roomId,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    String? participantName,
    String? contextName,
    String? contextType,
  }) {
    return ChatRoomPreviewModel(
      roomId: roomId ?? this.roomId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      participantName: participantName ?? this.participantName,
      contextName: contextName ?? this.contextName,
      contextType: contextType ?? this.contextType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatRoomPreviewModel && other.roomId == roomId;
  }

  @override
  int get hashCode => roomId.hashCode;
}
