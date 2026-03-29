import 'package:flutter/material.dart';
import 'package:smet/service/employee/lms_service.dart';

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year;
  return '$day/$month/$year';
}

/// Enrolled Course Card — modern Coursera-style:
/// - 16:9 banner with gradient overlay
/// - Linear progress (single % label, no duplicate ring)
/// - Rounded pill action button
/// - Hover scale animation
class EnrolledCourseCard extends StatefulWidget {
  final EnrolledCourse course;
  final VoidCallback? onTap;

  const EnrolledCourseCard({
    super.key,
    required this.course,
    this.onTap,
  });

  @override
  State<EnrolledCourseCard> createState() => _EnrolledCourseCardState();
}

class _EnrolledCourseCardState extends State<EnrolledCourseCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..scale(_isHovered ? 1.02 : 1.0),
        transformAlignment: Alignment.center,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isHovered
                    ? const Color(0xFF137FEC).withValues(alpha: 0.35)
                    : const Color(0xFFE2E8F0),
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: const Color(0xFF137FEC).withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Banner (16:9 aspect) ──────────────────────
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Container(
                          color: const Color(0xFFF1F5F9),
                          child: widget.course.imageUrl != null
                              ? Image.network(
                                  widget.course.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildBannerPlaceholder(),
                                )
                              : _buildBannerPlaceholder(),
                        ),
                      ),
                    ),

                    // Gradient overlay
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.25),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Certificate icon
                    if (widget.course.certificateAvailable)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF9C3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFCA8A04),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.workspace_premium,
                            color: Color(0xFFCA8A04),
                            size: 18,
                          ),
                        ),
                      ),

                    // Status badge
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _StatusBadge(status: widget.course.status),
                    ),
                  ],
                ),

                // ─── Body ─────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title — stronger hierarchy (single % source of truth below)
                        Expanded(
                          child: Text(
                            widget.course.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: Color(0xFF0F172A),
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Deadline chip
                        if (widget.course.deadline != null) ...[
                          _DeadlineChip(
                            deadline: widget.course.deadline!,
                            status: widget.course.deadlineStatus,
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Progress: one row + bar only (no duplicate ring %)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.pie_chart_outline_rounded,
                                  size: 16,
                                  color: widget.course.progressPercent >= 100
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Tiến độ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${widget.course.progressPercent.toInt()}%',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                    color: widget.course.progressPercent >= 100
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFF137FEC),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return Stack(
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(
                                            milliseconds: 600),
                                        curve: Curves.easeOutCubic,
                                        width: constraints.maxWidth *
                                            (widget.course.progressPercent / 100)
                                                .clamp(0.0, 1.0),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF137FEC),
                                              Color(0xFF22C55E),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          boxShadow: widget.course
                                                      .progressPercent >
                                                  0
                                              ? [
                                                  BoxShadow(
                                                    color: const Color(
                                                            0xFF137FEC)
                                                        .withValues(
                                                            alpha: 0.35),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Action button — pill style
                        SizedBox(
                          width: double.infinity,
                          child: _ActionButton(
                            progress: widget.course.progressPercent,
                            onTap: widget.onTap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A5F),
            Color(0xFF0F172A),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.3, -0.4),
                  radius: 1.2,
                  colors: [
                    const Color(0xFF137FEC).withValues(alpha: 0.38),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Icon(
            Icons.school_rounded,
            size: 44,
            color: Colors.white.withValues(alpha: 0.88),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final double progress;
  final VoidCallback? onTap;

  const _ActionButton({required this.progress, this.onTap});

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final label = widget.progress >= 100
        ? 'Hoàn thành'
        : widget.progress > 0
            ? 'Tiếp tục học'
            : 'Bắt đầu học';

    final color = widget.progress >= 100
        ? const Color(0xFF22C55E)
        : const Color(0xFF137FEC);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: _isHovered ? color.withValues(alpha: 0.9) : color,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final EnrollmentStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bgColor;
    String label;

    switch (status) {
      case EnrollmentStatus.notStarted:
        color = const Color(0xFF64748B);
        bgColor = const Color(0xFFF1F5F9);
        label = 'Chưa bắt đầu';
        break;
      case EnrollmentStatus.inProgress:
        color = const Color(0xFF137FEC);
        bgColor = const Color(0xFFDBEAFE);
        label = 'Đang học';
        break;
      case EnrollmentStatus.completed:
        color = const Color(0xFF22C55E);
        bgColor = const Color(0xFFDCFCE7);
        label = 'Hoàn thành';
        break;
      case EnrollmentStatus.unknown:
        color = const Color(0xFF64748B);
        bgColor = const Color(0xFFF1F5F9);
        label = '';
        break;
    }

    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}

class _DeadlineChip extends StatelessWidget {
  final DateTime deadline;
  final DeadlineStatus status;

  const _DeadlineChip({required this.deadline, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bgColor;
    IconData icon;

    switch (status) {
      case DeadlineStatus.onTime:
        color = const Color(0xFF15803D);
        bgColor = const Color(0xFFDCFCE7);
        icon = Icons.schedule;
        break;
      case DeadlineStatus.dueSoon:
        color = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
        icon = Icons.warning_amber_rounded;
        break;
      case DeadlineStatus.overdue:
        color = const Color(0xFFEF4444);
        bgColor = const Color(0xFFFEE2E2);
        icon = Icons.error_outline;
        break;
      case DeadlineStatus.none:
        color = const Color(0xFF64748B);
        bgColor = const Color(0xFFF1F5F9);
        icon = Icons.schedule;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Hạn: ${_formatDate(deadline)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: -0.1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
