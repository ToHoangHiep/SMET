import 'package:flutter/material.dart';
import 'package:smet/model/learning_model.dart';

class ResourcesSidebar extends StatelessWidget {
  final List<LessonResource> resources;
  final Lesson? nextLesson;
  final Function(Lesson)? onJumpToLesson;

  const ResourcesSidebar({
    super.key,
    required this.resources,
    this.nextLesson,
    this.onJumpToLesson,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resources Card
        _buildResourcesCard(),
        const SizedBox(height: 20),
        // Up Next Card
        if (nextLesson != null) _buildUpNextCard(),
      ],
    );
  }

  Widget _buildResourcesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.attach_file,
                size: 20,
                color: Color(0xFF137FEC),
              ),
              const SizedBox(width: 8),
              const Text(
                'Tài liệu bài học',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Resources list
          ...resources.map((resource) => _buildResourceItem(resource)),
        ],
      ),
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
      default:
        icon = Icons.insert_drive_file;
        color = const Color(0xFF64748B);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Icon(icon, color: color, size: 20),
        title: Text(
          resource.title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: resource.fileSize != null
            ? Text(
                resource.fileSize!,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              )
            : null,
        trailing: Icon(
          resource.type == 'link' ? Icons.open_in_new : Icons.download,
          size: 16,
          color: const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildUpNextCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF137FEC),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF137FEC).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          const Text(
            'TIẾP THEO',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          // Next lesson title
          Text(
            nextLesson!.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          // Jump button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => onJumpToLesson?.call(nextLesson!),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF137FEC),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Chuyển đến bài học',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
