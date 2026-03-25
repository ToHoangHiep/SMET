import 'package:flutter/material.dart';
import 'package:smet/model/Employee_learning_model.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // About this lesson
        const Text(
          'Về bài học này',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        // Description
        Text(
          description,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF475569),
            height: 1.7,
          ),
        ),
        const SizedBox(height: 24),
        // Key Takeaways
        const Text(
          'Kiến thức chính:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        ...keyTakeaways.asMap().entries.map((entry) {
          final index = entry.key;
          final takeaway = entry.value;
          return _buildTakeawayItem(index + 1, takeaway);
        }),
      ],
    );
  }

  Widget _buildTakeawayItem(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
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
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF475569),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DiscussionTab extends StatelessWidget {
  final List<Discussion> discussions;
  final Function(String) onPostComment;

  const DiscussionTab({
    super.key,
    required this.discussions,
    required this.onPostComment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Comment input
        _buildCommentInput(context),
        const SizedBox(height: 24),
        // Discussions list
        ...discussions.map((discussion) => _buildDiscussionItem(discussion)),
      ],
    );
  }

  Widget _buildCommentInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đặt câu hỏi hoặc chia sẻ suy nghĩ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Viết bình luận của bạn...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => onPostComment('New comment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF137FEC),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Gửi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscussionItem(Discussion discussion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFE2E8F0),
                backgroundImage:
                    discussion.avatarUrl != null
                        ? NetworkImage(discussion.avatarUrl!)
                        : null,
                child:
                    discussion.avatarUrl == null
                        ? const Icon(
                          Icons.person,
                          size: 16,
                          color: Color(0xFF94A3B8),
                        )
                        : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      discussion.userName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      discussion.timeAgo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Comment
          Text(
            discussion.comment,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF475569),
              height: 1.5,
            ),
          ),
          // Reply count
          if (discussion.replyCount > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.reply, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  '${discussion.replyCount} trả lời',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class ResourcesTab extends StatelessWidget {
  final List<LessonResource> resources;

  const ResourcesTab({super.key, required this.resources});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tài liệu bài học',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 16),
        ...resources.map((resource) => _buildResourceItem(resource)),
      ],
    );
  }

  Widget _buildResourceItem(LessonResource resource) {
    final IconData icon;
    final Color color;

    switch (resource.type) {
      case 'pdf':
        icon = Icons.picture_as_pdf;
        color = const Color(0xFFEF4444);
        break;
      case 'link':
        icon = Icons.link;
        color = const Color(0xFF3B82F6);
        break;
      case 'video':
        icon = Icons.videocam;
        color = const Color(0xFF8B5CF6);
        break;
      default:
        icon = Icons.insert_drive_file;
        color = const Color(0xFF64748B);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          resource.title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        subtitle:
            resource.fileSize != null
                ? Text(
                  resource.fileSize!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                )
                : null,
        trailing: Icon(
          resource.type == 'link' ? Icons.open_in_new : Icons.download,
          color: const Color(0xFF64748B),
        ),
      ),
    );
  }
}

class TranscriptTab extends StatelessWidget {
  final String? transcript;

  const TranscriptTab({super.key, this.transcript});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bản phụ đề',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Text(
            transcript ?? 'Không có bản phụ đề',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF475569),
              height: 1.7,
            ),
          ),
        ),
      ],
    );
  }
}
