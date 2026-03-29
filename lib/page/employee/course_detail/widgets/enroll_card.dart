import 'package:flutter/material.dart';

/// Enroll card — modern Coursera-style:
/// - Light border instead of heavy shadow
/// - Gradient progress bar (primary → success green)
/// - Full-width pill button
/// - Clean "Course includes" list
class EnrollCard extends StatelessWidget {
  final VoidCallback onEnroll;
  final VoidCallback? onStartLearning;
  final int videoHours;
  final int resources;
  final bool hasCertificate;
  final int enrolledCount;
  final bool isEnrolled;
  final bool isLoading;
  final double? progressPercent;
  final String? imageUrl;
  final VoidCallback? onShare;
  final VoidCallback? onBookmark;

  const EnrollCard({
    super.key,
    required this.onEnroll,
    this.onStartLearning,
    this.videoHours = 0,
    this.resources = 0,
    this.hasCertificate = true,
    this.enrolledCount = 0,
    this.isEnrolled = false,
    this.isLoading = false,
    this.progressPercent,
    this.imageUrl,
    this.onShare,
    this.onBookmark,
  });

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
      child: Column(
        children: [
          // ─── Thumbnail ────────────────────────────────────────
          if (imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFE2E8F0),
                          child: const Icon(
                            Icons.image_outlined,
                            size: 40,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),
                    // Gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.2),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ─── Button Section ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Free badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'MIỄN PHÍ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ─── Gradient Progress bar (khi đã enroll) ─────────
                if (isEnrolled && progressPercent != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Stack(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 600),
                                      curve: Curves.easeOutCubic,
                                      width: constraints.maxWidth *
                                          (progressPercent! / 100).clamp(0.0, 1.0),
                                      decoration: BoxDecoration(
                                        gradient:
                                            const LinearGradient(
                                          colors: [
                                            Color(0xFF137FEC),
                                            Color(0xFF22C55E),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${progressPercent!.round()}%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF22C55E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // ─── Primary Pill Button ───────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : (isEnrolled ? onStartLearning : onEnroll),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF137FEC),
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
                            isEnrolled ? 'Bắt đầu học' : 'Đăng ký ngay',
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
                  isEnrolled
                      ? 'Tiếp tục học tập ngay'
                      : 'Tham gia miễn phí — Không phí ẩn',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
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

          // ─── Course includes ────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Khóa học bao gồm:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                _FeatureItem(
                  icon: Icons.videocam_outlined,
                  text: '$videoHours giờ video bài giảng',
                ),
                const SizedBox(height: 12),
                _FeatureItem(
                  icon: Icons.download_outlined,
                  text: '$resources tài liệu tải về',
                ),
                const SizedBox(height: 12),
                _FeatureItem(
                  icon: Icons.workspace_premium_outlined,
                  text: hasCertificate
                      ? 'Chứng chỉ hoàn thành'
                      : 'Không có chứng chỉ',
                ),
                const SizedBox(height: 12),
                const _FeatureItem(
                  icon: Icons.all_inclusive,
                  text: 'Truy cập trọn đời',
                ),
              ],
            ),
          ),

          // ─── Enrolled count ───────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: Text(
              'Đã có $enrolledCount học viên đăng ký',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
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
