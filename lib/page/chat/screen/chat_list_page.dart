import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/chat/chat_models.dart';
import 'package:smet/page/chat/widgets/chat_list_item.dart';
import 'package:smet/page/chat/widgets/message_bubble.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/service/chat/chat_service.dart';
import 'package:smet/service/chat/websocket_service.dart';
import 'dart:developer';
import 'dart:async';

/// Chat List Page - Danh sách cuộc trò chuyện
class ChatListPage extends StatefulWidget {
  final Color primaryColor;
  final String rolePrefix; // 'employee' hoặc 'mentor'

  const ChatListPage({
    super.key,
    this.primaryColor = const Color(0xFF137FEC),
    required this.rolePrefix,
  });

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  // Colors
  static const _bgPage = Color(0xFFF3F6FC);
  static const _bgCard = Color(0xFFFFFFFF);
  static const _border = Color(0xFFE5E7EB);
  static const _textDark = Color(0xFF0F172A);
  static const _textMedium = Color(0xFF64748B);

  // State
  List<ChatRoomPreviewModel> _rooms = [];
  bool _isLoading = true;
  String? _error;
  int _totalUnread = 0;

  // Stream subscriptions
  StreamSubscription<ChatRoomUpdate>? _roomUpdateSubscription;
  StreamSubscription<ChatMessageModel>? _messageSubscription;

  // WebSocket
  ChatConnectionService get _wsService => ChatConnectionService.instance;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _roomUpdateSubscription?.cancel();
    _messageSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initData() async {
    try {
      await _loadRooms();
      _subscribeToWebSocket();
    } catch (e) {
      log("ChatListPage: initData error - $e");
      if (mounted) {
        setState(() {
          _error = 'Không thể tải dữ liệu';
          _isLoading = false;
        });
      }
    }
  }

  void _subscribeToWebSocket() {
    _wsService.connect();

    // Listen for room preview updates → update locally without API call
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
          // Move updated room to top
          final updated = _rooms.removeAt(idx);
          _rooms.insert(0, updated);
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
          _error = null;
        });
      }
    } catch (e) {
      log("ChatListPage: loadRooms error - $e");
      if (mounted) {
        setState(() {
          _error = 'Không thể tải danh sách chat';
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToChat(int roomId) {
    context.go('/${widget.rolePrefix}/chat/$roomId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      body: Column(
        children: [
          _buildPageHeader(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: _bgPage,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SharedBreadcrumb(
              items: [
                BreadcrumbItem(
                  label: widget.rolePrefix == 'employee' ? 'Nhân viên' : 'Mentor',
                  route: '/${widget.rolePrefix}/dashboard',
                ),
                const BreadcrumbItem(label: 'Tin nhắn'),
              ],
              primaryColor: widget.primaryColor,
              fontSize: 13,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.chat_rounded,
                    color: widget.primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Tin nhắn',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                  ),
                ),
                if (_totalUnread > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_active_rounded,
                          color: widget.primaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_totalUnread tin nhắn mới',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: widget.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const ChatLoadingIndicator();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_rooms.isEmpty) {
      return ChatEmptyState(
        title: 'Chưa có cuộc trò chuyện',
        subtitle: 'Bắt đầu trò chuyện với mentor từ khóa học hoặc dự án của bạn',
        icon: Icons.forum_outlined,
        primaryColor: widget.primaryColor,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRooms,
      color: widget.primaryColor,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ListView.builder(
            itemCount: _rooms.length,
            itemBuilder: (context, index) {
              final room = _rooms[index];
              final participantName = 'Người dùng';

              return ChatListItem(
                room: room,
                participantName: participantName,
                primaryColor: widget.primaryColor,
                onTap: () => _navigateToChat(room.roomId),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Đã xảy ra lỗi',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Vui lòng kiểm tra kết nối và thử lại',
              style: TextStyle(
                fontSize: 14,
                color: _textMedium,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadRooms();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Thử lại',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
