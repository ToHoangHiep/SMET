import 'package:flutter/material.dart';
import 'package:smet/model/learning_model.dart';

/// Sidebar danh sách module / bài học — UI theo mock HTML (w-80, Lexend-like).
class CourseOutlineSidebar extends StatefulWidget {
  final LearningCourse course;
  final void Function(Lesson lesson) onLessonTap;
  final String? currentLessonId;

  const CourseOutlineSidebar({
    super.key,
    required this.course,
    required this.onLessonTap,
    this.currentLessonId,
  });

  @override
  State<CourseOutlineSidebar> createState() => _CourseOutlineSidebarState();
}

class _CourseOutlineSidebarState extends State<CourseOutlineSidebar> {
  bool _collapsed = false;

  static const _primary = Color(0xFF137FEC);
  static const _border = Color(0xFFE2E8F0);
  static const _slate500 = Color(0xFF64748B);
  static const _slate600 = Color(0xFF475569);
  static const _slate900 = Color(0xFF0F172A);
  static const _bgHover = Color(0xFFF8FAFC);

  String get _courseTitle {
    final t = widget.course.title.trim();
    return t.isEmpty ? 'Khóa học' : t;
  }

  double get _progress => widget.course.progressPercent.clamp(0, 100) / 100.0;

  @override
  Widget build(BuildContext context) {
    if (_collapsed) {
      return _buildCollapsedRail();
    }

    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: _border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCourseHeader(),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (var i = 0; i < widget.course.modules.length; i++)
                    Padding(
                      padding: EdgeInsets.only(bottom: i == 0 ? 0 : 16),
                      child: _ModuleSection(
                        module: widget.course.modules[i],
                        currentLessonId: widget.currentLessonId,
                        onLessonTap: widget.onLessonTap,
                        primary: _primary,
                        border: _border,
                        slate500: _slate500,
                        slate600: _slate600,
                        slate900: _slate900,
                        bgHover: _bgHover,
                      ),
                    ),
                ],
              ),
            ),
          ),
          _buildCollapseFooter(),
        ],
      ),
    );
  }

  Widget _buildCourseHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _courseTitle.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: _slate500,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.course.progressPercent.round().clamp(0, 100)}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(_primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapseFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _border, width: 1)),
      ),
      child: Material(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => setState(() => _collapsed = true),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.menu_open_rounded,
                  size: 18,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Thu gọn danh sách',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedRail() {
    return Container(
      width: 56,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: _border, width: 1)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          IconButton(
            tooltip: 'Mở rộng danh sách khóa học',
            onPressed: () => setState(() => _collapsed = false),
            icon: const Icon(Icons.menu_open, color: _primary),
          ),
          const Spacer(),
          RotatedBox(
            quarterTurns: 3,
            child: Text(
              _courseTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _slate500,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _ModuleSection extends StatefulWidget {
  final LearningModule module;
  final String? currentLessonId;
  final void Function(Lesson) onLessonTap;
  final Color primary;
  final Color border;
  final Color slate500;
  final Color slate600;
  final Color slate900;
  final Color bgHover;

  const _ModuleSection({
    required this.module,
    required this.currentLessonId,
    required this.onLessonTap,
    required this.primary,
    required this.border,
    required this.slate500,
    required this.slate600,
    required this.slate900,
    required this.bgHover,
  });

  @override
  State<_ModuleSection> createState() => _ModuleSectionState();
}

class _ModuleSectionState extends State<_ModuleSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded =
        widget.module.isExpanded ||
        widget.module.lessons.any((l) => l.isCurrent) ||
        widget.module.lessons.any((l) => l.id == widget.currentLessonId);
  }

  bool get _isFinalOnly {
    if (widget.module.isLocked || widget.module.lessons.isNotEmpty) {
      return false;
    }
    final t = widget.module.title.toLowerCase();
    return t.contains('assessment') ||
        t.contains('đánh giá') ||
        t.contains('final') ||
        t.contains('quiz');
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinalOnly) {
      return _buildFinalAssessmentRow();
    }

    if (widget.module.isLocked) {
      return _buildLockedModule();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    _expanded
                        ? Icons.folder_open_outlined
                        : Icons.folder_outlined,
                    size: 22,
                    color: widget.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.module.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.slate900,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 22,
                    color: widget.slate500,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(left: 36, top: 4),
            child: Column(
              children:
                  widget.module.lessons.map((lesson) {
                    final isActive =
                        lesson.id == widget.currentLessonId || lesson.isCurrent;
                    return _LessonRow(
                      lesson: lesson,
                      isActive: isActive,
                      onTap: () => widget.onLessonTap(lesson),
                      primary: widget.primary,
                      slate600: widget.slate600,
                      bgHover: widget.bgHover,
                    );
                  }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildLockedModule() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.lock_outline, size: 22, color: widget.slate500),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.module.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: widget.slate500,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, size: 22, color: widget.slate500),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinalAssessmentRow() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.quiz_outlined, size: 22, color: widget.slate500),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.module.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: widget.slate900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  final Lesson lesson;
  final bool isActive;
  final VoidCallback onTap;
  final Color primary;
  final Color slate600;
  final Color bgHover;

  const _LessonRow({
    required this.lesson,
    required this.isActive,
    required this.onTap,
    required this.primary,
    required this.slate600,
    required this.bgHover,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          hoverColor: bgHover,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color:
                  isActive
                      ? primary.withValues(alpha: 0.1)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    lesson.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? primary : slate600,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  lesson.isCompleted
                      ? Icons.check_circle_outline
                      : Icons.play_circle_outline,
                  size: 20,
                  color:
                      lesson.isCompleted
                          ? const Color(0xFF22C55E)
                          : (isActive ? primary : slate600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
