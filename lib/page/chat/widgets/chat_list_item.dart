import 'package:flutter/material.dart';
import 'package:smet/model/chat/chat_models.dart';

/// Chat List Item Widget - Hiển thị một phòng chat trong danh sách
class ChatListItem extends StatelessWidget {
  final ChatRoomPreviewModel room;
  final String participantName;
  final bool isActive;
  final VoidCallback onTap;
  final Color primaryColor;

  const ChatListItem({
    super.key,
    required this.room,
    required this.participantName,
    required this.onTap,
    this.isActive = false,
    this.primaryColor = const Color(0xFF137FEC),
  });

  // Colors
  static const _bgCard = Color(0xFFFFFFFF);
  static const _bgHover = Color(0xFFF1F5F9);
  static const _border = Color(0xFFE5E7EB);
  static const _textDark = Color(0xFF0F172A);
  static const _textMedium = Color(0xFF64748B);
  static const _textMuted = Color(0xFF94A3B8);
  static const _badgeBg = Color(0xFFEF4444);
  static const _badgeBgBlue = Color(0xFFDBEAFE);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? _bgHover : _bgCard,
      child: InkWell(
        onTap: onTap,
        hoverColor: _bgHover,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: _border, width: 1),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              _buildAvatar(),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and time row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            participantName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  room.hasUnread ? FontWeight.w700 : FontWeight.w600,
                              color: _textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          room.formattedTime,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: room.hasUnread ? FontWeight.w600 : FontWeight.w400,
                            color: room.hasUnread ? primaryColor : _textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Message preview row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            room.messagePreview,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: room.hasUnread ? FontWeight.w500 : FontWeight.w400,
                              color: room.hasUnread ? _textDark : _textMedium,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Unread badge
                        if (room.hasUnread) _buildUnreadBadge(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final initials = _getInitials(participantName);
    final bgColor = primaryColor.withValues(alpha: 0.1);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildUnreadBadge() {
    final count = room.unreadCount;
    final displayCount = count > 99 ? '99+' : count.toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _badgeBg,
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: const BoxConstraints(minWidth: 20),
      child: Text(
        displayCount,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    }
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }
}
