import 'package:flutter/material.dart';
import 'package:smet/model/Employee_learning_model.dart';
import 'package:smet/page/employee/learning_workspace/widgets/lesson_content.dart';
import 'package:smet/page/employee/learning_workspace/widgets/lesson_header.dart';
import 'package:smet/page/employee/learning_workspace/widgets/lesson_tabs.dart';
import 'package:smet/page/employee/learning_workspace/widgets/quiz_lesson_view.dart';
import 'package:smet/page/employee/learning_workspace/widgets/resources_sidebar.dart';
import 'package:smet/page/employee/learning_workspace/widgets/video_player.dart';

class LearningWorkspaceMobile extends StatelessWidget {
  final LearningCourse course;
  final LessonContent? lessonContent;
  final String? quizId;
  final String? courseId;
  final LessonTab selectedTab;
  final ValueChanged<LessonTab> onTabChanged;
  final VoidCallback onMarkComplete;
  final Function(Lesson) onLessonTap;
  final void Function(String quizId) onQuizTap;
  final Function(String) onNavigate;
  final VoidCallback onLogout;

  const LearningWorkspaceMobile({
    super.key,
    required this.course,
    this.lessonContent,
    this.quizId,
    this.courseId,
    required this.selectedTab,
    required this.onTabChanged,
    required this.onMarkComplete,
    required this.onLessonTap,
    required this.onQuizTap,
    required this.onNavigate,
    required this.onLogout,
  });

  bool get _isQuizMode => quizId != null && quizId!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context),
      endDrawer: _buildDrawer(context),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isQuizMode)
              Padding(
                padding: const EdgeInsets.all(16),
                child: QuizLessonView(
                  quizId: quizId!,
                  courseId: courseId,
                ),
              )
            else ...[
              _buildContentArea(lessonContent),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (lessonContent != null)
                      LessonHeader(
                        title: lessonContent!.title,
                        level: lessonContent!.level,
                        lessonId: lessonContent!.id,
                        isCompleted: lessonContent!.isCompleted,
                        onMarkComplete: onMarkComplete,
                      ),
                    const SizedBox(height: 20),
                    LessonTabs(
                      selectedTab: selectedTab,
                      onTabChanged: onTabChanged,
                      discussionCount: lessonContent?.discussions.length ?? 0,
                    ),
                    const SizedBox(height: 20),
                    _buildTabContent(),
                    if (lessonContent?.nextLesson != null) ...[
                      const SizedBox(height: 24),
                      ResourcesSidebar(
                        nextLesson: lessonContent!.nextLesson,
                        onJumpToLesson: onLessonTap,
                        courseCompleted: course.isCourseCompleted,
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back, color: Color(0xFF0F172A), size: 20),
        ),
        onPressed: () => onNavigate('/employee/courses'),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF137FEC), Color(0xFF0B5FC5)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF137FEC).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'SMETS',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF137FEC),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '${course.progressPercent}% hoàn thành',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Builder(
          builder: (context) => IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.menu, color: Color(0xFF64748B), size: 20),
            ),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTabContent() {
    if (lessonContent == null) return const SizedBox.shrink();

    switch (selectedTab) {
      case LessonTab.discussion:
        return DiscussionTab(
          lessonId: lessonContent!.id,
          initialDiscussions: const [],
          mentorId: course.mentorId,
          mentorName: course.mentorName,
        );
    }
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildDrawerHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                for (var i = 0; i < course.modules.length; i++) ...[
                  _buildModuleItem(course.modules[i]),
                  if (i < course.modules.length - 1)
                    const SizedBox(height: 8),
                ],
                if (course.finalQuizId != null) ...[
                  const SizedBox(height: 8),
                  Builder(
                    builder: (drawerContext) => _buildFinalQuizItem(drawerContext, course),
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                _buildLogoutItem(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 48, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF137FEC), Color(0xFF0B5FC5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Nội dung khóa học',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 22,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${course.progressPercent}% hoàn thành',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: course.progressPercent / 100,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${course.progressPercent}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleItem(LearningModule module) {
    return _ModuleDrawerItem(
      module: module,
      onLessonTap: onLessonTap,
      onQuizTap: onQuizTap,
    );
  }

  Widget _buildFinalQuizItem(BuildContext context, LearningCourse course) {
    final isLocked = course.progressPercent < 80;
    final isPassed = course.finalQuizPassed;

    IconData finalIcon() {
      if (isLocked) return Icons.lock_outline;
      if (isPassed) return Icons.check_circle;
      return Icons.cancel_outlined;
    }

    Color finalIconColor() {
      if (isLocked) return const Color(0xFF94A3B8);
      if (isPassed) return const Color(0xFF22C55E);
      return const Color(0xFFBA1A1A);
    }

    String finalSubtitle() {
      if (isLocked) return 'Hoàn thành 80% khóa học để mở';
      if (isPassed) return 'Đã đạt';
      return 'Chưa đạt – Làm lại';
    }

    return Container(
      decoration: BoxDecoration(
        gradient: !isLocked
            ? LinearGradient(
                colors: [
                  (isPassed
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF137FEC))
                      .withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              )
            : null,
        color: !isLocked ? null : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: !isLocked
              ? (isPassed
                      ? const Color(0xFF22C55E)
                      : const Color(0xFF137FEC))
                  .withValues(alpha: 0.2)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: finalIconColor().withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(finalIcon(), size: 22, color: finalIconColor()),
        ),
        title: const Text(
          'Bài kiểm tra cuối khóa',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          finalSubtitle(),
          style: TextStyle(fontSize: 11, color: finalIconColor()),
        ),
        trailing: isLocked
            ? null
            : Icon(Icons.chevron_right, size: 22, color: finalIconColor()),
        onTap: isLocked ? null : () {
          Navigator.pop(context);
          onQuizTap(course.finalQuizId!);
        },
      ),
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: ListTile(
        onTap: () {
          Navigator.pop(context);
          onLogout();
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.logout, color: Color(0xFFEF4444), size: 20),
        ),
        title: const Text(
          'Đăng xuất',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFFEF4444),
          ),
        ),
      ),
    );
  }

  static Widget _buildContentArea(LessonContent? lessonContent) {
    if (lessonContent == null) return const SizedBox.shrink();

    final isVideo = lessonContent.contentType == 'VIDEO' &&
        lessonContent.youtubeVideoId != null &&
        lessonContent.youtubeVideoId!.isNotEmpty;

    if (isVideo) {
      return VideoPlayerWidget(
        youtubeVideoId: lessonContent.youtubeVideoId!,
        thumbnailUrl: lessonContent.thumbnailUrl,
        videoDurationSeconds: lessonContent.videoDurationSeconds,
        currentPositionSeconds: lessonContent.currentPositionSeconds,
      );
    }

    final textContent = lessonContent.content ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF137FEC).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF137FEC).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  lessonContent.contentType == 'LINK'
                      ? Icons.link
                      : Icons.article_outlined,
                  size: 14,
                  color: const Color(0xFF137FEC),
                ),
                const SizedBox(width: 6),
                Text(
                  lessonContent.contentType == 'LINK' ? 'Tài liệu' : 'Văn bản',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF137FEC),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (textContent.isNotEmpty)
            SelectableText(
              textContent,
              style: const TextStyle(
                fontSize: 15,
                height: 1.8,
                color: Color(0xFF334155),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF94A3B8), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Chưa có nội dung cho bài học này.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ModuleDrawerItem extends StatefulWidget {
  final LearningModule module;
  final Function(Lesson) onLessonTap;
  final void Function(String) onQuizTap;

  const _ModuleDrawerItem({
    required this.module,
    required this.onLessonTap,
    required this.onQuizTap,
  });

  @override
  State<_ModuleDrawerItem> createState() => _ModuleDrawerItemState();
}

class _ModuleDrawerItemState extends State<_ModuleDrawerItem> {
  bool _expanded = false;

  IconData _moduleIcon() {
    if (widget.module.isLocked) return Icons.lock_outline;
    if (_expanded) return Icons.folder_open;
    return Icons.folder;
  }

  Color _moduleIconColor() {
    if (widget.module.isLocked) return const Color(0xFF94A3B8);
    return const Color(0xFF137FEC);
  }

  @override
  void initState() {
    super.initState();
    _expanded = widget.module.lessons.any((l) => l.isCurrent) ||
        widget.module.isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.module.isLocked) {
      return _buildLockedModule();
    }

    final isFinalOnly = widget.module.lessons.isEmpty &&
        widget.module.quizId != null &&
        (widget.module.title.toLowerCase().contains('assessment') ||
            widget.module.title.toLowerCase().contains('đánh giá') ||
            widget.module.title.toLowerCase().contains('final') ||
            widget.module.title.toLowerCase().contains('quiz'));

    if (isFinalOnly) {
      return _buildFinalOnlyModule();
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _moduleIconColor().withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _moduleIcon(),
                      size: 20,
                      color: _moduleIconColor(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.module.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: widget.module.progress >= 1.0
                                    ? const Color(0xFF22C55E).withValues(alpha: 0.1)
                                    : const Color(0xFF137FEC).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${(widget.module.progress * 100).round()}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: widget.module.progress >= 1.0
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFF137FEC),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${widget.module.lessons.where((l) => l.isCompleted).length}/${widget.module.lessons.length} bài',
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
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.expand_more,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  ...widget.module.lessons.map((lesson) {
                    return _LessonDrawerItem(
                      lesson: lesson,
                      onTap: () {
                        Navigator.pop(context);
                        widget.onLessonTap(lesson);
                      },
                    );
                  }),
                  if (widget.module.quizId != null) ...[
                    const SizedBox(height: 8),
                    _ModuleQuizDrawerItem(
                      quizId: widget.module.quizId!,
                      isCompleted: widget.module.isCompleted,
                      quizPassed: widget.module.quizPassed,
                      moduleProgress: widget.module.progress,
                      onTap: (id) {
                        Navigator.pop(context);
                        widget.onQuizTap(id);
                      },
                    ),
                  ],
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedModule() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF94A3B8).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lock_outline,
                size: 20, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.module.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalOnlyModule() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF64748B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.quiz_outlined,
                size: 20, color: Color(0xFF64748B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.module.title,
              style: const TextStyle(
                fontSize: 14,
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

class _LessonDrawerItem extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onTap;

  const _LessonDrawerItem({
    required this.lesson,
    required this.onTap,
  });

  IconData get _icon {
    if (lesson.isCompleted) return Icons.check_circle;
    switch (lesson.lessonType) {
      case LessonType.text:
        return Icons.article_outlined;
      case LessonType.link:
        return Icons.link;
      default:
        return lesson.isCurrent ? Icons.play_circle : Icons.circle_outlined;
    }
  }

  Color get _iconColor {
    if (lesson.isCompleted) return const Color(0xFF22C55E);
    if (lesson.isCurrent) return const Color(0xFF137FEC);
    return const Color(0xFF94A3B8);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            Icon(_icon, size: 20, color: _iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                lesson.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      lesson.isCurrent ? FontWeight.w600 : FontWeight.w500,
                  color: lesson.isCurrent
                      ? const Color(0xFF137FEC)
                      : (lesson.isCompleted
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF475569)),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (lesson.isCurrent)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF137FEC).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Đang học',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF137FEC),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ModuleQuizDrawerItem extends StatefulWidget {
  final String quizId;
  final bool isCompleted;
  final bool quizPassed;
  final double moduleProgress;
  final void Function(String) onTap;

  const _ModuleQuizDrawerItem({
    required this.quizId,
    required this.isCompleted,
    required this.quizPassed,
    required this.moduleProgress,
    required this.onTap,
  });

  @override
  State<_ModuleQuizDrawerItem> createState() => _ModuleQuizDrawerItemState();
}

class _ModuleQuizDrawerItemState extends State<_ModuleQuizDrawerItem> {
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
    return const Color(0xFFBA1A1A);
  }

  String get _labelText {
    if (_isLocked) return 'Hoàn thành 80% để mở';
    if (widget.quizPassed) return 'Kiểm tra Module';
    return 'Chưa đạt – Làm lại';
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: _isLocked ? null : () => widget.onTap(widget.quizId),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: _isHovered && !_isLocked
                ? const Color(0xFFF8FAFC)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(_icon, size: 20, color: _iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _labelText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _isLocked
                        ? const Color(0xFF94A3B8)
                        : (widget.quizPassed
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFBA1A1A)),
                  ),
                ),
              ),
              if (!_isLocked)
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
