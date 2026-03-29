import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget mới — Hiển thị deadline info + share.
/// Nằm bên dưới EnrollCard trong cột phải.
class CourseInfoCard extends StatelessWidget {
  final String? deadlineType;
  final int? defaultDeadlineDays;
  final String? fixedDeadline;
  final VoidCallback? onShare;
  final String? courseTitle;

  const CourseInfoCard({
    super.key,
    this.deadlineType,
    this.defaultDeadlineDays,
    this.fixedDeadline,
    this.onShare,
    this.courseTitle,
  });

  String get _deadlineText {
    if (fixedDeadline != null && fixedDeadline!.isNotEmpty) {
      return 'Hạn chót: $fixedDeadline';
    }
    if (defaultDeadlineDays != null) {
      return 'Hạn chót: $defaultDeadlineDays ngày sau khi đăng ký';
    }
    return 'Không có giới hạn thời gian';
  }

  @override
  Widget build(BuildContext context) {
    final hasDeadlineInfo =
        fixedDeadline != null || defaultDeadlineDays != null;

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
          // ─── Deadline ───
          if (hasDeadlineInfo) ...[
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.schedule,
                    size: 16,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thời hạn hoàn thành',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      Text(
                        _deadlineText,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // ─── Share button ───
          if (onShare != null)
            InkWell(
              onTap: () async {
                onShare?.call();
                if (courseTitle != null) {
                  await Clipboard.setData(
                    ClipboardData(text: courseTitle!),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã sao chép tên khóa học!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.share_outlined,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Chia sẻ khóa học',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
