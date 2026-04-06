import 'package:flutter/material.dart';
import 'package:smet/model/Employee_learning_model.dart';
import 'package:smet/page/employee/learning_workspace/widgets/lesson_content.dart';
import 'package:smet/page/employee/learning_workspace/widgets/lesson_header.dart';
import 'package:smet/page/employee/learning_workspace/widgets/lesson_tabs.dart';
import 'package:smet/page/employee/learning_workspace/widgets/resources_sidebar.dart';
import 'package:smet/page/employee/learning_workspace/widgets/video_player.dart';

class LearningWorkspaceMobile extends StatelessWidget {
  final LearningCourse course;
  final LessonContent lessonContent;
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
    required this.lessonContent,
    required this.selectedTab,
    required this.onTabChanged,
    required this.onMarkComplete,
    required this.onLessonTap,
    required this.onQuizTap,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => onNavigate('/employee/courses'),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF137FEC),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text(
              'SMETS',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF137FEC),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list, color: Color(0xFF64748B)),
            onPressed: () => _showSidebar(context),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Player hoặc Text Content
            _buildContentArea(lessonContent),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lesson Header
                  LessonHeader(
                    title: lessonContent.title,
                    durationMinutes: lessonContent.videoDurationSeconds ~/ 60,
                    level: lessonContent.level,
                    lessonId: lessonContent.id,
                    isCompleted: lessonContent.isCompleted,
                    onMarkComplete: onMarkComplete,
                  ),
                  const SizedBox(height: 20),
                  // Tabs
                  LessonTabs(
                    selectedTab: selectedTab,
                    onTabChanged: onTabChanged,
                    discussionCount: lessonContent.discussions.length,
                  ),
                  const SizedBox(height: 20),
                  // Tab Content
                  _buildTabContent(),
                  if (lessonContent.nextLesson != null) ...[
                    const SizedBox(height: 20),
                    ResourcesSidebar(
                      nextLesson: lessonContent.nextLesson,
                      onJumpToLesson: onLessonTap,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (selectedTab) {
      case LessonTab.overview:
        return LessonOverviewTab(
          description: lessonContent.description,
          keyTakeaways: lessonContent.keyTakeaways,
        );
      case LessonTab.discussion:
        return DiscussionTab(
          lessonId: lessonContent.id,
          initialDiscussions: const [],
        );
    }
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF137FEC)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      course.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${course.progressPercent}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: course.progressPercent / 100,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          // Modules
          ...course.modules.map((module) {
            return _buildModuleItem(module);
          }),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFF64748B)),
            title: const Text('Đăng xuất'),
            onTap: () {
              Navigator.pop(context);
              onLogout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModuleItem(LearningModule module) {
    return ExpansionTile(
      leading: Icon(
        module.isLocked ? Icons.lock : Icons.folder,
        color:
            module.isLocked ? const Color(0xFF94A3B8) : const Color(0xFF137FEC),
      ),
      title: Text(
        module.title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color:
              module.isLocked
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF0F172A),
        ),
      ),
      children: [
        ...module.lessons.map((lesson) {
          return ListTile(
            contentPadding: const EdgeInsets.only(left: 56, right: 16),
            leading: Icon(
              lesson.isCompleted
                  ? Icons.check_circle
                  : (lesson.isCurrent
                      ? Icons.play_circle
                      : (lesson.lessonType == LessonType.text
                          ? Icons.article_outlined
                          : (lesson.lessonType == LessonType.link
                              ? Icons.link
                              : Icons.circle_outlined))),
              size: 18,
              color:
                  lesson.isCompleted
                      ? const Color(0xFF22C55E)
                      : (lesson.isCurrent
                          ? const Color(0xFF137FEC)
                          : const Color(0xFF94A3B8)),
            ),
            title: Text(
              lesson.title,
              style: TextStyle(
                fontSize: 13,
                color:
                    lesson.isCurrent
                        ? const Color(0xFF137FEC)
                        : const Color(0xFF475569),
              ),
            ),
            onTap: () => onLessonTap(lesson),
          );
        }),
        if (module.quizId != null)
          ListTile(
            contentPadding: const EdgeInsets.only(left: 56, right: 16),
            leading: Icon(
              module.isCompleted
                  ? Icons.check_circle
                  : Icons.quiz_outlined,
              size: 18,
              color: module.isCompleted
                  ? const Color(0xFF22C55E)
                  : const Color(0xFF64748B),
            ),
            title: Text(
              module.isCompleted ? 'Kiểm tra Module' : 'Kiểm tra Module',
              style: TextStyle(
                fontSize: 13,
                color: module.isCompleted
                    ? const Color(0xFF22C55E)
                    : const Color(0xFF64748B),
              ),
            ),
            onTap: module.isCompleted
                ? () => onQuizTap(module.quizId!)
                : null,
          ),
      ],
    );
  }

  void _showSidebar(BuildContext context) {
    Scaffold.of(context).openDrawer();
  }

  static Widget _buildContentArea(LessonContent lessonContent) {
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

    // TEXT or LINK — hiển thị nội dung dạng văn bản
    final textContent = lessonContent.content ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF137FEC).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
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
            const Text(
              'Chưa có nội dung cho bài học này.',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF94A3B8),
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}
