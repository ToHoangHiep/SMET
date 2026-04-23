import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/Employee_learning_model.dart';
import 'package:smet/page/employee/learning_workspace/screen/learning_workspace_mobile.dart';
import 'package:smet/page/employee/learning_workspace/screen/learning_workspace_web.dart';
import 'package:smet/page/employee/learning_workspace/widgets/course_outline_sidebar.dart';
import 'package:smet/page/employee/learning_workspace/widgets/lesson_content.dart';
import 'package:smet/page/employee/learning_workspace/widgets/lesson_header.dart';
import 'package:smet/page/employee/learning_workspace/widgets/lesson_tabs.dart';
import 'package:smet/page/employee/learning_workspace/widgets/quiz_lesson_view.dart';
import 'package:smet/page/employee/learning_workspace/widgets/resources_sidebar.dart';
import 'package:smet/page/employee/learning_workspace/widgets/video_player.dart';
import 'package:smet/service/common/global_notification_service.dart';
import 'package:smet/service/employee/lms_service.dart';
import 'package:smet/service/common/auth_service.dart';
import 'package:smet/service/employee/course_service.dart';
import 'package:smet/service/chat/chat_service.dart';
import 'package:smet/model/chat/chat_models.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';

class LearningWorkspacePage extends StatefulWidget {
  final String courseId;
  final String? lessonId;
  final String? quizId;
  final String? learningPathId;
  final String? from;

  const LearningWorkspacePage({
    super.key,
    required this.courseId,
    this.lessonId,
    this.quizId,
    this.learningPathId,
    this.from,
  });

  @override
  State<LearningWorkspacePage> createState() => _LearningWorkspacePageState();
}

class _LearningWorkspacePageState extends State<LearningWorkspacePage>
    with SingleTickerProviderStateMixin {
  static int _debugSetStateCount = 0;

  LearningCourse? _course;
  LessonContent? _lessonContent;
  String? _currentQuizId;
  LessonTab _selectedTab = LessonTab.discussion;
  bool _isLoading = true;
  String? _error;
  LearningPathDetail? _learningPath;
  int _discussionCount = 0;
  bool _isQuizMode = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  Future<void> _onQuizResetSuccess() async {
    await _loadCourseOnly();
  }

  Future<void> _sendVideoProgress(String lessonId, int watchedSeconds, int totalSeconds) async {
    if (watchedSeconds <= 0 || totalSeconds <= 0) return;
    // Fire-and-forget: don't block UI
    LmsService.updateVideoProgress(lessonId, watchedSeconds, totalSeconds);
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LearningWorkspacePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.courseId != widget.courseId ||
        oldWidget.lessonId != widget.lessonId ||
        oldWidget.quizId != widget.quizId ||
        oldWidget.learningPathId != widget.learningPathId) {
      _loadData();
    }
  }

  BreadcrumbItem _buildBreadcrumbParent() {
    switch (widget.from) {
      case 'my_courses':
        return const BreadcrumbItem(
          label: 'Khóa học của tôi',
          route: '/employee/my-courses',
        );
      case 'dashboard':
        return const BreadcrumbItem(
          label: 'Trang chủ',
          route: '/employee/dashboard',
        );
      case 'learning_path':
        return const BreadcrumbItem(
          label: 'Lộ trình học tập',
          route: '/employee/my-learning-paths',
        );
      case 'search':
        return const BreadcrumbItem(
          label: 'Tìm kiếm',
          route: '/employee/search',
        );
      default:
        return const BreadcrumbItem(
          label: 'Danh mục khóa học',
          route: '/employee/courses',
        );
    }
  }

  Future<void> _loadData() async {
    _fadeController.reset();
    debugPrint('[DEBUG setState #${++_debugSetStateCount}] _loadData START');
    setState(() {
      _isLoading = true;
      _error = null;
      _currentQuizId = widget.quizId;
    });

    try {
      final user = await AuthService.getCurrentUser();
      final course = await LmsService.getCourseProgress(
        widget.courseId,
        user.id.toString(),
      );

      LearningPathDetail? pathDetail;
      if (widget.learningPathId != null) {
        pathDetail = await LmsService.getLearningPathDetail(widget.learningPathId!);
      }

      if (widget.quizId != null) {
        debugPrint('[DEBUG setState #${++_debugSetStateCount}] _loadData QUIZ mode');
        setState(() {
          _course = course;
          _lessonContent = null;
          _learningPath = pathDetail;
          _isQuizMode = true;
          _isLoading = false;
        });
        _fadeController.forward();
        return;
      }

      _isQuizMode = false;
      String targetLessonId = widget.lessonId ?? '';
      if (targetLessonId.isEmpty) {
        for (var module in course.modules) {
          for (var lesson in module.lessons) {
            if (lesson.isCurrent) {
              targetLessonId = lesson.id;
              break;
            }
          }
          if (targetLessonId.isNotEmpty) break;
        }
        if (targetLessonId.isEmpty &&
            course.modules.isNotEmpty &&
            course.modules.first.lessons.isNotEmpty) {
          targetLessonId = course.modules.first.lessons.first.id;
        }
      }

      int fetchedCount = 0;
      LessonContent? lessonContent;
      if (targetLessonId.isNotEmpty) {
        lessonContent = await LmsService.getLessonDetail(targetLessonId);

        try {
          final lessonIdInt = int.tryParse(targetLessonId) ?? 0;
          if (lessonIdInt > 0) {
            final roomId = await ChatService.createOrGetRoom(
              mentorId: 0,
              contextType: ChatContextType.LESSON,
              contextId: lessonIdInt,
            );
            final messages = await ChatService.getMessages(roomId: roomId);
            fetchedCount = messages.length;
          }
        } catch (_) {
          fetchedCount = 0;
        }
      }

      debugPrint('[DEBUG setState #${++_debugSetStateCount}] _loadData FINAL');
      setState(() {
        _course = course;
        _lessonContent = lessonContent;
        _learningPath = pathDetail;
        _discussionCount = fetchedCount;
        _isLoading = false;
      });
      _loadLessonDuration();
      _fadeController.forward();
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
      final lessonSuccess = await CourseService.completeLesson(_lessonContent!.id);

      if (lessonSuccess) {
        await _loadCourseOnly();

        // Sau khi reload, neu progress = 100% nhung chua COMPLETED -> goi completeCourse
        final course = _course;
        if (course != null &&
            course.progressPercent >= 100 &&
            !course.isCourseCompleted) {
          final completeSuccess = await CourseService.completeCourse(widget.courseId);
          if (completeSuccess) {
            // Reload lai de lay enrollmentStatus moi
            await _loadCourseOnly();
            if (mounted) {
              GlobalNotificationService.show(
                context: context,
                message: 'Chuc mung! Ban da hoan thanh khoa hoc!',
                type: NotificationType.success,
              );
            }
          }
        } else {
          if (mounted) {
            GlobalNotificationService.show(
              context: context,
              message: 'Da danh dau hoan thanh!',
              type: NotificationType.success,
            );
          }
        }
      } else {
        if (mounted) {
          GlobalNotificationService.show(
            context: context,
            message: 'Khong the danh dau hoan thanh. Vui long thu lai.',
            type: NotificationType.error,
          );
        }
      }
    } catch (e) {
      debugPrint('Error marking complete: $e');
    }
  }

  Future<void> _loadCourseOnly() async {
    try {
      final user = await AuthService.getCurrentUser();
      final course = await LmsService.getCourseProgress(
        widget.courseId,
        user.id.toString(),
      );
      LearningPathDetail? pathDetail;
      if (widget.learningPathId != null) {
        pathDetail = await LmsService.getLearningPathDetail(widget.learningPathId!);
      }
      debugPrint('[DEBUG setState #${++_debugSetStateCount}] _loadCourseOnly');
      setState(() {
        _course = course;
        if (pathDetail != null) {
          _learningPath = pathDetail;
        }
      });
    } catch (e) {
      debugPrint('Error reloading course: $e');
    }
  }

  String _locationForLearnLesson(String lessonId) {
    final path = '/employee/learn/${widget.courseId}/$lessonId';
    final lpId = widget.learningPathId;
    final Map<String, String> q = {};
    if (lpId != null && lpId.isNotEmpty) {
      q['learningPathId'] = lpId;
      q['from'] = 'learning_path';
    } else if (widget.from != null && widget.from!.isNotEmpty) {
      q['from'] = widget.from!;
    }
    if (q.isEmpty) return path;
    return Uri(path: path, queryParameters: q).toString();
  }

  void _onJumpToLesson(Lesson lesson) {
    if (lesson.lessonType == LessonType.quiz) {
      _onTakeQuiz(lesson.id);
    } else {
      context.go(_locationForLearnLesson(lesson.id));
    }
  }

  void _onTakeQuiz(String quizId) {
    QuizLessonView.onQuizPassedFromQuizPage = _onQuizPassedFromLessonView;
    context.go('/employee/learn/${widget.courseId}?quizId=$quizId');
  }

  void _onQuizPassedFromLessonView() {
    _loadCourseOnly();
  }

  void _onQuizTap(String quizId) {
    context.go('/employee/learn/${widget.courseId}?quizId=$quizId');
  }

  void _onCourseInPathTap(String courseId) {
    if (widget.learningPathId != null) {
      context.go('/employee/learn/$courseId?learningPathId=${widget.learningPathId}&from=learning_path');
    } else {
      context.go('/employee/learn/$courseId');
    }
  }

  void _onNavigateTo(String path) {
    context.go(path);
  }

  void _handleLogout() async {
    await AuthService.logout();
    if (!mounted) return;
    context.go('/login');
  }

  Future<void> _showVideoCompleteDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF137FEC), size: 28),
            SizedBox(width: 12),
            Text('Hoàn thành bài học'),
          ],
        ),
        content: const Text(
          'Video đã phát xong. Bạn có chắc chắn muốn đánh dấu hoàn thành bài học này?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF137FEC),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _onMarkComplete();
    }
  }

  Widget buildContentArea() {
    if (_isQuizMode && widget.quizId != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        child: QuizLessonView(
          quizId: widget.quizId!,
          courseId: widget.courseId,
          onResetSuccess: _onQuizResetSuccess,
        ),
      );
    }

    if (_lessonContent == null) return const SizedBox.shrink();

    if (_lessonContent!.contentType == 'VIDEO' &&
        _lessonContent!.youtubeVideoId != null &&
        _lessonContent!.youtubeVideoId!.isNotEmpty) {
      return VideoPlayerWidget(
        youtubeVideoId: _lessonContent!.youtubeVideoId,
        thumbnailUrl: _lessonContent!.thumbnailUrl,
        videoDurationSeconds: _lessonContent!.videoDurationSeconds,
        currentPositionSeconds: _lessonContent!.currentPositionSeconds,
        onPlay: () {
          debugPrint('Video started playing');
        },
        onVideoComplete: () {
          debugPrint('Video completed');
          _showVideoCompleteDialog();
        },
        onProgress: (currentSeconds, totalSeconds) {
          _sendVideoProgress(_lessonContent!.id, currentSeconds, totalSeconds);
        },
      );
    }

    final textContent = _lessonContent!.content ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      _lessonContent!.contentType == 'LINK'
                          ? Icons.link
                          : Icons.article_outlined,
                      size: 14,
                      color: const Color(0xFF137FEC),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _lessonContent!.contentType == 'LINK' ? 'Tài liệu' : 'Văn bản',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF137FEC),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF94A3B8), size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Chưa có nội dung cho bài học này.',
                    style: TextStyle(
                      fontSize: 15,
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

  String? _formatDuration(int seconds) {
    if (seconds <= 0) return '';
    if (seconds < 60) return '$seconds giây';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '$minutes phút';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '$hours giờ';
    return '$hours giờ $remainingMinutes phút';
  }

  String? _lessonDurationMinutes;

  void _loadLessonDuration() {
    if (_course == null || _lessonContent == null) return;
    for (var module in _course!.modules) {
      for (var lesson in module.lessons) {
        if (lesson.id == _lessonContent!.id) {
          _lessonDurationMinutes = _formatDuration(lesson.durationMinutes * 60);
          return;
        }
      }
    }
  }

  Widget buildLessonHeader() {
    if (_lessonContent == null && !_isQuizMode) return const SizedBox.shrink();

    if (_isQuizMode && widget.quizId != null) {
      return const SizedBox.shrink();
    }

    return LessonHeader(
      title: _lessonContent!.title,
      level: _lessonContent!.level,
      lessonId: _lessonContent!.id,
      isCompleted: _lessonContent!.isCompleted,
      onMarkComplete: _onMarkComplete,
      lessonDuration: _lessonDurationMinutes,
    );
  }

  Widget buildTabs() {
    if (_isQuizMode && widget.quizId != null) {
      return const SizedBox.shrink();
    }

    return LessonTabs(
      selectedTab: _selectedTab,
      onTabChanged: _onTabChanged,
      discussionCount: _discussionCount,
    );
  }

  Widget buildTabContent() {
    if (_isQuizMode && widget.quizId != null) {
      return const SizedBox.shrink();
    }

    if (_lessonContent == null) return const SizedBox.shrink();

    switch (_selectedTab) {
      case LessonTab.discussion:
        return DiscussionTab(
          lessonId: _lessonContent!.id,
          courseId: widget.courseId,
          initialDiscussions: const [],
          mentorId: _course?.mentorId ?? 0,
          mentorName: _course?.mentorName ?? 'Giảng viên',
        );
    }
  }

  Widget? buildResourcesSidebar() {
    if (_lessonContent == null) return null;
    final next = _lessonContent!.nextLesson;
    if (next == null && _learningPath == null) return null;

    return ResourcesSidebar(
      nextLesson: next,
      onJumpToLesson: _onJumpToLesson,
      learningPath: _learningPath,
      currentCourseId: widget.courseId,
      onCourseTap: _onCourseInPathTap,
      courseProgress: _course?.progressPercent,
      courseCompleted: _course?.isCourseCompleted ?? false,
    );
  }

  Widget buildSidebarNavigation() {
    if (_course == null) return const SizedBox.shrink();

    return CourseOutlineSidebar(
      course: _course!,
      currentLessonId: _lessonContent?.id,
      currentQuizId: _currentQuizId,
      onLessonTap: _onJumpToLesson,
      onQuizTap: _onQuizTap,
    );
  }

  static int _debugLwpBuild = 0;

  @override
  Widget build(BuildContext context) {
    debugPrint('[DEBUG LearningWorkspacePage build #${++_debugLwpBuild}]');
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: const _WorkspaceLoadingSkeleton(),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: _WorkspaceErrorState(
          error: _error!,
          onRetry: _loadData,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 850) {
                return Stack(
                  children: [
                    LearningWorkspaceWeb(
                      sidebarNavigation: buildSidebarNavigation(),
                      contentArea: buildContentArea(),
                      lessonHeader: buildLessonHeader(),
                      tabs: buildTabs(),
                      tabContent: buildTabContent(),
                      resourcesSidebar: buildResourcesSidebar(),
                      onNavigate: _onNavigateTo,
                      onLogout: _handleLogout,
                      breadcrumbs: [
                        const BreadcrumbItem(
                          label: 'Trang chủ',
                          route: '/employee/dashboard',
                        ),
                        _buildBreadcrumbParent(),
                        if (_course != null)
                          BreadcrumbItem(
                            label: _course!.title.trim().isEmpty
                                ? 'Khóa học'
                                : _course!.title.trim(),
                            route: '/employee/course/${_course!.id}',
                          ),
                        BreadcrumbItem(
                          label: (_isQuizMode && widget.quizId != null)
                              ? 'Bài kiểm tra'
                              : ((_lessonContent?.title ?? '').trim().isEmpty
                                  ? 'Bài học'
                                  : _lessonContent!.title.trim()),
                        ),
                      ],
                      isQuizMode: _isQuizMode,
                    ),
                    // FloatingChatButton is inside EmployeeShell already
                  ],
                );
              } else {
                return Stack(
                  children: [
                    LearningWorkspaceMobile(
                      course: _course!,
                      lessonContent: _lessonContent,
                      quizId: _isQuizMode ? widget.quizId : null,
                      courseId: widget.courseId,
                      selectedTab: _selectedTab,
                      onTabChanged: _onTabChanged,
                      onMarkComplete: _onMarkComplete,
                      onLessonTap: _onJumpToLesson,
                      onQuizTap: _onQuizTap,
                      onNavigate: _onNavigateTo,
                      onLogout: _handleLogout,
                      onQuizResetSuccess: _onQuizResetSuccess,
                    ),
                    // FloatingChatButton is inside EmployeeShell already
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

class _WorkspaceLoadingSkeleton extends StatefulWidget {
  const _WorkspaceLoadingSkeleton();

  @override
  State<_WorkspaceLoadingSkeleton> createState() => _WorkspaceLoadingSkeletonState();
}

class _WorkspaceLoadingSkeletonState extends State<_WorkspaceLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _shimmerColor(Color base) {
    return Color.lerp(
      base,
      base.withValues(alpha: 0.08),
      _animation.value,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 850;

        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isWide) ...[
                  // Sidebar skeleton
                  Container(
                    width: 320,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        right: BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkeletonBox(
                          height: 80,
                          borderRadius: 12,
                          color: _shimmerColor(const Color(0xFFF1F5F9)),
                        ),
                        const SizedBox(height: 20),
                        ...List.generate(4, (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _SkeletonBox(
                            height: i == 0 ? 60 : 44,
                            borderRadius: 10,
                            color: _shimmerColor(const Color(0xFFF1F5F9)),
                          ),
                        )),
                        const Spacer(),
                        _SkeletonBox(
                          height: 44,
                          borderRadius: 10,
                          color: _shimmerColor(const Color(0xFFF1F5F9)),
                        ),
                      ],
                    ),
                  ),
                ],
                // Content skeleton
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkeletonBox(
                          height: 400,
                          borderRadius: 16,
                          color: _shimmerColor(const Color(0xFFE2E8F0)),
                        ),
                        const SizedBox(height: 28),
                        _SkeletonBox(
                          height: 200,
                          borderRadius: 16,
                          color: _shimmerColor(const Color(0xFFF1F5F9)),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _SkeletonBox(
                                height: 44,
                                borderRadius: 10,
                                color: _shimmerColor(const Color(0xFFE2E8F0)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SkeletonBox(
                                height: 44,
                                borderRadius: 10,
                                color: _shimmerColor(const Color(0xFFE2E8F0)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _SkeletonBox(
                                height: 120,
                                borderRadius: 14,
                                color: _shimmerColor(const Color(0xFFF1F5F9)),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Container(
                              width: 300,
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: _shimmerColor(const Color(0xFFF1F5F9)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double height;
  final double borderRadius;
  final Color color;

  const _SkeletonBox({
    required this.height,
    this.borderRadius = 8,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: color,
      ),
    );
  }
}

class _WorkspaceErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _WorkspaceErrorState({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 64,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Đã xảy ra lỗi',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            _RetryButton(onTap: onRetry),
          ],
        ),
      ),
    );
  }
}

class _RetryButton extends StatefulWidget {
  final VoidCallback onTap;

  const _RetryButton({required this.onTap});

  @override
  State<_RetryButton> createState() => _RetryButtonState();
}

class _RetryButtonState extends State<_RetryButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF137FEC), Color(0xFF0B5FC5)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF137FEC).withValues(
                  alpha: _isHovered ? 0.5 : 0.35,
                ),
                blurRadius: _isHovered ? 20 : 12,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
            ],
          ),
          transform: _isHovered
              ? (Matrix4.identity()..translate(0.0, -2.0))
              : Matrix4.identity(),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                'Thử lại',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
