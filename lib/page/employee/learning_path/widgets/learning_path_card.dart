import 'package:flutter/material.dart';
import 'package:smet/core/theme/app_colors.dart';
import 'package:smet/core/utils/animations.dart';
import 'package:smet/model/learning_path_model.dart' hide Long;
import 'package:smet/service/employee/lms_service.dart';

/// ─── Learning Path Card ───────────────────────────────────────────────────
///
/// Inset card that shows a learning path with its course steps,
/// animated progress, and hover-lift effect.
class LearningPathCard extends StatefulWidget {
  final LearningPathInfo path;
  final int index;
  final VoidCallback onTap;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;

  const LearningPathCard({
    super.key,
    required this.path,
    required this.index,
    required this.onTap,
    this.isExpanded = false,
    this.onToggleExpand,
  });

  @override
  State<LearningPathCard> createState() => _LearningPathCardState();
}

class _LearningPathCardState extends State<LearningPathCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: (widget.path.progressPercent / 100).clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));

    Future.delayed(Duration(milliseconds: 100 + widget.index * 80), () {
      if (mounted) _progressController.forward();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LearningPathCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path.progressPercent != widget.path.progressPercent) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: (widget.path.progressPercent / 100).clamp(0.0, 1.0),
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeOutCubic,
      ));
      _progressController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.path;
    final progress = path.progressPercent;
    final isCompleted = progress >= 100;
    final isStarted = progress > 0;

    final statusColor = isCompleted
        ? AppColors.success
        : isStarted
            ? AppColors.primary
            : AppColors.textMuted;

    final statusLabel = isCompleted
        ? 'Hoàn thành'
        : isStarted
            ? 'Đang học'
            : 'Chưa bắt đầu';

    final statusBg = isCompleted
        ? AppColors.badgeGreenBg
        : isStarted
            ? AppColors.badgeBlueBg
            : AppColors.badgeGrayBg;

    return AnimatedFadeSlide(
      index: widget.index,
      duration: AppAnimations.standard,
      slideOffset: const Offset(0, 16),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: AppAnimations.standard,
            curve: AppAnimations.standardCurve,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isHovered
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : AppColors.border,
                width: _isHovered ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  blurRadius: _isHovered ? 24 : 12,
                  offset: Offset(0, _isHovered ? 8 : 4),
                ),
              ],
            ),
            transform: Matrix4.identity()
              ..translate(0.0, _isHovered ? -2.0 : 0.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Icon badge
                          AnimatedContainer(
                            duration: AppAnimations.standard,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: isCompleted
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF22C55E),
                                        Color(0xFF16A34A),
                                      ],
                                    )
                                  : AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: (isCompleted
                                          ? AppColors.success
                                          : AppColors.primary)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              isCompleted
                                  ? Icons.check_circle_rounded
                                  : Icons.route_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Title + meta
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  path.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _MetaChip(
                                      icon: Icons.library_books_outlined,
                                      label: '${path.courseCount} khóa học',
                                    ),
                                    const SizedBox(width: 12),
                                    _MetaChip(
                                      icon: Icons.layers_outlined,
                                      label: '${path.totalModules} module',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Status badge
                          AnimatedContainer(
                            duration: AppAnimations.fast,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Description
                      if (path.description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          path.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                          maxLines: widget.isExpanded ? 10 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      // Expand/collapse
                      if (path.courses.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: widget.onToggleExpand,
                          child: Row(
                            children: [
                              AnimatedRotation(
                                turns: widget.isExpanded ? 0.5 : 0,
                                duration: AppAnimations.standard,
                                child: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.isExpanded
                                    ? 'Thu gọn'
                                    : 'Xem ${path.courseCount} khóa học',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Course Timeline (expanded) ─────────────────────
                if (widget.isExpanded && path.courses.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                    child: _CourseTimeline(courses: path.courses),
                  ),
                ],

                // ── Progress Section ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 22),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, _) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'Tiến độ',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${path.progressPercent.round()}%',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: statusColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: AppColors.border,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          return Stack(
                                            children: [
                                              AnimatedContainer(
                                                duration: AppAnimations.slow,
                                                curve: AppAnimations.standardCurve,
                                                width: constraints.maxWidth *
                                                    _progressAnimation.value,
                                                decoration: BoxDecoration(
                                                  gradient: isCompleted
                                                      ? const LinearGradient(
                                                          colors: [
                                                            Color(0xFF22C55E),
                                                            Color(0xFF16A34A),
                                                          ],
                                                        )
                                                      : AppColors.primaryGradient,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Continue button
                          _ContinueButton(
                            onTap: widget.onTap,
                            state: isCompleted
                                ? LearningPathButtonState.completed
                                : isStarted
                                    ? LearningPathButtonState.inProgress
                                    : LearningPathButtonState.notStarted,
                          ),
                        ],
                      ),
                    ],
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

// ─── Sub-widgets ────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class LearningPathButtonState {
  final String label;
  final String iconType; // 'start' | 'continue' | 'review'
  final LinearGradient gradient;

  LearningPathButtonState._({
    required this.label,
    required this.iconType,
    required this.gradient,
  });

  static final completed = LearningPathButtonState._(
    label: 'Xem lại',
    iconType: 'review',
    gradient: LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF16A34A)]),
  );

  static final inProgress = LearningPathButtonState._(
    label: 'Tiếp tục',
    iconType: 'continue',
    gradient: LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
  );

  static final notStarted = LearningPathButtonState._(
    label: 'Bắt đầu',
    iconType: 'start',
    gradient: LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
  );
}

class _ContinueButton extends StatefulWidget {
  final VoidCallback onTap;
  final LearningPathButtonState state;

  const _ContinueButton({required this.onTap, required this.state});

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final Color baseColor = state == LearningPathButtonState.completed
        ? AppColors.success
        : state == LearningPathButtonState.notStarted
            ? const Color(0xFF8B5CF6)
            : AppColors.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            gradient: state.gradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: baseColor.withValues(alpha: _isHovered ? 0.4 : 0.25),
                blurRadius: _isHovered ? 12 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          transform: Matrix4.identity()
            ..scale(_isHovered ? 1.04 : 1.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                state == LearningPathButtonState.completed
                    ? Icons.replay_rounded
                    : state == LearningPathButtonState.notStarted
                        ? Icons.play_arrow_rounded
                        : Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseTimeline extends StatelessWidget {
  final List<CourseItemResponse> courses;

  const _CourseTimeline({required this.courses});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSlateLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.playlist_play_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                'Danh sách khóa học (${courses.length})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(courses.length, (i) {
            final course = courses[i];
            final isLast = i == courses.length - 1;
            return _TimelineItem(
              course: course,
              index: i,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatefulWidget {
  final CourseItemResponse course;
  final int index;
  final bool isLast;

  const _TimelineItem({
    required this.course,
    required this.index,
    required this.isLast,
  });

  @override
  State<_TimelineItem> createState() => _TimelineItemState();
}

class _TimelineItemState extends State<_TimelineItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line + dot
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${widget.index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (!widget.isLast)
              Container(
                width: 2,
                height: 36,
                color: AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 12),
        // Course info
        Expanded(
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: AppAnimations.fast,
              margin: EdgeInsets.only(bottom: widget.isLast ? 0 : 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _isHovered
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isHovered
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.play_circle_outline_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.course.courseTitle,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.course.mentorName != null ||
                            widget.course.moduleCount != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (widget.course.mentorName != null)
                                widget.course.mentorName,
                              if (widget.course.moduleCount != null)
                                '${widget.course.moduleCount} module',
                            ].join(' · '),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: _isHovered ? AppColors.primary : AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
