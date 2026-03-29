import 'package:flutter/material.dart';

/// Refactor từ course_syllabus.dart
/// - Card có shadow nhẹ, hover state
/// - Progress bar trên mỗi module card
/// - Active module border-left primary 4px
/// - Animation expand/collapse mượt
class SyllabusSection extends StatelessWidget {
  final List<SyllabusModule> modules;
  final void Function(int moduleIndex, int lessonIndex)? onLessonTap;

  const SyllabusSection({
    super.key,
    required this.modules,
    this.onLessonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Title + count ───
        Row(
          children: [
            const Text(
              'Nội dung khóa học',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF137FEC).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${modules.length} modules',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF137FEC),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ─── Modules list ───
        ...modules.asMap().entries.map((entry) {
          final index = entry.key;
          final module = entry.value;
          return _ModuleItem(
            index: index + 1,
            title: module.title,
            lessonCount: module.lessonCount,
            lessons: module.lessons,
            isExpanded: module.isExpanded,
            isActive: module.isActive,
            onToggle: module.onToggle,
            onLessonTap: (lessonIdx) => onLessonTap?.call(index, lessonIdx),
          );
        }),
      ],
    );
  }
}

class SyllabusModule {
  final String title;
  final int lessonCount;
  final List<SyllabusLesson> lessons;
  final bool isExpanded;
  final bool isActive;
  final VoidCallback onToggle;

  const SyllabusModule({
    required this.title,
    required this.lessonCount,
    required this.lessons,
    required this.isExpanded,
    this.isActive = false,
    required this.onToggle,
  });
}

class SyllabusLesson {
  final String title;
  final SyllabusLessonType type;
  final bool isCompleted;

  const SyllabusLesson({
    required this.title,
    this.type = SyllabusLessonType.video,
    this.isCompleted = false,
  });
}

enum SyllabusLessonType { video, document, quiz, article }

class _ModuleItem extends StatefulWidget {
  final int index;
  final String title;
  final int lessonCount;
  final List<SyllabusLesson> lessons;
  final bool isExpanded;
  final bool isActive;
  final VoidCallback onToggle;
  final void Function(int lessonIndex)? onLessonTap;

  const _ModuleItem({
    required this.index,
    required this.title,
    required this.lessonCount,
    required this.lessons,
    required this.isExpanded,
    this.isActive = false,
    required this.onToggle,
    this.onLessonTap,
  });

  @override
  State<_ModuleItem> createState() => _ModuleItemState();
}

class _ModuleItemState extends State<_ModuleItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _iconRotation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _iconRotation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isExpanded) _controller.value = 1;
  }

  @override
  void didUpdateWidget(_ModuleItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate module completion progress
    final completedLessons = widget.lessons.where((l) => l.isCompleted).length;
    final progress =
        widget.lessons.isEmpty ? 0.0 : completedLessons / widget.lessons.length;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isActive
                ? const Color(0xFF137FEC)
                : const Color(0xFFE5E7EB),
            width: widget.isActive ? 1.5 : 1,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          children: [
            // ─── Progress bar (top) ─────────────────────────────
            if (widget.lessons.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress >= 1.0
                            ? const Color(0xFF22C55E)
                            : const Color(0xFF137FEC),
                      ),
                      minHeight: 3,
                    );
                  },
                ),
              ),

            // ─── Header ──────────────────────────────────────────
            InkWell(
              onTap: widget.onToggle,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Module number badge
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: widget.isActive
                            ? const Color(0xFF137FEC)
                            : const Color(0xFF137FEC).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: progress >= 1.0
                            ? const Icon(
                                Icons.check,
                                size: 20,
                                color: Color(0xFF22C55E),
                              )
                            : Text(
                                widget.index.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: widget.isActive
                                      ? Colors.white
                                      : const Color(0xFF137FEC),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Title + meta
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: widget.isActive
                                  ? const Color(0xFF137FEC)
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                '${widget.lessonCount} bài học',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              if (widget.lessons.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFCBD5E1),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${completedLessons}/${widget.lessonCount} hoàn thành',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: progress >= 1.0
                                        ? const Color(0xFF22C55E)
                                        : const Color(0xFF64748B),
                                    fontWeight: progress >= 1.0
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Chevron
                    RotationTransition(
                      turns: _iconRotation,
                      child: const Icon(
                        Icons.expand_more,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Lessons ───────────────────────────────────────
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: widget.isExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border(
                    top: BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
                child: Column(
                  children: widget.lessons.asMap().entries.map((entry) {
                    final lessonIdx = entry.key;
                    final lesson = entry.value;
                    return _LessonItem(
                      lesson: lesson,
                      onTap: () => widget.onLessonTap?.call(lessonIdx),
                    );
                  }).toList(),
                ),
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonItem extends StatefulWidget {
  final SyllabusLesson lesson;
  final VoidCallback? onTap;

  const _LessonItem({required this.lesson, this.onTap});

  @override
  State<_LessonItem> createState() => _LessonItemState();
}

class _LessonItemState extends State<_LessonItem> {
  bool _isHovered = false;

  IconData get _icon {
    switch (widget.lesson.type) {
      case SyllabusLessonType.video:
        return Icons.play_circle_outline;
      case SyllabusLessonType.document:
        return Icons.article_outlined;
      case SyllabusLessonType.quiz:
        return Icons.quiz_outlined;
      case SyllabusLessonType.article:
        return Icons.library_books_outlined;
    }
  }

  Color get _iconColor {
    if (widget.lesson.isCompleted) return const Color(0xFF22C55E);
    switch (widget.lesson.type) {
      case SyllabusLessonType.video:
        return const Color(0xFF137FEC);
      case SyllabusLessonType.document:
        return const Color(0xFFF59E0B);
      case SyllabusLessonType.quiz:
        return const Color(0xFF22C55E);
      case SyllabusLessonType.article:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: _isHovered
              ? const Color(0xFF137FEC).withValues(alpha: 0.04)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              // Status icon
              Icon(
                widget.lesson.isCompleted
                    ? Icons.check_circle
                    : _icon,
                size: 20,
                color: _iconColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.lesson.title,
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.lesson.isCompleted
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF475569),
                    fontWeight: widget.lesson.isCompleted
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (_isHovered || widget.lesson.isCompleted)
                Icon(
                  widget.lesson.isCompleted
                      ? Icons.check
                      : Icons.chevron_right,
                  size: 18,
                  color: widget.lesson.isCompleted
                      ? const Color(0xFF22C55E)
                      : const Color(0xFF94A3B8),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
