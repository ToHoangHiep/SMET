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
import 'package:smet/page/chat/widgets/floating_chat_button.dart';
import 'package:smet/service/employee/lms_service.dart';
import 'package:smet/service/common/auth_service.dart';
import 'package:smet/service/employee/course_service.dart';
import 'package:smet/service/chat/chat_service.dart';
import 'package:smet/model/chat/chat_models.dart';
import 'package:smet/page/shared/widgets/app_toast.dart';
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

class _LearningWorkspacePageState extends State<LearningWorkspacePage> {
  LearningCourse? _course;
  LessonContent? _lessonContent;
  String? _currentQuizId;
  LessonTab _selectedTab = LessonTab.discussion;
  bool _isLoading = true;
  String? _error;
  LearningPathDetail? _learningPath;
  int _discussionCount = 0;
  // Quiz mode — khi xem thông tin quiz (chưa vào làm bài)
  bool _isQuizMode = false;

  @override
  void initState() {
    super.initState();
    _loadData();
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
    setState(() {
      _isLoading = true;
      _error = null;
      _currentQuizId = widget.quizId;
    });

    try {
      final course = await LmsService.getCourseProgress(
        widget.courseId,
        'user_1',
      );

      // Fetch Learning Path detail if path ID is provided
      LearningPathDetail? pathDetail;
      if (widget.learningPathId != null) {
        pathDetail = await LmsService.getLearningPathDetail(widget.learningPathId!);
      }

      // QUIZ MODE: có quizId → không load lesson, hiển thị quiz info ngay trong workspace
      if (widget.quizId != null) {
        setState(() {
          _course = course;
          _lessonContent = null;
          _learningPath = pathDetail;
          _isQuizMode = true;
          _isLoading = false;
        });
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

        // Fetch discussion count for the badge
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

      setState(() {
        _course = course;
        _lessonContent = lessonContent;
        _learningPath = pathDetail;
        _discussionCount = fetchedCount;
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
        context.showAppToast('Đã đánh dấu hoàn thành!');
      }
      // Reload course to update sidebar progress
      await _loadCourseOnly();
    } catch (e) {
      debugPrint('Error marking complete: $e');
    }
  }

  Future<void> _loadCourseOnly() async {
    try {
      final course = await LmsService.getCourseProgress(
        widget.courseId,
        'user_1',
      );
      // Reload Learning Path detail if available
      LearningPathDetail? pathDetail;
      if (widget.learningPathId != null) {
        pathDetail = await LmsService.getLearningPathDetail(widget.learningPathId!);
      }
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

  /// Điều hướng tới bài học, giữ ngữ cảnh breadcrumb (danh mục / khóa của tôi / lộ trình).
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
    // Chuyển đến learning workspace với quizId để hiển thị quiz ngay trong workspace
    // giống như lesson - không chuyển sang trang quiz riêng
    context.go('/employee/learn/${widget.courseId}?quizId=$quizId');
  }

  void _onQuizTap(String quizId) {
    // Chuyển đến learning workspace với quizId để hiển thị quiz ngay trong workspace
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
  // Build content area: video player (VIDEO) hoặc text content (TEXT/LINK) hoặc quiz
  Widget buildContentArea() {
    // QUIZ MODE: hiển thị quiz ngay trong workspace như lesson
    if (_isQuizMode && widget.quizId != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: QuizLessonView(
          quizId: widget.quizId!,
          courseId: widget.courseId,
          // isFinalQuiz sẽ được xác định từ API trong QuizLessonView
          // Không truyền prop này để tránh xung đột
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
          _onMarkComplete();
        },
      );
    }

    // TEXT or LINK — hiển thị nội dung dạng văn bản
    final textContent = _lessonContent!.content ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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

  // Build lesson header widget
  Widget buildLessonHeader() {
    if (_lessonContent == null && !_isQuizMode) return const SizedBox.shrink();

    if (_isQuizMode && widget.quizId != null) {
      return QuizLessonHeader(
        title: 'Bài kiểm tra',
        isFinalQuiz: _isFinalQuiz(),
      );
    }

    return LessonHeader(
      title: _lessonContent!.title,
      durationMinutes: _lessonContent!.videoDurationSeconds ~/ 60,
      level: _lessonContent!.level,
      lessonId: _lessonContent!.id,
      isCompleted: _lessonContent!.isCompleted,
      onMarkComplete: _onMarkComplete,
    );
  }

  bool _isFinalQuiz() {
    if (_course == null || widget.quizId == null) return false;
    // So sánh cả hai dưới dạng String để tránh type mismatch (int vs String)
    return _course!.finalQuizId?.toString() == widget.quizId.toString();
  }

  // Build tabs widget
  Widget buildTabs() {
    // Quiz mode - không có tabs
    if (_isQuizMode && widget.quizId != null) {
      return const SizedBox.shrink();
    }

    return LessonTabs(
      selectedTab: _selectedTab,
      onTabChanged: _onTabChanged,
      discussionCount: _discussionCount,
    );
  }

  // Build tab content widget
  Widget buildTabContent() {
    // Quiz mode - không có tab
    if (_isQuizMode && widget.quizId != null) {
      return const SizedBox.shrink();
    }

    if (_lessonContent == null) return const SizedBox.shrink();

    switch (_selectedTab) {
      case LessonTab.discussion:
        return DiscussionTab(
          lessonId: _lessonContent!.id,
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

  // Build sidebar navigation widget (danh sách module / bài học — UI mock)
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
                          label:
                              _course!.title.trim().isEmpty
                                  ? 'Khóa học'
                                  : _course!.title.trim(),
                          route: '/employee/course/${_course!.id}',
                        ),
                      BreadcrumbItem(
                        label:
                            (_isQuizMode && widget.quizId != null)
                                ? 'Bài kiểm tra'
                                : ((_lessonContent?.title ?? '').trim().isEmpty
                                    ? 'Bài học'
                                    : _lessonContent!.title.trim()),
                      ),
                    ],
                    isQuizMode: _isQuizMode,
                  ),
                  Positioned(
                    right: 20,
                    bottom: 20,
                    child: FloatingChatButton(
                      primaryColor: const Color(0xFF137FEC),
                      rolePrefix: 'employee',
                    ),
                  ),
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
                  ),
                  Positioned(
                    right: 20,
                    bottom: 20,
                    child: FloatingChatButton(
                      primaryColor: const Color(0xFF137FEC),
                      rolePrefix: 'employee',
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
