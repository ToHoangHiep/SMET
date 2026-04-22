import 'package:flutter/material.dart';
import 'package:smet/model/chat/chat_models.dart';

/// Message Bubble Widget - Hiển thị một tin nhắn trong chat
class MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final bool showSenderName;
  final Color primaryColor;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showSenderName = false,
    this.primaryColor = const Color(0xFF137FEC),
  });

  // Colors
  static const _bgMyMessage = Color(0xFF137FEC);
  static const _bgOtherMessage = Color(0xFFF1F5F9);
  static const _textMyMessage = Colors.white;
  static const _textOtherMessage = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF94A3B8);
  static const _timeMyMessage = Color(0xFFE0E0E0);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 48 : 12,
        right: isMe ? 12 : 48,
        top: 4,
        bottom: 4,
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender name (for other messages)
          if (showSenderName && !isMe) ...[
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 2),
              child: Text(
                message.senderName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
          ],
          // Message bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? _bgMyMessage : _bgOtherMessage,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message content
                Text(
                  message.content,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: isMe ? _textMyMessage : _textOtherMessage,
                  ),
                ),
                const SizedBox(height: 4),
                // Time
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: isMe ? _timeMyMessage : _textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Date separator widget - Hiển thị ngày phân cách giữa các tin nhắn
class DateSeparator extends StatelessWidget {
  final DateTime date;
  final Color primaryColor;

  const DateSeparator({
    super.key,
    required this.date,
    this.primaryColor = const Color(0xFF137FEC),
  });

  static const _bgDate = Color(0xFFF1F5F9);
  static const _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _bgDate,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatDate(date),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _textMuted,
                ),
              ),
            ),
          ),
          const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Hôm nay';
    } else if (messageDate == yesterday) {
      return 'Hôm qua';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Chat empty state widget
class ChatEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color primaryColor;

  const ChatEmptyState({
    super.key,
    this.title = 'Chưa có tin nhắn',
    this.subtitle = 'Bắt đầu cuộc trò chuyện với mentor',
    this.icon = Icons.chat_bubble_outline_rounded,
    this.primaryColor = const Color(0xFF137FEC),
  });

  static const _textMedium = Color(0xFF64748B);
  static const _textMuted = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: _textMedium,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading indicator for chat
class ChatLoadingIndicator extends StatelessWidget {
  final Color primaryColor;

  const ChatLoadingIndicator({
    super.key,
    this.primaryColor = const Color(0xFF137FEC),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Đang tải tin nhắn...',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
