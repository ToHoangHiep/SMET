import 'package:flutter/material.dart';
import 'package:smet/service/employee/lms_service.dart';

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year;
  return '$day/$month/$year';
}

class EnrolledCourseCard extends StatefulWidget {
  final EnrolledCourse course;
  final VoidCallback? onTap;
  final VoidCallback? onViewCertificate;

  const EnrolledCourseCard({
    super.key,
    required this.course,
    this.onTap,
    this.onViewCertificate,
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
        transform: Matrix4.identity()..scale(_isHovered ? 1.015 : 1.0),
        transformAlignment: Alignment.center,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHovered
                    ? const Color(0xFF2563EB).withValues(alpha: 0.3)
                    : const Color(0xFFE2E8F0),
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- TOP 16:9 BANNER ---
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                    child: Stack(
                      children: [
                        // Image or Placeholder
                        Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                            ),
                          ),
                          child: widget.course.imageUrl != null
                              ? Image.network(
                                  widget.course.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const _PlaceholderBanner(),
                                )
                              : const _PlaceholderBanner(),
                        ),
                        // Top Badges
                        if (widget.course.certificateAvailable)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.workspace_premium, size: 12, color: Color(0xFFFDE047)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Chứng chỉ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: _StatusBadge(status: widget.course.status),
                        ),
                      ],
                    ),
                  ),
                ),

                // --- PROGRESS BAR (Coursera Style, thin line below image) ---
                Container(
                  height: 3,
                  width: double.infinity,
                  color: const Color(0xFFE2E8F0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          width: constraints.maxWidth *
                              (widget.course.progressPercent / 100).clamp(0.0, 1.0),
                          color: widget.course.progressPercent >= 100
                              ? const Color(0xFF10B981) // Emerald
                              : const Color(0xFF2563EB), // Brand blue
                        ),
                      );
                    },
                  ),
                ),

                // --- CONTENT ---
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          widget.course.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: Color(0xFF0F172A),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Description
                        if (widget.course.description != null &&
                            widget.course.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              widget.course.description!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(height: 6),

                        // Deadline
                        if (widget.course.deadline != null)
                          _DeadlineText(
                            deadline: widget.course.deadline!,
                            status: widget.course.deadlineStatus,
                          ),

                        const Spacer(),

                        // Tiny progress text
                        Text(
                          '${widget.course.progressPercent.toInt()}% hoàn thành',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: widget.course.progressPercent >= 100
                                ? const Color(0xFF10B981)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Action Row
                        _ActionButtonRow(
                          progress: widget.course.progressPercent,
                          status: widget.course.status,
                          certificateAvailable: widget.course.certificateAvailable,
                          onTap: widget.onTap,
                          onViewCertificate: widget.onViewCertificate,
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
}

class _PlaceholderBanner extends StatelessWidget {
  const _PlaceholderBanner();
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -20,
          right: -20,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF60A5FA).withValues(alpha: 0.15),
            ),
          ),
        ),
        Positioned(
          bottom: -30,
          left: -10,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
            ),
          ),
        ),
        const Center(
          child: Icon(Icons.school_rounded, size: 40, color: Color(0xFF3B82F6)),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final EnrollmentStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case EnrollmentStatus.notStarted:
        bgColor = Colors.black.withValues(alpha: 0.4);
        textColor = Colors.white;
        label = 'Chưa bắt đầu';
        break;
      case EnrollmentStatus.inProgress:
        bgColor = const Color(0xFFEFF6FF).withValues(alpha: 0.9);
        textColor = const Color(0xFF1D4ED8);
        label = 'Đang học';
        break;
      case EnrollmentStatus.completed:
        bgColor = const Color(0xFFD1FAE5).withValues(alpha: 0.95);
        textColor = const Color(0xFF047857);
        label = 'Hoàn thành';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _DeadlineText extends StatelessWidget {
  final DateTime deadline;
  final DeadlineStatus status;

  const _DeadlineText({required this.deadline, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (status) {
      case DeadlineStatus.onTime:
        color = const Color(0xFF0F766E);
        icon = Icons.schedule;
        break;
      case DeadlineStatus.dueSoon:
        color = const Color(0xFFD97706);
        icon = Icons.warning_amber_rounded;
        break;
      case DeadlineStatus.overdue:
        color = const Color(0xFFDC2626);
        icon = Icons.error_outline;
        break;
      case DeadlineStatus.none:
        color = const Color(0xFF64748B);
        icon = Icons.schedule;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            'Hạn: ${_formatDate(deadline)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ActionButtonRow extends StatefulWidget {
  final double progress;
  final EnrollmentStatus status;
  final bool certificateAvailable;
  final VoidCallback? onTap;
  final VoidCallback? onViewCertificate;

  const _ActionButtonRow({
    required this.progress,
    required this.status,
    required this.certificateAvailable,
    this.onTap,
    this.onViewCertificate,
  });

  @override
  State<_ActionButtonRow> createState() => _ActionButtonRowState();
}

class _ActionButtonRowState extends State<_ActionButtonRow> {
  bool _isHoveredMain = false;
  bool _isHoveredCert = false;

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.status == EnrollmentStatus.completed;
    final showCertButton = isCompleted && widget.certificateAvailable;

    final String label = isCompleted
        ? 'Ôn tập lại'
        : widget.progress > 0
            ? 'Tiếp tục học'
            : 'Bắt đầu học';

    final Color bgColor = isCompleted
        ? const Color(0xFFF8FAFC)
        : const Color(0xFFEFF6FF); // Brand blue extremely pale
    final Color textColor = isCompleted
        ? const Color(0xFF64748B)
        : const Color(0xFF1D4ED8);

    return Row(
      children: [
        if (showCertButton) ...[
          Expanded(
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHoveredCert = true),
              onExit: (_) => setState(() => _isHoveredCert = false),
              child: GestureDetector(
                onTap: widget.onViewCertificate,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _isHoveredCert
                        ? const Color(0xFFFEF3C7) // Very pale subtle yellow
                        : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFDE047).withValues(alpha: 0.5)),
                  ),
                  child: const Center(
                    child: Text(
                      'Chứng chỉ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD97706), // Amber 600
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],

        // Main Action
        Expanded(
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHoveredMain = true),
            onExit: (_) => setState(() => _isHoveredMain = false),
            child: GestureDetector(
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _isHoveredMain
                      ? (isCompleted ? const Color(0xFFF1F5F9) : const Color(0xFFDBEAFE))
                      : bgColor,
                  borderRadius: BorderRadius.circular(6),
                  border: isCompleted ? Border.all(color: const Color(0xFFE2E8F0)) : null,
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
