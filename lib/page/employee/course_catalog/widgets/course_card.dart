import 'package:flutter/material.dart';

String _formatDate(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  try {
    final dt = DateTime.parse(raw);
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  } catch (_) {
    return raw;
  }
}

class CourseCard extends StatefulWidget {
  final String title;
  final String? description;
  final String? departmentName;
  final String status;
  final String? deadlineStatus;
  final String? fixedDeadline;
  final String? deadlineType;
  final int? defaultDeadlineDays;
  final bool? isEnrolled;
  final int moduleCount;
  final int lessonCount;
  final String? mentorName;
  final VoidCallback? onJoin;
  final VoidCallback? onTap;
  final String? level;

  const CourseCard({
    super.key,
    required this.title,
    this.description,
    this.departmentName,
    required this.status,
    this.deadlineStatus,
    this.fixedDeadline,
    this.deadlineType,
    this.defaultDeadlineDays,
    this.isEnrolled,
    required this.moduleCount,
    required this.lessonCount,
    this.mentorName,
    this.onJoin,
    this.onTap,
    this.level,
  });

  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard> {
  bool _isHovered = false;

  bool get _hasDeadline =>
      widget.deadlineType != null && widget.deadlineType!.isNotEmpty;

  Color get _levelColor {
    switch (widget.level?.toLowerCase()) {
      case 'beginner':
        return const Color(0xFF10B981);
      case 'intermediate':
        return const Color(0xFFF59E0B);
      case 'advanced':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color get _levelBgColor {
    switch (widget.level?.toLowerCase()) {
      case 'beginner':
        return const Color(0xFFD1FAE5);
      case 'intermediate':
        return const Color(0xFFFEF3C7);
      case 'advanced':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

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
              borderRadius: BorderRadius.circular(12), // Coursera-like professional radius
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
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                        child: // Placeholder Banner Design (Elegant Corporate Tech)
                            Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFEFF6FF), // soft blue
                                Color(0xFFDBEAFE),
                              ],
                            ),
                          ),
                          child: Stack(
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
                                child: Icon(
                                  Icons.menu_book_rounded,
                                  size: 40,
                                  color: Color(0xFF3B82F6), // Blue 500
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Department Tag over image (Subtle)
                      if (widget.departmentName != null &&
                          widget.departmentName!.isNotEmpty)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.departmentName!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      // Status Badge (outside ClipRRect so it's not clipped at rounded corners)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _StatusBadge(status: widget.status),
                      ),
                    ],
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
                          widget.title,
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
                        if (widget.description != null && widget.description!.isNotEmpty) ...[
                          Text(
                            widget.description!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                        ],

                        // Mentor/Provider
                        if (widget.mentorName != null && widget.mentorName!.isNotEmpty)
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 14,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.mentorName!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                        const Spacer(),

                        // Level & Modules (clean meta info row)
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (widget.level != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _levelBgColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  widget.level!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _levelColor,
                                  ),
                                ),
                              ),
                            _MetaText(
                              icon: Icons.view_module_outlined,
                              label: '${widget.moduleCount} mô-đun',
                            ),
                            _MetaText(
                              icon: Icons.play_lesson_outlined,
                              label: '${widget.lessonCount} bài',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Deadline if any
                        if (_hasDeadline) ...[
                          _DeadlineText(
                            deadlineType: widget.deadlineType,
                            deadlineStatus: widget.deadlineStatus,
                            fixedDeadline: widget.fixedDeadline,
                            defaultDeadlineDays: widget.defaultDeadlineDays,
                          ),
                          const SizedBox(height: 10),
                        ],

                        // Join Button 
                        SizedBox(
                          width: double.infinity,
                          child: _JoinButton(
                            status: widget.status,
                            isEnrolled: widget.isEnrolled,
                            onTap: (widget.isEnrolled != true &&
                                    widget.status == 'PUBLISHED')
                                ? widget.onJoin
                                : null,
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
}

class _MetaText extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaText({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bgColor;
    String label;

    switch (status.toUpperCase()) {
      case 'PUBLISHED':
        color = const Color(0xFF0F766E); // Teal 700
        bgColor = const Color(0xFFCCFBF1); // Teal 100
        label = 'Đã xuất bản';
        break;
      case 'PENDING':
        color = const Color(0xFFB45309); // Amber 700
        bgColor = const Color(0xFFFEF3C7); // Amber 100
        label = 'Chờ duyệt';
        break;
      case 'DRAFT':
        color = const Color(0xFFB45309); // Amber 700
        bgColor = const Color(0xFFFEF3C7); // Amber 100
        label = 'Bản nháp';
        break;
      case 'ARCHIVED':
        color = const Color(0xFF475569);
        bgColor = const Color(0xFFE2E8F0);
        label = 'Đã lưu trữ';
        break;
      default:
        color = const Color(0xFF475569);
        bgColor = const Color(0xFFE2E8F0);
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _DeadlineText extends StatelessWidget {
  final String? deadlineType;
  final String? deadlineStatus;
  final String? fixedDeadline;
  final int? defaultDeadlineDays;

  const _DeadlineText({
    this.deadlineType,
    this.deadlineStatus,
    this.fixedDeadline,
    this.defaultDeadlineDays,
  });

  @override
  Widget build(BuildContext context) {
    final type = deadlineType?.toUpperCase();
    final status = deadlineStatus?.toUpperCase();

    if (type == 'RELATIVE') {
      return _buildText(
        color: const Color(0xFF0F766E),
        icon: Icons.schedule,
        text: defaultDeadlineDays != null
            ? 'Hạn: $defaultDeadlineDays ngày'
            : 'Có hạn hoàn thành',
      );
    }

    Color color;
    IconData icon;

    switch (status) {
      case 'OVERDUE':
        color = const Color(0xFFDC2626);
        icon = Icons.error_outline;
        break;
      case 'DUE_SOON':
        color = const Color(0xFFD97706);
        icon = Icons.warning_amber_rounded;
        break;
      case 'ON_TIME':
        color = const Color(0xFF0F766E);
        icon = Icons.schedule;
        break;
      default:
        if (type == 'FIXED' &&
            fixedDeadline != null &&
            fixedDeadline!.isNotEmpty) {
          return _buildText(
            color: const Color(0xFF0F766E),
            icon: Icons.schedule,
            text: 'Hạn: ${_formatDate(fixedDeadline)}',
          );
        }
        return const SizedBox.shrink();
    }

    return _buildText(
      color: color,
      icon: icon,
      text: fixedDeadline != null && fixedDeadline!.isNotEmpty
          ? 'Hạn: ${_formatDate(fixedDeadline)}'
          : status == 'OVERDUE'
              ? 'Đã quá hạn'
              : status == 'DUE_SOON'
                  ? 'Sắp tới hạn'
                  : 'Còn hạn',
    );
  }

  Widget _buildText({required Color color, required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _JoinButton extends StatefulWidget {
  final String status;
  final bool? isEnrolled;
  final VoidCallback? onTap;

  const _JoinButton({required this.status, this.isEnrolled, this.onTap});

  @override
  State<_JoinButton> createState() => _JoinButtonState();
}

class _JoinButtonState extends State<_JoinButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isPublished = widget.status == 'PUBLISHED';
    final isEnrolled = widget.isEnrolled == true;

    final bool enabled =
        isEnrolled ? false : (isPublished && widget.onTap != null);

    final String label;
    final Color bgColor;
    final Color textColor;

    if (isEnrolled) {
      label = 'Đã tham gia';
      bgColor = const Color(0xFFF1F5F9);
      textColor = const Color(0xFF64748B);
    } else if (isPublished) {
      label = 'Tham gia';
      bgColor = const Color(0xFFEFF6FF); // Minimal brand blue background
      textColor = const Color(0xFF1D4ED8); // Deep brand blue text
    } else {
      label = 'Xem chi tiết';
      bgColor = const Color(0xFFF8FAFC);
      textColor = const Color(0xFF64748B);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered && enabled ? const Color(0xFFDBEAFE) : bgColor,
            borderRadius: BorderRadius.circular(6), // Sleek radius
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
