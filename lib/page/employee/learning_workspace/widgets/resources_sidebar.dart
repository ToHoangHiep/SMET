import 'package:flutter/material.dart';
import 'package:smet/model/Employee_learning_model.dart';
import 'package:smet/service/employee/lms_service.dart';

/// Resources Sidebar — elevated modern design:
/// - Animated circular progress ring
/// - Up Next card with gradient background
/// - Learning path card with visual hierarchy
class ResourcesSidebar extends StatelessWidget {
  final Lesson? nextLesson;
  final Function(Lesson)? onJumpToLesson;
  final LearningPathDetail? learningPath;
  final String? currentCourseId;
  final Function(String courseId)? onCourseTap;
  final double? courseProgress;
  final bool courseCompleted;

  const ResourcesSidebar({
    super.key,
    this.nextLesson,
    this.onJumpToLesson,
    this.learningPath,
    this.currentCourseId,
    this.onCourseTap,
    this.courseProgress,
    this.courseCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (courseProgress != null) ...[
          _ContinueLearningCard(
            courseProgress: courseProgress!,
            courseCompleted: courseCompleted,
          ),
          const SizedBox(height: 20),
        ],
        if (nextLesson != null) ...[
          _UpNextCard(
            lesson: nextLesson!,
            onTap: () => onJumpToLesson?.call(nextLesson!),
          ),
          const SizedBox(height: 20),
        ],
        if (learningPath != null) ...[
          _LearningPathCard(
            learningPath: learningPath!,
            currentCourseId: currentCourseId,
            onCourseTap: onCourseTap,
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  final double courseProgress;
  final bool courseCompleted;

  const _ContinueLearningCard({
    required this.courseProgress,
    required this.courseCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final progress = courseProgress.clamp(0.0, 1.0);
    final percent = (progress * 100).round();
    final color = courseCompleted ? const Color(0xFF22C55E) : const Color(0xFF137FEC);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      courseCompleted ? Icons.check_circle : Icons.school,
                      size: 14,
                      color: color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      courseCompleted ? 'Hoàn thành' : 'Đang học',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Tiến độ khóa học',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            courseCompleted
                ? 'Chúc mừng bạn đã hoàn thành khóa học!'
                : '$percent% đã hoàn thành · Tiếp tục học nhé!',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          // Animated progress bar
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(999),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: constraints.maxWidth * value,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: courseCompleted
                                  ? [const Color(0xFF22C55E), const Color(0xFF16A34A)]
                                  : [const Color(0xFF137FEC), const Color(0xFF22C55E)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: (courseCompleted
                                        ? const Color(0xFF22C55E)
                                        : const Color(0xFF137FEC))
                                    .withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Circular progress
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(80, 80),
                          painter: _RingPainter(
                            progress: value,
                            backgroundColor: const Color(0xFFE2E8F0),
                            progressColor: color,
                            strokeWidth: 7,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$percent',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: color,
                              ),
                            ),
                            Text(
                              '%',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: color.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpNextCard extends StatefulWidget {
  final Lesson lesson;
  final VoidCallback onTap;

  const _UpNextCard({
    required this.lesson,
    required this.onTap,
  });

  @override
  State<_UpNextCard> createState() => _UpNextCardState();
}

class _UpNextCardState extends State<_UpNextCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF137FEC), Color(0xFF0B5FC5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF137FEC).withValues(alpha: _isHovered ? 0.5 : 0.35),
                blurRadius: _isHovered ? 24 : 20,
                offset: Offset(0, _isHovered ? 10 : 6),
              ),
            ],
          ),
          transform: _isHovered
              ? (Matrix4.identity()..translate(0.0, -3.0))
              : Matrix4.identity(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white),
                        SizedBox(width: 5),
                        Text(
                          'TIẾP THEO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _isHovered ? 0.08 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                widget.lesson.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_circle_fill,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Chuyển đến bài học',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LearningPathCard extends StatelessWidget {
  final LearningPathDetail learningPath;
  final String? currentCourseId;
  final Function(String)? onCourseTap;

  const _LearningPathCard({
    required this.learningPath,
    this.currentCourseId,
    this.onCourseTap,
  });

  @override
  Widget build(BuildContext context) {
    final courses = learningPath.courses;
    final completedCount = courses.where((c) => c.isCompleted).length;
    final totalCount = courses.length;
    final percent = totalCount > 0 ? (completedCount / totalCount) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF137FEC).withValues(alpha: 0.12),
                      const Color(0xFF137FEC).withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  size: 22,
                  color: Color(0xFF137FEC),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      learningPath.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          completedCount == totalCount
                              ? Icons.check_circle
                              : Icons.school,
                          size: 13,
                          color: completedCount == totalCount
                              ? const Color(0xFF22C55E)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$completedCount / $totalCount khóa học hoàn thành',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(999),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: percent),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return Stack(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: constraints.maxWidth * value,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: completedCount == totalCount
                                  ? [const Color(0xFF22C55E), const Color(0xFF16A34A)]
                                  : [const Color(0xFF137FEC), const Color(0xFF22C55E)],
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: const Color(0xFFF1F5F9),
          ),
          const SizedBox(height: 12),
          ...courses.map(
            (course) => _LearningPathCourseItem(
              course: course,
              isCurrent: course.id == currentCourseId,
              onTap: () => onCourseTap?.call(course.id),
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningPathCourseItem extends StatefulWidget {
  final LearningPathCourseItem course;
  final bool isCurrent;
  final VoidCallback onTap;

  const _LearningPathCourseItem({
    required this.course,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  State<_LearningPathCourseItem> createState() => _LearningPathCourseItemState();
}

class _LearningPathCourseItemState extends State<_LearningPathCourseItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.course.isCompleted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: widget.isCurrent
                  ? const Color(0xFF137FEC).withValues(alpha: 0.08)
                  : (_isHovered
                      ? const Color(0xFFF8FAFC)
                      : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isCurrent
                    ? const Color(0xFF137FEC).withValues(alpha: 0.3)
                    : (_isHovered
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFFF1F5F9)),
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xFF22C55E).withValues(alpha: 0.12)
                        : (widget.isCurrent
                            ? const Color(0xFF137FEC).withValues(alpha: 0.12)
                            : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isCompleted
                        ? Icons.check_circle
                        : widget.isCurrent
                            ? Icons.play_circle_filled
                            : Icons.radio_button_unchecked,
                    size: 18,
                    color: isCompleted
                        ? const Color(0xFF22C55E)
                        : (widget.isCurrent
                            ? const Color(0xFF137FEC)
                            : const Color(0xFFCBD5E1)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.course.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              widget.isCurrent ? FontWeight.w700 : FontWeight.w500,
                          color: isCompleted
                              ? const Color(0xFF64748B)
                              : const Color(0xFF0F172A),
                          decoration:
                              isCompleted ? TextDecoration.lineThrough : null,
                          decorationColor: const Color(0xFF94A3B8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isCompleted) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.check,
                              size: 11,
                              color: Color(0xFF22C55E),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Đã hoàn thành',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF22C55E).withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.isCurrent || _isHovered)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: widget.isCurrent
                        ? const Color(0xFF137FEC)
                        : const Color(0xFF94A3B8),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular ring painter for continue learning progress.
class _RingPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -3.14159 / 2;
    final sweepAngle = 2 * 3.14159 * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress;
}
