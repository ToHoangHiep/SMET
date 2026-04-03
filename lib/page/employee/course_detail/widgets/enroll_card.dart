import 'package:flutter/material.dart';

/// Enroll card — hiển thị số chương, số bài học, nút đăng ký / tiếp tục học.
class EnrollCard extends StatelessWidget {
  final VoidCallback? onEnroll;
  final VoidCallback? onStartLearning;
  final int moduleCount;
  final int lessonCount;
  final bool isEnrolled;
  final int progress;
  final String enrollmentStatus;
  final bool isLoading;
  final bool isArchived;
  final VoidCallback? onShare;
  final VoidCallback? onBookmark;

  const EnrollCard({
    super.key,
    this.onEnroll,
    this.onStartLearning,
    this.moduleCount = 0,
    this.lessonCount = 0,
    this.isEnrolled = false,
    this.progress = 0,
    this.enrollmentStatus = 'NOT_STARTED',
    this.isLoading = false,
    this.isArchived = false,
    this.onShare,
    this.onBookmark,
  });

  String get _buttonText {
    if (isArchived) return 'Khóa học đã bị ngưng';
    if (!isEnrolled) return 'Đăng ký ngay';
    final status = enrollmentStatus.toUpperCase();
    if (status == 'COMPLETED') return 'Học lại';
    if (progress > 0) return 'Tiếp tục học';
    return 'Bắt đầu học';
  }

  String get _subtitleText {
    if (isArchived) return 'Khóa học này đã bị ngưng, bạn không thể tham gia';
    if (!isEnrolled) return 'Tham gia miễn phí — Không phí ẩn';
    final status = enrollmentStatus.toUpperCase();
    if (status == 'COMPLETED') return 'Bạn đã hoàn thành khóa học này';
    if (progress > 0) return 'Tiếp tục học tập ngay';
    return 'Bắt đầu học ngay hôm nay';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ─── Primary Pill Button ───────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading || isArchived
                    ? null
                    : (isEnrolled ? onStartLearning : onEnroll),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isArchived
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF137FEC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _buttonText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle text
            Text(
              _subtitleText,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),

            const SizedBox(height: 16),

            // ─── Course stats inside card ───
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  _FeatureItem(
                    icon: Icons.library_books,
                    text: '$moduleCount chương',
                  ),
                  const SizedBox(height: 10),
                  _FeatureItem(
                    icon: Icons.play_lesson,
                    text: '$lessonCount bài học',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ─── Secondary actions ───────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onBookmark != null)
                  _SecondaryButton(
                    icon: Icons.bookmark_outline,
                    label: 'Lưu',
                    onTap: onBookmark!,
                  ),
                if (onShare != null) ...[
                  if (onBookmark != null)
                    const SizedBox(width: 16),
                  _SecondaryButton(
                    icon: Icons.share_outlined,
                    label: 'Chia sẻ',
                    onTap: onShare!,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<_SecondaryButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _isHovered
                ? const Color(0xFF137FEC).withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: _isHovered
                    ? const Color(0xFF137FEC)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  color: _isHovered
                      ? const Color(0xFF137FEC)
                      : const Color(0xFF64748B),
                  fontWeight:
                      _isHovered ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF137FEC)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }
}
