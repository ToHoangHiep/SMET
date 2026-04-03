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
        return const Color(0xFF22C55E);
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
        return const Color(0xFFDCFCE7);
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
        transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
        transformAlignment: Alignment.center,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    _isHovered
                        ? const Color(0xFF137FEC).withValues(alpha: 0.35)
                        : const Color(0xFFE2E8F0),
              ),
              boxShadow:
                  _isHovered
                      ? [
                        BoxShadow(
                          color: const Color(
                            0xFF137FEC,
                          ).withValues(alpha: 0.12),
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
                // ─── Partial Gradient Header (40%) ───────────────
                Stack(
                  children: [
                    // Gradient background — dark blue (matching enrolled_course_card)
                    Container(
                      height: 110,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1E3A5F),
                            const Color(0xFF0F172A),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Blue highlight overlay
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: const Alignment(0.3, -0.4),
                                  radius: 1.2,
                                  colors: [
                                    const Color(
                                      0xFF137FEC,
                                    ).withValues(alpha: 0.38),
                                    Colors.transparent,
                                  ],
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          Icon(
                            Icons.school_rounded,
                            size: 46,
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                        ],
                      ),
                    ),

                    // Gradient overlay at bottom
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.15),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Department badge (top-left) — pill style
                    if (widget.departmentName != null &&
                        widget.departmentName!.isNotEmpty)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.52),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            widget.departmentName!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                      ),

                    // Status badge (top-right)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _StatusBadge(status: widget.status),
                    ),

                    // Level chip (bottom-left) — pill with border & shadow
                    if (widget.level != null)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _levelBgColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _levelColor.withValues(alpha: 0.25),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _levelColor.withValues(alpha: 0.12),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            widget.level!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _levelColor,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // ─── Content ─────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title — stronger hierarchy
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: Color(0xFF0F172A),
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),

                        // Mentor row with avatar
                        if (widget.mentorName != null &&
                            widget.mentorName!.isNotEmpty) ...[
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(
                                        0xFF137FEC,
                                      ).withValues(alpha: 0.2),
                                      const Color(
                                        0xFF137FEC,
                                      ).withValues(alpha: 0.08),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 13,
                                  color: Color(0xFF137FEC),
                                ),
                              ),
                              const SizedBox(width: 8),
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
                          const SizedBox(height: 10),
                        ],

                        const Spacer(),

                        // Meta row: modules + lessons — improved
                        Row(
                          children: [
                            _MetaChip(
                              icon: Icons.view_module_outlined,
                              label: '${widget.moduleCount} mô-đun',
                            ),
                            const SizedBox(width: 12),
                            _MetaChip(
                              icon: Icons.play_lesson_outlined,
                              label: '${widget.lessonCount} bài',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Deadline chip — hiện khi khóa có cấu hình deadline (FIXED hoặc RELATIVE)
                        if (_hasDeadline) ...[
                          _DeadlineChip(
                            deadlineType: widget.deadlineType,
                            deadlineStatus: widget.deadlineStatus,
                            fixedDeadline: widget.fixedDeadline,
                            defaultDeadlineDays: widget.defaultDeadlineDays,
                          ),
                          const SizedBox(height: 10),
                        ],

                        // Action button — taller pill
                        SizedBox(
                          width: double.infinity,
                          height: 36,
                          child: _JoinButton(
                            status: widget.status,
                            isEnrolled: widget.isEnrolled,
                            onTap:
                                (widget.isEnrolled != true &&
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

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
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
    final Color hoverBgColor;

    if (isEnrolled) {
      label = 'Đã tham gia';
      bgColor = const Color(0xFFE2E8F0);
      hoverBgColor = const Color(0xFFCBD5E1);
    } else if (isPublished) {
      label = 'Tham gia';
      bgColor = const Color(0xFF137FEC);
      hoverBgColor = const Color(0xFF0B5FC5);
    } else {
      label = 'Xem chi tiết';
      bgColor = const Color(0xFF94A3B8);
      hoverBgColor = const Color(0xFF64748B);
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
            color: _isHovered ? hoverBgColor : bgColor,
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isEnrolled ? const Color(0xFF64748B) : Colors.white,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
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
        color = const Color(0xFF22C55E);
        bgColor = const Color(0xFFDCFCE7);
        label = 'Đã xuất bản';
        break;
      case 'DRAFT':
        color = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
        label = 'Bản nháp';
        break;
      case 'ARCHIVED':
        color = const Color(0xFF64748B);
        bgColor = const Color(0xFFF1F5F9);
        label = 'Đã lưu trữ';
        break;
      default:
        color = const Color(0xFF64748B);
        bgColor = const Color(0xFFF1F5F9);
        label = status;
    }

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
  final String? deadlineType;
  final String? deadlineStatus;
  final String? fixedDeadline;
  final int? defaultDeadlineDays;

  const _DeadlineChip({
    this.deadlineType,
    this.deadlineStatus,
    this.fixedDeadline,
    this.defaultDeadlineDays,
  });

  @override
  Widget build(BuildContext context) {
    final type = deadlineType?.toUpperCase();
    final status = deadlineStatus?.toUpperCase();

    // RELATIVE deadline → hiện "Có hạn" (không tính được ngày cụ thể ở mức catalog)
    if (type == 'RELATIVE') {
      return _buildChip(
        color: const Color(0xFF15803D),
        bgColor: const Color(0xFFDCFCE7),
        icon: Icons.schedule,
        text:
            defaultDeadlineDays != null
                ? 'Hạn: $defaultDeadlineDays ngày sau khi đăng ký'
                : 'Có hạn hoàn thành',
      );
    }

    // FIXED deadline — dùng deadlineStatus đã được backend tính
    Color color;
    Color bgColor;
    IconData icon;

    switch (status) {
      case 'OVERDUE':
        color = const Color(0xFFDC2626);
        bgColor = const Color(0xFFFEE2E2);
        icon = Icons.error_outline;
        break;
      case 'DUE_SOON':
        color = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
        icon = Icons.warning_amber_rounded;
        break;
      case 'ON_TIME':
        color = const Color(0xFF15803D);
        bgColor = const Color(0xFFDCFCE7);
        icon = Icons.schedule;
        break;
      default:
        // FIXED nhưng backend chưa compute status → vẫn hiện với fixedDeadline
        if (type == 'FIXED' &&
            fixedDeadline != null &&
            fixedDeadline!.isNotEmpty) {
          return _buildChip(
            color: const Color(0xFF15803D),
            bgColor: const Color(0xFFDCFCE7),
            icon: Icons.schedule,
            text: 'Hạn: ${_formatDate(fixedDeadline)}',
          );
        }
        return const SizedBox.shrink();
    }

    return _buildChip(
      color: color,
      bgColor: bgColor,
      icon: icon,
      text:
          fixedDeadline != null && fixedDeadline!.isNotEmpty
              ? 'Hạn: ${_formatDate(fixedDeadline)}'
              : status == 'OVERDUE'
              ? 'Đã quá hạn'
              : status == 'DUE_SOON'
              ? 'Sắp hết hạn'
              : 'Còn thời gian',
    );
  }

  Widget _buildChip({
    required Color color,
    required Color bgColor,
    required IconData icon,
    required String text,
  }) {
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
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
