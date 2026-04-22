import 'package:flutter/material.dart';
import 'package:smet/model/Employee_learning_model.dart';
import 'package:smet/model/chat/chat_message_model.dart';
import 'package:smet/service/common/global_notification_service.dart';
import 'package:smet/service/chat/chat_service.dart';

/// Lesson content tabs — modern Coursera-style:
/// - Overview: key takeaways with numbered circles + dividers
/// - Discussion: bubble-style comments with larger avatars
class LessonOverviewTab extends StatelessWidget {
  final String description;
  final List<String> keyTakeaways;

  const LessonOverviewTab({
    super.key,
    required this.description,
    required this.keyTakeaways,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF137FEC).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Color(0xFF137FEC),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Về bài học này',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF475569),
              height: 1.7,
            ),
          ),
          if (keyTakeaways.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  size: 20,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Kiến thức chính:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...keyTakeaways.asMap().entries.map((entry) {
              final index = entry.key;
              final takeaway = entry.value;
              return _buildTakeawayItem(index + 1, takeaway);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildTakeawayItem(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF137FEC).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF137FEC),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF475569),
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DiscussionTab extends StatefulWidget {
  final String lessonId;
  final String courseId;
  final List<Discussion> initialDiscussions;
  /// ID của mentor của khóa học hiện tại
  final int mentorId;
  /// Tên của mentor
  final String mentorName;

  const DiscussionTab({
    super.key,
    required this.lessonId,
    required this.courseId,
    this.initialDiscussions = const [],
    this.mentorId = 0,
    this.mentorName = 'Giảng viên',
  });

  @override
  State<DiscussionTab> createState() => _DiscussionTabState();
}

class _DiscussionTabState extends State<DiscussionTab> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int? _roomId;
  List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  bool _isPosting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRoomAndMessages();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchRoomAndMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final lessonIdInt = int.tryParse(widget.lessonId) ?? 0;

      // Tạo/lấy room với LESSON context và mentorId thực tế
      final roomId = await ChatService.createOrGetRoom(
        mentorId: widget.mentorId > 0 ? widget.mentorId : 0,
        contextType: ChatContextType.LESSON,
        contextId: lessonIdInt,
      );

      // Lấy messages
      final messages = await ChatService.getMessages(roomId: roomId);

      setState(() {
        _roomId = roomId;
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải bình luận';
        _isLoading = false;
      });
    }
  }

  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _roomId == null) return;

    setState(() {
      _isPosting = true;
    });

    try {
      final clientMessageId = '${DateTime.now().millisecondsSinceEpoch}_${content.hashCode}';
      final newMessage = await ChatService.sendMessage(
        roomId: _roomId!,
        content: content,
        clientMessageId: clientMessageId,
      );

      _commentController.clear();

      setState(() {
        _messages.insert(0, newMessage);
        _isPosting = false;
      });
    } catch (e) {
      setState(() {
        _isPosting = false;
      });
      if (mounted) {
        GlobalNotificationService.show(
          context: context,
          message: 'Không thể gửi bình luận',
          type: NotificationType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCommentInput(),
        const SizedBox(height: 20),
        _buildDiscussionsList(),
      ],
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF137FEC).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.edit,
                  size: 16,
                  color: Color(0xFF137FEC),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Đặt câu hỏi hoặc chia sẻ suy nghĩ',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _commentController,
            maxLines: 3,
            enabled: !_isPosting,
            decoration: InputDecoration(
              hintText: 'Viết bình luận của bạn...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: Color(0xFF137FEC), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _isPosting ? null : _postComment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF137FEC),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
                disabledBackgroundColor: const Color(0xFF137FEC).withValues(alpha: 0.5),
              ),
              child: _isPosting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Gửi bình luận',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscussionsList() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF137FEC)),
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.forum_outlined, size: 48, color: Color(0xFFCBD5E1)),
              SizedBox(height: 12),
              Text(
                'Diễn đàn bài học',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Đang được phát triển',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_messages.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: _messages.map((m) => _buildDiscussionItem(m)).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.forum_outlined, size: 48, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            Text(
              'Chưa có bình luận nào',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Hãy là người đầu tiên đặt câu hỏi!',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscussionItem(ChatMessageModel message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF137FEC).withValues(alpha: 0.1),
                child: const Icon(Icons.person, size: 20,
                    color: Color(0xFF137FEC)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.senderName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message.formattedTime,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              message.content,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF475569),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
