import 'package:flutter/material.dart';
import 'package:smet/model/Employee_learning_model.dart';
import 'package:smet/page/employee/quiz/widgets/quiz_exam_theme.dart';

/// Course Outline Sidebar — modern Coursera-style:
/// - Progress pill per module
/// - Current lesson: highlight bg + left border primary
/// - Smooth expand/collapse animation
/// - Hover states on all interactive elements
class CourseOutlineSidebar extends StatefulWidget {
  final LearningCourse course;
  final void Function(Lesson lesson) onLessonTap;
  final void Function(String quizId) onQuizTap;
  final String? currentLessonId;
  final String? currentQuizId;

  const CourseOutlineSidebar({
    super.key,
    required this.course,
    required this.onLessonTap,
    required this.onQuizTap,
    this.currentLessonId,
    this.currentQuizId,
  });

  @override
  State<CourseOutlineSidebar> createState() => _CourseOutlineSidebarState();
}

class _CourseOutlineSidebarState extends State<CourseOutlineSidebar> {
  bool _collapsed = false;
  final ScrollController _scrollController = ScrollController();

  static const _primary = Color(0xFF137FEC);
  static const _border = Color(0xFFE2E8F0);
  static const _slate500 = Color(0xFF64748B);
  static const _success = Color(0xFF22C55E);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
              controller: _scrollController,
              thumbVisibility: true,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  for (var i = 0; i < widget.course.modules.length; i++)
                    Padding(
                      padding: EdgeInsets.only(bottom: i == 0 ? 0 : 12),
                      child: _ModuleSection(
                        module: widget.course.modules[i],
                        currentLessonId: widget.currentLessonId,
                        currentQuizId: widget.currentQuizId,
                        onLessonTap: widget.onLessonTap,
                        onQuizTap: widget.onQuizTap,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (widget.course.finalQuizId != null) _buildFinalQuizSection(),
          _buildCollapseFooter(),
        ],
      ),
    );
  }

  Widget _buildCourseHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
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
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: _slate500,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Progress pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.course.progressPercent.round().clamp(0, 100)}%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Gradient progress bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(999),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      width: constraints.maxWidth * _progress,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF137FEC), Color(0xFF22C55E)],
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalQuizSection() {
    final isActive = widget.currentQuizId != null;
    // Dùng enrollmentStatus thay vì progressPercent để xác định trạng thái khóa học
    final isLocked = widget.course.progressPercent < 80;
    final isPassed = widget.course.finalQuizPassed;

    IconData finalIcon() {
      if (isLocked) return Icons.lock_outline;
      if (isPassed) return Icons.check_circle;
      return Icons.cancel_outlined;
    }

    Color finalIconColor() {
      if (isLocked) return const Color(0xFFCBD5E1);
      if (isPassed) return _success;
      return QuizExamTheme.error;
    }

    Color finalTextColor() {
      if (isLocked) return const Color(0xFF94A3B8);
      if (isPassed) return _success;
      return QuizExamTheme.error;
    }

    String finalSubtitle() {
      if (isLocked) return 'Hoàn thành 80% khóa học để mở';
      if (isPassed) return 'Đã đạt';
      return 'Chưa đạt – Làm lại';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          // Divider-like separator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(child: Divider(height: 1, color: Color(0xFFE2E8F0))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Cuối khóa',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Expanded(child: Divider(height: 1, color: Color(0xFFE2E8F0))),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Final Quiz Row — giống _ModuleSection header
          MouseRegion(
            onEnter: (_) => setState(() {}),
            onExit: (_) => setState(() {}),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isLocked ? null : () => widget.onQuizTap(widget.course.finalQuizId!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? _primary.withValues(alpha: 0.08)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(
                        color: isActive ? _primary : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Module icon
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: finalIconColor().withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(finalIcon(), size: 20, color: finalIconColor()),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Bài kiểm tra cuối khóa',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isActive
                                          ? _primary
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.course.finalQuizPassed
                                        ? _success.withValues(alpha: 0.1)
                                        : _primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${widget.course.progressPercent.round().clamp(0, 100)}%',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: widget.course.finalQuizPassed
                                          ? _success
                                          : _primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child:                                 Text(
                                  finalSubtitle(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: finalTextColor(),
                                  ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: isActive ? _primary : const Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ),
              ),
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
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => setState(() => _collapsed = true),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
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
  final String? currentQuizId;
  final void Function(Lesson) onLessonTap;
  final void Function(String quizId) onQuizTap;

  const _ModuleSection({
    required this.module,
    required this.currentLessonId,
    required this.currentQuizId,
    required this.onLessonTap,
    required this.onQuizTap,
  });

  @override
  State<_ModuleSection> createState() => _ModuleSectionState();
}

class _ModuleSectionState extends State<_ModuleSection>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _animController;
  late Animation<double> _iconRotation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _expanded =
        widget.module.isExpanded ||
        widget.module.lessons.any((l) => l.isCurrent) ||
        widget.module.lessons.any((l) => l.id == widget.currentLessonId);
    _animController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _iconRotation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    if (_expanded) _animController.value = 1;
  }

  @override
  void didUpdateWidget(_ModuleSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldExpand =
        widget.module.isExpanded ||
        widget.module.lessons.any((l) => l.isCurrent) ||
        widget.module.lessons.any((l) => l.id == widget.currentLessonId);
    if (shouldExpand != _expanded) {
      _expanded = shouldExpand;
      if (_expanded) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  bool get _isFinalOnly {
    if (widget.module.lessons.isNotEmpty || widget.module.quizId == null) {
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
    if (_isFinalOnly) return _buildFinalAssessmentRow();
    if (widget.module.isLocked) return _buildLockedModule();

    // Lay module.progress tu API da co san
    // Backend: /lms/lessons/modules/{moduleId}/progress tra ve 0.0 - 1.0
    final progress = widget.module.progress;

    // completed/total chi dung de hien thi "3/4" - khong dung de tinh progress
    final completed = widget.module.lessons.where((l) => l.isCompleted).length;
    final total = widget.module.lessons.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Module header with hover
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: _isHovered ? const Color(0xFFF8FAFC) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() => _expanded = !_expanded);
                  if (_expanded) {
                    _animController.forward();
                  } else {
                    _animController.reverse();
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // Folder icon
                      Icon(
                        _expanded
                            ? Icons.folder_open_outlined
                            : Icons.folder_outlined,
                        size: 20,
                        color: const Color(0xFF137FEC),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.module.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                // Progress pill
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        progress >= 1.0
                                            ? const Color(
                                              0xFF22C55E,
                                            ).withValues(alpha: 0.1)
                                            : const Color(
                                              0xFF137FEC,
                                            ).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${(progress * 100).round()}%',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          progress >= 1.0
                                              ? const Color(0xFF22C55E)
                                              : const Color(0xFF137FEC),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$completed/$total',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      RotationTransition(
                        turns: _iconRotation,
                        child: const Icon(
                          Icons.expand_more,
                          size: 20,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Lessons list with animated reveal
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState:
              _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.only(left: 44, top: 6, bottom: 4),
            child: Column(
              children: [
                for (final lesson in widget.module.lessons)
                  _LessonRow(
                    lesson: lesson,
                    currentLessonId: widget.currentLessonId,
                    onTap: () => widget.onLessonTap(lesson),
                  ),
                if (widget.module.quizId != null)
                  _ModuleQuizRow(
                    quizId: widget.module.quizId!,
                    isCompleted: widget.module.isCompleted,
                    quizPassed: widget.module.quizPassed,
                    isActive: widget.currentQuizId == widget.module.quizId,
                    moduleProgress: widget.module.progress,
                    onTap: widget.onQuizTap,
                  ),
              ],
            ),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildLockedModule() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 20, color: Color(0xFFCBD5E1)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.module.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalAssessmentRow() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.quiz_outlined, size: 20, color: Color(0xFF64748B)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.module.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonRow extends StatefulWidget {
  final Lesson lesson;
  final String? currentLessonId;
  final VoidCallback onTap;

  const _LessonRow({
    required this.lesson,
    required this.currentLessonId,
    required this.onTap,
  });

  @override
  State<_LessonRow> createState() => _LessonRowState();
}

class _LessonRowState extends State<_LessonRow> {
  bool _isHovered = false;

  bool get _isActive =>
      widget.lesson.id == widget.currentLessonId || widget.lesson.isCurrent;

  IconData get _icon {
    if (widget.lesson.isCompleted) return Icons.check_circle;
    switch (widget.lesson.lessonType) {
      case LessonType.quiz:
        return Icons.quiz_outlined;
      case LessonType.text:
        return Icons.article_outlined;
      case LessonType.link:
        return Icons.link;
      default:
        return Icons.play_circle_outline;
    }
  }

  Color get _iconColor {
    if (widget.lesson.isCompleted) return const Color(0xFF22C55E);
    if (_isActive) return const Color(0xFF137FEC);
    return const Color(0xFF94A3B8);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color:
                _isActive
                    ? const Color(0xFF137FEC).withValues(alpha: 0.08)
                    : (_isHovered
                        ? const Color(0xFFF8FAFC)
                        : Colors.transparent),
            borderRadius: BorderRadius.circular(6),
            border:
                _isActive
                    ? const Border(
                      left: BorderSide(color: Color(0xFF137FEC), width: 3),
                    )
                    : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(_icon, size: 20, color: _iconColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.lesson.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              _isActive ? FontWeight.w600 : FontWeight.w500,
                          color:
                              _isActive
                                  ? const Color(0xFF137FEC)
                                  : (widget.lesson.isCompleted
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFF475569)),
                          height: 1.35,
                        ),
                      ),
                    ),
                    if (_isHovered && !widget.lesson.isCompleted)
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Color(0xFFCBD5E1),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModuleQuizRow extends StatefulWidget {
  final String quizId;
  /// Module đã hoàn thành (lesson + quiz pass)
  final bool isCompleted;
  /// Quiz đã pass (điểm >= passingScore)
  final bool quizPassed;
  final bool isActive;
  final double moduleProgress; // 0.0 - 1.0
  final void Function(String) onTap;

  const _ModuleQuizRow({
    required this.quizId,
    required this.isCompleted,
    required this.quizPassed,
    required this.isActive,
    required this.moduleProgress,
    required this.onTap,
  });

  @override
  State<_ModuleQuizRow> createState() => _ModuleQuizRowState();
}

class _ModuleQuizRowState extends State<_ModuleQuizRow> {
  bool _isHovered = false;
  bool get _isLocked => widget.moduleProgress < 0.8;

  IconData get _icon {
    if (_isLocked) return Icons.lock_outline;
    if (widget.quizPassed) return Icons.check_circle;
    return Icons.cancel_outlined;
  }

  Color get _iconColor {
    if (_isLocked) return const Color(0xFFCBD5E1);
    if (widget.quizPassed) return const Color(0xFF22C55E);
    return QuizExamTheme.error;
  }

  String get _labelText {
    if (_isLocked) return 'Hoàn thành 80% bài học để mở';
    if (widget.quizPassed) return 'Kiểm tra Module';
    return 'Chưa đạt – Làm lại';
  }

  Color get _textColor {
    if (_isLocked) return const Color(0xFF94A3B8);
    if (widget.quizPassed) return const Color(0xFF22C55E);
    return QuizExamTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color:
                widget.isActive
                    ? const Color(0xFF137FEC).withValues(alpha: 0.08)
                    : (_isHovered && !_isLocked
                        ? const Color(0xFFF8FAFC)
                        : Colors.transparent),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLocked ? null : () => widget.onTap(widget.quizId),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(_icon, size: 20, color: _iconColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _labelText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              widget.isActive
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                          color: _textColor,
                          height: 1.35,
                        ),
                      ),
                    ),
                    if (_isLocked)
                      Tooltip(
                        message: 'Hoàn thành 80% bài học để mở',
                        child: const Icon(
                          Icons.help_outline,
                          size: 15,
                          color: Color(0xFFCBD5E1),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
