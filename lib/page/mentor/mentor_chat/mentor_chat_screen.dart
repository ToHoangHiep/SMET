import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smet/model/chat/chat_models.dart';
import 'package:smet/service/chat/chat_service.dart';
import 'package:smet/service/chat/websocket_service.dart';
import 'package:smet/service/common/auth_service.dart';

class MentorChatColors {
  static const Color bgList = Color(0xFFFDFBFD); 
  static const Color bgChat = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF333333);
  static const Color textMuted = Color(0xFF7A7A7A);
  static const Color bubbleMe = Color(0xFF635A6C); // Dark warm grey from image
  static const Color bubbleOther = Color(0xFFEBE5F2); // Light lavender
  static const Color inputBg = Color(0xFFEAE4F0); 
  static const Color primaryAccent = Color(0xFF635A6C);
}

class MentorChatScreen extends StatefulWidget {
  const MentorChatScreen({super.key});

  @override
  State<MentorChatScreen> createState() => _MentorChatScreenState();
}

class _MentorChatScreenState extends State<MentorChatScreen> {
  // Common State
  bool _isLoadingRooms = true;
  String? _errorRooms;
  List<ChatRoomPreviewModel> _rooms = [];
  int? _selectedRoomId;
  int _currentUserId = 0;

  // Selected Room State
  List<ChatMessageModel> _messages = [];
  bool _isLoadingMessages = false;
  String? _errorMessages;
  bool _isSending = false;
  
  // Input
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Subscriptions
  StreamSubscription<ChatRoomUpdate>? _roomSub;
  StreamSubscription<ChatMessageModel>? _msgSub;

  ChatConnectionService get _wsService => ChatConnectionService.instance;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _roomSub?.cancel();
    _msgSub?.cancel();
    if (_selectedRoomId != null) {
      _wsService.unsubscribeFromRoom(_selectedRoomId!);
    }
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    try {
      final user = await AuthService.getCurrentUser();
      _currentUserId = user.id;

      await _loadRooms();
      _subscribeToWebSocket();
    } catch (e) {
      log("MentorChatScreen: initData error - $e");
      if (mounted) {
        setState(() {
          _errorRooms = 'Không thể khởi tạo dữ liệu chat';
          _isLoadingRooms = false;
        });
      }
    }
  }

  Future<void> _loadRooms() async {
    try {
      final rooms = await ChatService.getMyRooms();
      if (mounted) {
        setState(() {
          _rooms = rooms;
          _isLoadingRooms = false;
          _errorRooms = null;
        });
      }
    } catch (e) {
      log("MentorChatScreen: loadRooms error - $e");
      if (mounted) {
        setState(() {
          _errorRooms = 'Không thể tải danh sách chat';
          _isLoadingRooms = false;
        });
      }
    }
  }

  void _subscribeToWebSocket() {
    _wsService.connect();

    // Rooms update
    _roomSub = _wsService.roomUpdateStream.listen((update) {
      if (!mounted) return;
      setState(() {
        final idx = _rooms.indexWhere((r) => r.roomId == update.roomId);
        if (idx != -1) {
          final isSelected = update.roomId == _selectedRoomId;
          final prevCount = _rooms[idx].unreadCount;
          
          _rooms[idx] = _rooms[idx].copyWith(
            lastMessage: update.lastMessage,
            lastMessageTime: update.lastMessageTime,
            // If active room, never increase unread count locally (we are reading it)
            unreadCount: isSelected ? 0 : (prevCount + 1),
          );
          
          // Move updated room to top
          final updated = _rooms.removeAt(idx);
          _rooms.insert(0, updated);

          if (isSelected) {
            ChatService.markAsRead(_selectedRoomId!);
          }
        } else {
           _loadRooms(); // complete refresh if unseen room arrives
        }
      });
    });

    // Messages
    _msgSub = _wsService.messageStream.listen((message) {
      if (!mounted) return;
      if (message.roomId == _selectedRoomId && message.senderId != _currentUserId) {
        setState(() {
          if (!_messages.any((m) => m.id == message.id)) {
            _messages.add(message);
          }
        });
        _scrollToBottom();
        ChatService.markAsRead(_selectedRoomId!);
      }
    });
  }

  Future<void> _selectRoom(ChatRoomPreviewModel room) async {
    if (_selectedRoomId == room.roomId) return; // Already selected

    // Unsubscribe previous
    if (_selectedRoomId != null) {
      _wsService.unsubscribeFromRoom(_selectedRoomId!);
    }

    setState(() {
      _selectedRoomId = room.roomId;
      _messages = [];
      _isLoadingMessages = true;
      _errorMessages = null;
      
      // Clear unread mark locally
      final idx = _rooms.indexWhere((r) => r.roomId == room.roomId);
      if (idx != -1) {
         _rooms[idx] = _rooms[idx].copyWith(unreadCount: 0);
      }
    });

    _wsService.subscribeToRoom(room.roomId);

    try {
      final messages = await ChatService.getMessages(roomId: room.roomId);
      await ChatService.markAsRead(room.roomId);

      if (mounted && _selectedRoomId == room.roomId) {
        setState(() {
          _messages = messages.reversed.toList();
          _isLoadingMessages = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
       log("MentorChatScreen: loadMessages error - $e");
       if (mounted && _selectedRoomId == room.roomId) {
         setState(() {
           _errorMessages = "Không thể tải tin nhắn";
           _isLoadingMessages = false;
         });
       }
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

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _selectedRoomId == null || _isSending) return;

    setState(() {
      _isSending = true;
    });

    // Optimistic UI could be added here, but going simple via reliable API
    _msgController.clear();

    try {
      final clientMessageId = DateTime.now().millisecondsSinceEpoch.toString();
      final message = await ChatService.sendMessage(
        roomId: _selectedRoomId!,
        content: text,
        clientMessageId: clientMessageId,
      );

      if (mounted && _selectedRoomId == message.roomId) {
        setState(() {
          _messages.add(message);
          _isSending = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      log("MentorChatScreen: _sendMessage error - $e");
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không thể gửi tin nhắn"), backgroundColor: Colors.red),
        );
        _msgController.text = text; // Return text on error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MentorChatColors.bgChat,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 768;
          
          if (isMobile) {
            // Adaptive mobile view
            if (_selectedRoomId != null) {
              return _buildRightPanel(isMobile: true);
            } else {
              return Container(
                color: MentorChatColors.bgList,
                child: _buildLeftPanel(),
              );
            }
          }

          // Desktop/Tablet Split View
          return Row(
            children: [
              Container(
                width: 350,
                color: MentorChatColors.bgList,
                child: _buildLeftPanel(),
              ),
              Expanded(
                child: _buildRightPanel(isMobile: false),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============== LEFT PANEL ==============
  Widget _buildLeftPanel() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 32.0, left: 24.0, right: 24.0, bottom: 20.0),
            child: Text(
              "DANH SÁCH",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: MentorChatColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: _isLoadingRooms 
              ? const Center(child: CircularProgressIndicator(color: MentorChatColors.primaryAccent))
              : _errorRooms != null 
                ? Center(child: Text(_errorRooms!, style: const TextStyle(color: Colors.red)))
                : _rooms.isEmpty
                  ? const Center(child: Text("Chưa có tin nhắn nào", style: TextStyle(color: MentorChatColors.textMuted)))
                  : ListView.builder(
                      itemCount: _rooms.length,
                      itemBuilder: (context, index) {
                        return _buildRoomItem(_rooms[index]);
                      },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomItem(ChatRoomPreviewModel room) {
    final isSelected = _selectedRoomId == room.roomId;
    // Hiển thị: Tên người gửi + Tên khóa học (contextName)
    String displayName = room.participantName ?? 'Không rõ';
    if (room.contextName != null && room.contextName!.isNotEmpty) {
      displayName = '$displayName - ${room.contextName}';
    }
    String subtitle = room.lastMessage ?? "Hỗ trợ dự án/khóa học";

    final timeString = room.lastMessageTime != null 
      ? _formatTime(room.lastMessageTime!)
      : "";

    return InkWell(
      onTap: () => _selectRoom(room),
      child: Container(
        color: isSelected ? MentorChatColors.inputBg.withValues(alpha: 0.5) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Safe Icon / Avatar matching the image roughly
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: MentorChatColors.inputBg,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.architecture, color: MentorChatColors.textMuted, size: 20),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: MentorChatColors.textDark,
                        ),
                      ),
                      Text(
                        timeString,
                        style: const TextStyle(
                          fontSize: 11,
                          color: MentorChatColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: room.unreadCount > 0 ? MentorChatColors.textDark : MentorChatColors.textMuted,
                            fontWeight: room.unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (room.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: MentorChatColors.primaryAccent,
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
    );
  }

  // ============== RIGHT PANEL ==============
  Widget _buildRightPanel({required bool isMobile}) {
    if (_selectedRoomId == null) {
      return Container(
        decoration: const BoxDecoration(
          color: MentorChatColors.bgChat,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(32)),
        ),
        child: const Center(
          child: Text(
            "Chọn một đoạn chat để bắt đầu",
            style: TextStyle(color: MentorChatColors.textMuted, fontSize: 16),
          ),
        ),
      );
    }

    final activeRoom = _rooms.firstWhere(
      (r) => r.roomId == _selectedRoomId,
      orElse: () => ChatRoomPreviewModel(roomId: _selectedRoomId!, contextType: 'COURSE', unreadCount: 0)
    );

    return Container(
      decoration: BoxDecoration(
        color: MentorChatColors.bgChat,
        borderRadius: isMobile ? BorderRadius.zero : const BorderRadius.only(
          topLeft: Radius.circular(32),
        ),
        boxShadow: isMobile ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            offset: const Offset(-4, 0),
            blurRadius: 16,
          )
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildChatHeader(isMobile, activeRoom),
            Expanded(child: _buildChatMessages()),
            _buildChatInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatHeader(bool isMobile, ChatRoomPreviewModel room) {
    return Padding(
      padding: const EdgeInsets.only(top: 32, left: 24, right: 24, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (isMobile)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _selectedRoomId = null;
                    });
                  },
                ),
              const Text(
                "Đoạn Chat", // Or dynamic name mapping based on ContextType
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: MentorChatColors.textDark,
                ),
              ),
            ],
          ),
          const Icon(Icons.arrow_back, color: MentorChatColors.textDark, size: 24),
        ],
      ),
    );
  }

  Widget _buildChatMessages() {
    if (_isLoadingMessages) {
      return const Center(child: CircularProgressIndicator(color: MentorChatColors.primaryAccent));
    }
    if (_errorMessages != null) {
      return Center(child: Text(_errorMessages!, style: const TextStyle(color: Colors.red)));
    }
    if (_messages.isEmpty) {
      return const Center(
        child: Text(
          "Chưa có tin nhắn.",
          style: TextStyle(color: MentorChatColors.textMuted),
        )
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isMe = msg.senderId == _currentUserId;

        // check sequence for bottom corners
        final isLastInGroup = index == _messages.length - 1 || _messages[index + 1].senderId != msg.senderId;

        return _buildMessageBubble(msg, isMe, isLastInGroup);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessageModel msg, bool isMe, bool isLastInGroup) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLastInGroup ? 20 : 6),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            Container(
              margin: const EdgeInsets.only(right: 12),
              width: 36,
              height: 36,
              decoration: isLastInGroup ? const BoxDecoration(
                color: MentorChatColors.inputBg,
                shape: BoxShape.circle,
              ) : null,
              child: isLastInGroup ? const Center(
                child: Icon(Icons.architecture, size: 18, color: MentorChatColors.textMuted),
              ) : null,
            ),
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isMe ? MentorChatColors.bubbleMe : MentorChatColors.bubbleOther,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomRight: isMe && isLastInGroup ? Radius.zero : const Radius.circular(20),
                  bottomLeft: !isMe && isLastInGroup ? Radius.zero : const Radius.circular(20),
                ),
              ),
              child: Text(
                msg.content,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isMe ? Colors.white : MentorChatColors.textDark,
                ),
              ),
            ),
          ),

          if (isMe)
            const SizedBox(width: 48), // Padding equivalent to other side
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Row(
        children: [
           GestureDetector(
             onTap: _showEmojiPicker,
             child: const Icon(Icons.sentiment_satisfied_rounded, size: 28, color: MentorChatColors.textDark),
           ),
           const SizedBox(width: 16),
           Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: MentorChatColors.inputBg,
                borderRadius: BorderRadius.circular(26),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.menu, color: MentorChatColors.textDark, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: const InputDecoration(
                        hintText: "",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  _isSending 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: MentorChatColors.textDark))
                    : InkWell(
                        onTap: _sendMessage,
                        child: const Icon(Icons.search, color: MentorChatColors.textDark, size: 24),
                      ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      if (difference.inMinutes <= 0) return "V.xong";
      if (difference.inMinutes < 60) return "${difference.inMinutes} min";
      return DateFormat('HH:mm').format(time);
    } else if (difference.inDays == 1) {
      return "H.qua";
    }
    return DateFormat('dd/MM').format(time);
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Chọn biểu tượng cảm xúc",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: MentorChatColors.textDark),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                '😀','😃','😄','😁','😆','😅','🤣','😂','🙂','🙃',
                '😉','😊','😇','🥰','😍','🤩','😘','😗','😚','😙',
                '🥲','😋','😛','😜','🤪','😝','🤑','🤗','🤭','🤫',
                '🤔','🤐','🤨','😐','😑','😶','😏','😒','🙄','😬',
                '😌','😔','😪','🤤','😴','😷','🤒','🤕','🤢','🤮',
                '👍','👎','👏','🙌','🤝','🙏','💪','🤘','🤙','✌️',
              ].map((emoji) => GestureDetector(
                onTap: () {
                  _msgController.text += emoji;
                  Navigator.pop(context);
                },
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              )).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

}
