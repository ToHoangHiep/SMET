import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/learning_model.dart';
import 'package:smet/page/employee/learning_workspace/screen/learning_workspace_mobile.dart';
import 'package:smet/page/employee/learning_workspace/screen/learning_workspace_web.dart';
import 'package:smet/page/employee/learning_workspace/widgets/course_outline_sidebar.dart';
import 'package:smet/page/employee/learning_workspace/widgets/lesson_content.dart';
import 'package:smet/page/employee/learning_workspace/widgets/lesson_header.dart';
import 'package:smet/page/employee/learning_workspace/widgets/lesson_tabs.dart';
import 'package:smet/page/employee/learning_workspace/widgets/resources_sidebar.dart';
import 'package:smet/page/employee/learning_workspace/widgets/video_player.dart';
import 'package:smet/service/employee/lms_service.dart';
import 'package:smet/service/employee/course_service.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';

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
      final course = await LmsService.getCourseProgress(
        widget.courseId,
        'user_1',
      );

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
        if (targetLessonId.isEmpty &&
            course.modules.isNotEmpty &&
            course.modules.first.lessons.isNotEmpty) {
          targetLessonId = course.modules.first.lessons.first.id;
        }
      }

      final lessonContent = await LmsService.getLessonDetail(
        targetLessonId,
      );

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
      await CourseService.completeLesson(_lessonContent!.id);
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
      lessonId: _lessonContent!.id,
      onMarkComplete: _onMarkComplete,
      onTakeQuiz: _onTakeQuiz,
    );
  }

  void _onTakeQuiz() {
    if (_lessonContent == null) return;
    context.go('/employee/quiz/${_lessonContent!.id}');
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
        return ResourcesTab(resources: _lessonContent!.resources);
      case LessonTab.discussion:
        return DiscussionTab(
          discussions: _lessonContent!.discussions,
          onPostComment: (comment) {
            // TODO: Implement post comment
          },
        );
      case LessonTab.transcripts:
        return TranscriptTab(transcript: _lessonContent!.transcript);
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

  // Build sidebar navigation widget (danh sách module / bài học — UI mock)
  Widget buildSidebarNavigation() {
    if (_course == null) return const SizedBox.shrink();

    return CourseOutlineSidebar(
      course: _course!,
      currentLessonId: _lessonContent?.id,
      onLessonTap: _onJumpToLesson,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF137FEC)),
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
                style: const TextStyle(fontSize: 16, color: Color(0xFF64748B)),
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
                breadcrumbs: [
                  const BreadcrumbItem(
                    label: 'Trang chủ',
                    route: '/employee/dashboard',
                  ),
                  const BreadcrumbItem(
                    label: 'Danh mục khóa học',
                    route: '/employee/courses',
                  ),
                  if (_course != null)
                    BreadcrumbItem(
                      label: _course!.title,
                      route: '/employee/course/${_course!.id}',
                    ),
                  BreadcrumbItem(label: _lessonContent?.title ?? 'Bài học'),
                ],
              );
            } else {
              return LearningWorkspaceMobile(
                course: _course!,
                lessonContent: _lessonContent!,
                selectedTab: _selectedTab,
                onTabChanged: _onTabChanged,
                onMarkComplete: _onMarkComplete,
                onTakeQuiz: _onTakeQuiz,
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
