import 'package:flutter/material.dart';

class LessonHeader extends StatelessWidget {
  final String title;
  final int durationMinutes;
  final String level;
  final String lessonId;
  final bool isCompleted;
  final VoidCallback onMarkComplete;

  const LessonHeader({
    super.key,
    required this.title,
    required this.durationMinutes,
    required this.level,
    required this.lessonId,
    this.isCompleted = false,
    required this.onMarkComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        // Meta info
        Row(
          children: [
            _buildMetaItem(Icons.schedule, '$durationMinutes phút'),
            const SizedBox(width: 20),
            _buildMetaItem(Icons.trending_up, level),
          ],
        ),
        const SizedBox(height: 20),
        // 操作区：仅「Hoàn thành」；quiz 在侧边栏模块末尾「Kiểm tra Module」进入
        Row(
          children: [
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: isCompleted ? null : onMarkComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted
                      ? const Color(0xFF22C55E)
                      : const Color(0xFF137FEC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                icon: Icon(
                  isCompleted ? Icons.check_circle : Icons.check_circle,
                  size: 20,
                ),
                label: Text(
                  isCompleted ? 'Đã hoàn thành' : 'Hoàn thành',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetaItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
