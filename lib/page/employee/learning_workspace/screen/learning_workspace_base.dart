import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/learning_model.dart';
import 'package:smet/page/employee/learning_workspace/screen/learning_workspace_mobile.dart';
import 'package:smet/page/employee/learning_workspace/screen/learning_workspace_web.dart';
import 'package:smet/page/employee/learning_workspace/widgets/lesson_content.dart';
import 'package:smet/page/employee/learning_workspace/widgets/lesson_header.dart';
import 'package:smet/page/employee/learning_workspace/widgets/lesson_tabs.dart';
import 'package:smet/page/employee/learning_workspace/widgets/resources_sidebar.dart';
import 'package:smet/page/employee/learning_workspace/widgets/video_player.dart';
import 'package:smet/service/employee/learning_service.dart';

class LearningWorkspacePage extends StatefulWidget {
  final String courseId;
  final String? lessonId;

  const LearningWorkspacePage({
    super.key,
    required this.courseId,
    this.lessonId,
  });

  @override
  State<LearningWorkspacePage> createState() => _LearningWorkspacePageState();
}

class _LearningWorkspacePageState extends State<LearningWorkspacePage> {
  LearningCourse? _course;
  LessonContent? _lessonContent;
  LessonTab _selectedTab = LessonTab.overview;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load course progress
      final course = await LearningService.getCourseProgress(widget.courseId, 'user_1');
      
      // Load lesson content - use provided lessonId or first current lesson
      String targetLessonId = widget.lessonId ?? '';
      if (targetLessonId.isEmpty) {
        // Find current lesson
        for (var module in course.modules) {
          for (var lesson in module.lessons) {
            if (lesson.isCurrent) {
              targetLessonId = lesson.id;
              break;
            }
          }
          if (targetLessonId.isNotEmpty) break;
        }
        // If no current lesson, use first lesson
        if (targetLessonId.isEmpty && course.modules.isNotEmpty && course.modules.first.lessons.isNotEmpty) {
          targetLessonId = course.modules.first.lessons.first.id;
        }
      }
      
      final lessonContent = await LearningService.getLessonDetail(targetLessonId);

      setState(() {
        _course = course;
        _lessonContent = lessonContent;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading learning workspace: $e');
      setState(() {
        _error = 'Không thể tải dữ liệu';
        _isLoading = false;
      });
    }
  }

  void _onTabChanged(LessonTab tab) {
    setState(() {
      _selectedTab = tab;
    });
  }

  Future<void> _onMarkComplete() async {
    if (_lessonContent == null) return;
    
    try {
      await LearningService.markLessonComplete('lesson_1_1', 'user_1');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã đánh dấu hoàn thành!'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error marking complete: $e');
    }
  }

  void _onJumpToLesson(Lesson lesson) {
    context.go('/employee/learn/${widget.courseId}/${lesson.id}');
  }

  void _onNavigateTo(String path) {
    context.go(path);
  }

  void _onLogout() {
    context.go('/login');
  }

  // Build video player widget
  Widget buildVideoPlayer() {
    if (_lessonContent == null) return const SizedBox.shrink();

    return VideoPlayer(
      thumbnailUrl: _lessonContent!.thumbnailUrl,
      videoDurationSeconds: _lessonContent!.videoDurationSeconds,
      currentPositionSeconds: _lessonContent!.currentPositionSeconds,
    );
  }

  // Build lesson header widget
  Widget buildLessonHeader() {
    if (_lessonContent == null) return const SizedBox.shrink();

    return LessonHeader(
      title: _lessonContent!.title,
      durationMinutes: _lessonContent!.videoDurationSeconds ~/ 60,
      level: _lessonContent!.level,
      onMarkComplete: _onMarkComplete,
    );
  }

  // Build tabs widget
  Widget buildTabs() {
    return LessonTabs(
      selectedTab: _selectedTab,
      onTabChanged: _onTabChanged,
      discussionCount: _lessonContent?.discussions.length ?? 0,
    );
  }

  // Build tab content widget
  Widget buildTabContent() {
    if (_lessonContent == null) return const SizedBox.shrink();

    switch (_selectedTab) {
      case LessonTab.overview:
        return LessonOverviewTab(
          description: _lessonContent!.description,
          keyTakeaways: _lessonContent!.keyTakeaways,
        );
      case LessonTab.resources:
        return ResourcesTab(
          resources: _lessonContent!.resources,
        );
      case LessonTab.discussion:
        return DiscussionTab(
          discussions: _lessonContent!.discussions,
          onPostComment: (comment) {
            // TODO: Implement post comment
          },
        );
      case LessonTab.transcripts:
        return TranscriptTab(
          transcript: _lessonContent!.transcript,
        );
    }
  }

  // Build resources sidebar widget
  Widget buildResourcesSidebar() {
    if (_lessonContent == null) return const SizedBox.shrink();

    return ResourcesSidebar(
      resources: _lessonContent!.resources,
      nextLesson: _lessonContent!.nextLesson,
      onJumpToLesson: _onJumpToLesson,
    );
  }

  // Build sidebar navigation widget
  Widget buildSidebarNavigation() {
    if (_course == null) return const SizedBox.shrink();

    return _SidebarNavigation(
      course: _course!,
      onLessonTap: _onJumpToLesson,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF137FEC),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 850) {
              return LearningWorkspaceWeb(
                sidebarNavigation: buildSidebarNavigation(),
                videoPlayer: buildVideoPlayer(),
                lessonHeader: buildLessonHeader(),
                tabs: buildTabs(),
                tabContent: buildTabContent(),
                resourcesSidebar: buildResourcesSidebar(),
                onNavigate: _onNavigateTo,
                onLogout: _onLogout,
              );
            } else {
              return LearningWorkspaceMobile(
                course: _course!,
                lessonContent: _lessonContent!,
                selectedTab: _selectedTab,
                onTabChanged: _onTabChanged,
                onMarkComplete: _onMarkComplete,
                onLessonTap: _onJumpToLesson,
                onNavigate: _onNavigateTo,
                onLogout: _onLogout,
              );
            }
          },
        ),
      ),
    );
  }
}

// Sidebar Navigation Component
class _SidebarNavigation extends StatelessWidget {
  final LearningCourse course;
  final Function(Lesson) onLessonTap;

  const _SidebarNavigation({
    required this.course,
    required this.onLessonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Course Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      course.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '${course.progressPercent}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF137FEC),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: course.progressPercent / 100,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF137FEC)),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          // Modules List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: course.modules.length,
              itemBuilder: (context, moduleIndex) {
                final module = course.modules[moduleIndex];
                return _ModuleItem(
                  module: module,
                  onLessonTap: onLessonTap,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleItem extends StatefulWidget {
  final LearningModule module;
  final Function(Lesson) onLessonTap;

  const _ModuleItem({
    required this.module,
    required this.onLessonTap,
  });

  @override
  State<_ModuleItem> createState() => _ModuleItemState();
}

class _ModuleItemState extends State<_ModuleItem> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.module.isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Module Header
        InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  _isExpanded ? Icons.folder_open : (widget.module.isLocked ? Icons.lock : Icons.folder),
                  size: 20,
                  color: widget.module.isLocked ? const Color(0xFF94A3B8) : const Color(0xFF137FEC),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.module.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: widget.module.isLocked ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                if (!widget.module.isLocked)
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: const Color(0xFF94A3B8),
                  ),
              ],
            ),
          ),
        ),
        // Lessons
        if (_isExpanded && !widget.module.isLocked)
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              children: widget.module.lessons.map((lesson) {
                return _LessonItem(
                  lesson: lesson,
                  onTap: () => widget.onLessonTap(lesson),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _LessonItem extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onTap;

  const _LessonItem({
    required this.lesson,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: lesson.isCurrent
              ? const Color(0xFF137FEC).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              lesson.isCompleted
                  ? Icons.check_circle
                  : (lesson.isCurrent ? Icons.play_circle : Icons.circle_outlined),
              size: 18,
              color: lesson.isCompleted
                  ? const Color(0xFF22C55E)
                  : (lesson.isCurrent ? const Color(0xFF137FEC) : const Color(0xFF94A3B8)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                lesson.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: lesson.isCurrent ? FontWeight.w600 : FontWeight.normal,
                  color: lesson.isCurrent ? const Color(0xFF137FEC) : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
