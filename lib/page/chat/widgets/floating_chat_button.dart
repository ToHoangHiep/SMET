import 'package:flutter/material.dart';
import 'package:smet/model/chat/chat_models.dart';
import 'package:smet/service/chat/chat_service.dart';
import 'package:smet/service/chat/websocket_service.dart';
import 'package:smet/service/common/auth_service.dart';
import 'dart:developer';
import 'dart:async';

/// FloatingChatButton - Nút chat nổi góc dưới bên phải
///
/// Xuất hiện xuyên suốt tất cả màn hình employee và mentor thông qua Shell.
/// Cho phép nhanh chóng trả lời tin nhắn mà không cần rời khỏi trang hiện tại.
class FloatingChatButton extends StatefulWidget {
  final Color primaryColor;
  final String rolePrefix;

  const FloatingChatButton({
    super.key,
    this.primaryColor = const Color(0xFF137FEC),
    this.rolePrefix = 'employee',
  });

  @override
  State<FloatingChatButton> createState() => _FloatingChatButtonState();
}

class _FloatingChatButtonState extends State<FloatingChatButton>
    with SingleTickerProviderStateMixin {
  static const _bgCard = Color(0xFFFFFFFF);
  static const _border = Color(0xFFE5E7EB);
  static const _textDark = Color(0xFF0F172A);
  static const _textMedium = Color(0xFF64748B);

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  List<ChatRoomPreviewModel> _rooms = [];
  bool _isExpanded = false;
  bool _isLoading = true;
  int _totalUnread = 0;
  bool _hasNewMessage = false;

  int? _activeRoomId;
  List<ChatMessageModel> _activeMessages = [];
  bool _loadingMessages = false;
  bool _sendingMessage = false;
  bool _hasMoreMessages = true;
  bool _loadMoreLoading = false;
  int? _messagesCursor;

  final ScrollController _messagesScrollController = ScrollController();

  StreamSubscription<ChatRoomUpdate>? _roomUpdateSubscription;
  StreamSubscription<ChatMessageModel>? _messageSubscription;

  ChatConnectionService get _wsService => ChatConnectionService.instance;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
    _loadRooms();
    _subscribeToWebSocket();
  }

  @override
  void dispose() {
    _roomUpdateSubscription?.cancel();
    _messageSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _subscribeToWebSocket() {
    _wsService.connect();

    _messageSubscription = _wsService.messageStream.listen((message) {
      if (!mounted) return;

      if (_activeRoomId == message.roomId) {
        setState(() {
          if (!_activeMessages.any((m) => m.id == message.id)) {
            _activeMessages.add(message);
          }
        });
      }

      if (!_hasNewMessage) {
        setState(() => _hasNewMessage = true);
        _pulseController.forward();
      }
    });

    _roomUpdateSubscription = _wsService.roomUpdateStream.listen((update) {
      if (!mounted) return;
      setState(() {
        final idx = _rooms.indexWhere((r) => r.roomId == update.roomId);
        if (idx != -1) {
          _rooms[idx] = _rooms[idx].copyWith(
            lastMessage: update.lastMessage,
            lastMessageTime: update.lastMessageTime,
            unreadCount: _rooms[idx].unreadCount + 1,
          );
          _totalUnread = _rooms.fold(0, (sum, r) => sum + r.unreadCount);
        }
      });
    });
  }

  Future<void> _loadRooms() async {
    try {
      final rooms = await ChatService.getMyRooms();
      if (mounted) {
        setState(() {
          _rooms = rooms;
          _totalUnread = rooms.fold(0, (sum, r) => sum + r.unreadCount);
          _isLoading = false;
        });
      }
    } catch (e) {
      log("FloatingChatButton: loadRooms error - $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleExpanded() {
    if (_isExpanded) {
      setState(() {
        _isExpanded = false;
        _activeRoomId = null;
        _activeMessages = [];
      });
    } else {
      setState(() => _isExpanded = true);
      _loadRooms();
    }
  }

  void _openRoomChat(ChatRoomPreviewModel room) {
    setState(() {
      _activeRoomId = room.roomId;
      _loadingMessages = true;
      _hasMoreMessages = true;
      _loadMoreLoading = false;
      _messagesCursor = null;
    });
    _loadRoomMessages(room.roomId);
  }

  void _exitRoomChat() {
    setState(() {
      _activeRoomId = null;
      _activeMessages = [];
    });
  }

  Future<void> _loadRoomMessages(int roomId, {bool isLoadMore = false}) async {
    try {
      final msgs = await ChatService.getMessages(
        roomId: roomId,
        cursor: isLoadMore ? _messagesCursor : null,
      );
      if (mounted && _activeRoomId == roomId) {
        setState(() {
          if (isLoadMore) {
            _activeMessages.addAll(msgs.reversed.toList());
            _loadMoreLoading = false;
          } else {
            _activeMessages = msgs.reversed.toList();
            _loadingMessages = false;
          }
          _hasMoreMessages = msgs.length >= 50;
          if (msgs.isNotEmpty) {
            _messagesCursor = msgs.first.id;
          }
          _jumpToBottom();
        });
        if (!isLoadMore) {
          ChatService.markAsRead(roomId);
        }
      }
    } catch (e) {
      log("FloatingChatButton: load messages error - $e");
      if (mounted && _activeRoomId == roomId) {
        setState(() {
          _loadingMessages = false;
          _loadMoreLoading = false;
        });
      }
    }
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_messagesScrollController.hasClients) {
        _messagesScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _loadMoreMessages() {
    if (_activeRoomId == null || _loadMoreLoading || !_hasMoreMessages) return;
    setState(() => _loadMoreLoading = true);
    _loadRoomMessages(_activeRoomId!, isLoadMore: true);
  }

  Future<void> _sendMessage(String content) async {
    if (_activeRoomId == null || _sendingMessage) return;
    final clientMsgId = '${DateTime.now().millisecondsSinceEpoch}_${content.hashCode}';
    setState(() => _sendingMessage = true);
    try {
      final sent = await ChatService.sendMessage(
        roomId: _activeRoomId!,
        content: content,
        clientMessageId: clientMsgId,
      );
      if (mounted) {
        setState(() {
          if (!_activeMessages.any((m) => m.clientMessageId == sent.clientMessageId)) {
            _activeMessages.add(sent);
          }
          _sendingMessage = false;
        });
      }
    } catch (e) {
      log("FloatingChatButton: send message error - $e");
      if (mounted) {
        setState(() => _sendingMessage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gửi tin nhắn thất bại: $e')),
        );
      }
    }
  }

  int _getCurrentUserId() {
    final user = AuthService.currentUserCached;
    return user?.id ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 20,
      bottom: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isExpanded) _buildExpandedPanel(),
          const SizedBox(height: 12),
          _buildMainButton(),
        ],
      ),
    );
  }

  Widget _buildMainButton() {
    final showPulse = _hasNewMessage && _totalUnread > 0;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: showPulse ? _pulseAnimation.value : 1.0,
          child: child,
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(28),
            color: widget.primaryColor,
            child: InkWell(
              onTap: _toggleExpanded,
              borderRadius: BorderRadius.circular(28),
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: AnimatedRotation(
                  turns: _isExpanded ? 0.125 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _isExpanded ? Icons.close_rounded : Icons.chat_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
          if (_totalUnread > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                constraints: const BoxConstraints(minWidth: 20),
                child: Text(
                  _totalUnread > 99 ? '99+' : _totalUnread.toString(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpandedPanel() {
    return Container(
      width: 360,
      height: 420,
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _activeRoomId != null
              ? _buildRoomChatContent()
              : _buildRoomListContent(),
        ),
      ),
    );
  }

  Widget _buildRoomChatContent() {
    return SizedBox(
      key: const ValueKey('room_chat'),
      width: 360,
      height: 420,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: widget.primaryColor.withValues(alpha: 0.06),
              border: Border(bottom: BorderSide(color: _border, width: 0.5)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _exitRoomChat,
                  icon: Icon(Icons.arrow_back_rounded, size: 20, color: widget.primaryColor),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _getParticipantDisplayName(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: widget.primaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_activeRoom?.contextBadge.isNotEmpty ?? false) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: widget.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _activeRoom!.contextBadge,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: widget.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (_hasMoreMessages)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: GestureDetector(
                            onTap: _loadMoreMessages,
                            child: Text(
                              'Xem tin nhắn cũ hơn',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: widget.primaryColor,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Messages
          Expanded(
            child: _loadingMessages
                ? Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: widget.primaryColor),
                  )
                : _activeMessages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded,
                                size: 36, color: _textMedium.withValues(alpha: 0.5)),
                            const SizedBox(height: 8),
                            Text(
                              'Bắt đầu cuộc trò chuyện',
                              style: TextStyle(fontSize: 13, color: _textMedium.withValues(alpha: 0.7)),
                            ),
                          ],
                        ),
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollUpdateNotification &&
                              notification.metrics.pixels <= 0 &&
                              !_loadMoreLoading &&
                              _hasMoreMessages) {
                            _loadMoreMessages();
                          }
                          return false;
                        },
                        child: ListView.builder(
                          controller: _messagesScrollController,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          itemCount: _activeMessages.length + (_loadMoreLoading ? 1 : 0),
                          itemBuilder: (context, i) {
                            if (_loadMoreLoading && i == _activeMessages.length) {
                              return const Padding(
                                padding: EdgeInsets.all(8),
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              );
                            }
                            final msg = _activeMessages[_activeMessages.length - 1 - i];
                            final isMe = msg.senderId == _getCurrentUserId();
                            return Padding(
                              padding: EdgeInsets.only(
                                left: isMe ? 48 : 12,
                                right: isMe ? 12 : 48,
                                top: 4,
                                bottom: 4,
                              ),
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  if (!isMe)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 12, bottom: 2),
                                      child: Text(
                                        msg.senderName,
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: widget.primaryColor),
                                      ),
                                    ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isMe ? widget.primaryColor : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(16),
                                        topRight: const Radius.circular(16),
                                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                                        bottomRight: Radius.circular(isMe ? 4 : 16),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          msg.content,
                                          style: TextStyle(
                                            fontSize: 14,
                                            height: 1.4,
                                            color: isMe ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isMe ? const Color(0xFFE0E0E0) : _textMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
          // Input
          _buildChatInput(),
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    bool hasText = false;

    return StatefulBuilder(
      builder: (context, setInputState) {
        controller.addListener(() {
          final v = controller.text.trim().isNotEmpty;
          if (v != hasText) {
            setInputState(() => hasText = v);
          }
        });

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: _border, width: 1)),
          ),
          child: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: focusNode.hasFocus ? widget.primaryColor : _border,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      maxLines: null,
                      style: const TextStyle(fontSize: 15, color: _textDark),
                      decoration: InputDecoration(
                        hintText: _getInputHint(),
                        hintStyle: const TextStyle(fontSize: 15, color: Color(0xFF94A3B8)),
                        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (text) {
                        if (text.trim().isNotEmpty && !_sendingMessage) {
                          _sendMessage(text.trim());
                          controller.clear();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Material(
                  color: hasText ? widget.primaryColor : _border,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: () {
                      if (hasText && !_sendingMessage) {
                        _sendMessage(controller.text.trim());
                        controller.clear();
                      }
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: _sendingMessage
                          ? Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.send_rounded,
                              color: hasText ? Colors.white : const Color(0xFF94A3B8),
                              size: 22,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoomListContent() {
    return SizedBox(
      key: const ValueKey('room_list'),
      width: 360,
      height: 420,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.primaryColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.chat_rounded, color: widget.primaryColor, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Tin nhắn',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textDark),
                  ),
                ),
                if (_totalUnread > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_totalUnread',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          // Content
          Flexible(
            child: _isLoading
                ? _buildLoadingState()
                : _rooms.isEmpty
                    ? _buildEmptyState()
                    : _buildRoomsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: widget.primaryColor),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 40, color: _textMedium.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            'Chưa có cuộc trò chuyện nào',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _textMedium),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _getEmptyStateSubtitle(),
            style: TextStyle(fontSize: 12, color: _textMedium.withValues(alpha: 0.7)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  ChatRoomPreviewModel? get _activeRoom {
    if (_activeRoomId == null) return null;
    try {
      return _rooms.firstWhere((r) => r.roomId == _activeRoomId);
    } catch (_) {
      return null;
    }
  }

  String _getParticipantDisplayName() {
    return _activeRoom?.displayName ?? (widget.rolePrefix == 'mentor' ? 'Học viên' : 'Mentor');
  }

  String _getInputHint() {
    if (widget.rolePrefix == 'mentor') {
      return 'Nhắn tin học viên...';
    }
    return 'Nhắn tin...';
  }

  String _getEmptyStateSubtitle() {
    if (widget.rolePrefix == 'employee') {
      return 'Nhắn tin với mentor từ khóa học của bạn';
    } else {
      return 'Học viên sẽ chat với bạn từ khóa học';
    }
  }

  Widget _buildRoomsList() {
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: _rooms.length > 5 ? 5 : _rooms.length,
      itemBuilder: (context, index) {
        final room = _rooms[index];
        return _buildRoomItem(room);
      },
    );
  }

  Widget _buildRoomItem(ChatRoomPreviewModel room) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openRoomChat(room),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _border, width: 0.5))),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    room.participantInitials,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: widget.primaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            room.displayName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: room.hasUnread ? FontWeight.w700 : FontWeight.w600,
                              color: _textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (room.contextBadge.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: widget.primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              room.contextBadge,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: widget.primaryColor,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          room.formattedTime,
                          style: TextStyle(
                            fontSize: 11,
                            color: room.hasUnread ? widget.primaryColor : _textMedium.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            room.messagePreview,
                            style: TextStyle(
                              fontSize: 13,
                              color: room.hasUnread ? _textDark : _textMedium.withValues(alpha: 0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (room.hasUnread)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${room.unreadCount}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
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
}
