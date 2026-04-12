import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/chat/chat_models.dart';
import 'package:smet/page/chat/widgets/message_bubble.dart';
import 'package:smet/page/chat/widgets/chat_input.dart';
import 'package:smet/service/chat/chat_service.dart';
import 'package:smet/service/chat/websocket_service.dart';
import 'package:smet/service/common/auth_service.dart';
import 'dart:developer';
import 'dart:async';

/// Chat Page - Màn hình chat chính với danh sách tin nhắn
class ChatPage extends StatefulWidget {
  final int roomId;
  final Color primaryColor;
  final String rolePrefix;

  const ChatPage({
    super.key,
    required this.roomId,
    this.primaryColor = const Color(0xFF137FEC),
    required this.rolePrefix,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // Colors
  static const _bgPage = Color(0xFFF3F6FC);
  static const _bgCard = Color(0xFFFFFFFF);
  static const _border = Color(0xFFE5E7EB);
  static const _textDark = Color(0xFF0F172A);

  // State
  List<ChatMessageModel> _messages = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isSending = false;
  String? _error;
  int _currentUserId = 0;
  int? _lastMessageId;
  bool _hasMore = true;

  // Controllers
  final ScrollController _scrollController = ScrollController();

  // Stream subscriptions - MUST dispose to prevent leaks
  StreamSubscription<ChatMessageModel>? _messageSubscription;

  // WebSocket
  ChatConnectionService get _wsService => ChatConnectionService.instance;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initData();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _wsService.unsubscribeFromRoom(widget.roomId);
    ChatService.markAsRead(widget.roomId);
    super.dispose();
  }

  Future<void> _initData() async {
    try {
      final user = await AuthService.getCurrentUser();
      _currentUserId = user.id;
      await _loadMessages();
      _subscribeToWebSocket();
      // Mark as read
      await ChatService.markAsRead(widget.roomId);
    } catch (e) {
      log("ChatPage: initData error - $e");
      if (mounted) {
        setState(() {
          _error = 'Không thể tải tin nhắn';
          _isLoading = false;
        });
      }
    }
  }

  void _subscribeToWebSocket() {
    _wsService.subscribeToRoom(widget.roomId);
    _messageSubscription = _wsService.messageStream.listen((message) {
      if (!mounted) return;
      if (message.roomId == widget.roomId && message.senderId != _currentUserId) {
        setState(() {
          // Avoid duplicate messages
          if (!_messages.any((m) => m.id == message.id)) {
            _messages.add(message);
          }
        });
        _scrollToBottom();
        ChatService.markAsRead(widget.roomId);
      }
    });
  }

  Future<void> _loadMessages({bool loadMore = false}) async {
    if (loadMore) {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final messages = await ChatService.getMessages(
        roomId: widget.roomId,
        cursor: loadMore ? _lastMessageId : null,
      );

      if (mounted) {
        setState(() {
          if (loadMore) {
            _messages.insertAll(0, messages);
            _isLoadingMore = false;
          } else {
            _messages = messages.reversed.toList();
          }
          if (messages.isNotEmpty) {
            _lastMessageId = messages.first.id;
          }
          _hasMore = messages.length >= 50;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      log("ChatPage: loadMessages error - $e");
      if (mounted) {
        setState(() {
          _error = 'Không thể tải tin nhắn';
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels <= 50 && !_isLoadingMore && _hasMore) {
      _loadMessages(loadMore: true);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String content) async {
    if (_isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final clientMessageId = DateTime.now().millisecondsSinceEpoch.toString();
      final message = await ChatService.sendMessage(
        roomId: widget.roomId,
        content: content,
        clientMessageId: clientMessageId,
      );

      if (mounted) {
        setState(() {
          _messages.add(message);
          _isSending = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      log("ChatPage: sendMessage error - $e");
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Không thể gửi tin nhắn'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildContent()),
          ChatInput(
            onSend: _sendMessage,
            isLoading: _isSending,
            primaryColor: widget.primaryColor,
            hintText: 'Nhập tin nhắn...',
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgCard,
        border: Border(
          bottom: BorderSide(color: _border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Back button
            Material(
              color: _bgPage,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => context.go('/${widget.rolePrefix}/chat'),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: _textDark,
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  'M',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: widget.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mentor',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Đang hoạt động',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // More options
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.more_vert_rounded,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return ChatLoadingIndicator(primaryColor: widget.primaryColor);
    }

    if (_error != null && _messages.isEmpty) {
      return _buildErrorState();
    }

    if (_messages.isEmpty) {
      return ChatEmptyState(
        primaryColor: widget.primaryColor,
      );
    }

    return Container(
      color: _bgPage,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: _messages.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (_isLoadingMore && index == 0) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.primaryColor,
                  ),
                ),
              ),
            );
          }

          final messageIndex = _isLoadingMore ? index - 1 : index;
          final message = _messages[messageIndex];
          final isMe = message.senderId == _currentUserId;

          // Check if we should show date separator
          final showDateSeparator = _shouldShowDateSeparator(messageIndex);

          return Column(
            children: [
              if (showDateSeparator != null)
                DateSeparator(
                  date: showDateSeparator,
                  primaryColor: widget.primaryColor,
                ),
              MessageBubble(
                message: message,
                isMe: isMe,
                primaryColor: widget.primaryColor,
              ),
            ],
          );
        },
      ),
    );
  }

  DateTime? _shouldShowDateSeparator(int index) {
    if (index >= _messages.length) return null;

    final message = _messages[index];
    final messageDate = DateTime(
      message.createdAt.year,
      message.createdAt.month,
      message.createdAt.day,
    );

    if (index == 0) {
      return messageDate;
    }

    final prevMessage = _messages[index - 1];
    final prevDate = DateTime(
      prevMessage.createdAt.year,
      prevMessage.createdAt.month,
      prevMessage.createdAt.day,
    );

    if (messageDate.isAfter(prevDate)) {
      return messageDate;
    }

    return null;
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
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadMessages();
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
