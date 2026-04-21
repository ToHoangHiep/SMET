import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/employee/course_detail/screen/course_detail_web.dart';
import 'package:smet/page/employee/course_detail/screen/course_detail_mobile.dart';
import 'package:smet/page/chat/widgets/floating_chat_button.dart';
import 'package:smet/model/Employee_course_model.dart';
import 'package:smet/model/user_model.dart';
import 'package:smet/model/chat/chat_models.dart';
import 'package:smet/page/shared/widgets/app_toast.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/service/common/auth_service.dart';
import 'package:smet/service/employee/course_service.dart';
import 'package:smet/service/chat/chat_service.dart';

class CourseDetailPage extends StatefulWidget {
  final String courseId;
  final String? from;

  const CourseDetailPage({super.key, required this.courseId, this.from});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  CourseDetail? _course;
  bool _isLoading = true;
  String? _error;
  bool _isEnrolling = false;
  bool _isLeaving = false;
  bool _isPreviewMode = false;
  final Map<int, bool> _expandedModules = {};

  @override
  void initState() {
    super.initState();
    _loadCourseDetail();
  }

  Future<void> _loadCourseDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      try {
        final user = await AuthService.getCurrentUser();
        debugPrint('>>> [DEBUG] _loadCourseDetail — frontend user: id=${user.id}, email=${user.email}, role=${user.role}');
        _isPreviewMode = user.role != UserRole.USER;
      } catch (_) {
        _isPreviewMode = false;
      }

      final course = await CourseService.getCourseDetail(widget.courseId);

      debugPrint('>>> [DEBUG] _loadCourseDetail — course loaded: id=${widget.courseId}, '
          'enrolled=${course.enrolled}, enrollmentStatus=${course.enrollmentStatus}, progress=${course.progress}');

      for (var i = 0; i < course.modules.length; i++) {
        _expandedModules[i] = false;
      }

      if (mounted) {
        setState(() {
          _course = course;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading course detail: $e');
      if (mounted) {
        setState(() {
          _error = 'Không thể tải thông tin khóa học';
          _isLoading = false;
        });
      }
    }
  }

  void _toggleModule(int index) {
    setState(() {
      _expandedModules[index] = !(_expandedModules[index] ?? false);
    });
  }

  Future<void> _onEnroll() async {
    setState(() => _isEnrolling = true);
    try {
      debugPrint('>>> [DEBUG] _onEnroll — courseId=${widget.courseId}');
      final success = await CourseService.enrollCourse(widget.courseId);
      debugPrint('>>> [DEBUG] _onEnroll — result=$success');
      if (success) {
        if (mounted) {
          context.showAppToast('Đăng ký thành công!');
          await _loadCourseDetail();
        }
      }
    } catch (e) {
      if (mounted) {
        context.showAppToast('Đăng ký thất bại: $e', variant: AppToastVariant.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isEnrolling = false);
      }
    }
  }

  Future<void> _onLeaveCourse() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFF59E0B),
                  size: 28,
                ),
                SizedBox(width: 12),
                Expanded(child: Text('Xác nhận rời khóa học')),
              ],
            ),
            content: Text(
              'Bạn có chắc chắn muốn rời khóa học "${_course?.title}" không?\n'
              'Tiến độ học tập của bạn sẽ bị mất.',
              style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                ),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Rời khóa học'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() => _isLeaving = true);
    try {
      final success = await CourseService.leaveCourse(widget.courseId);
      if (success) {
        await Future.delayed(const Duration(milliseconds: 200));
        await _loadCourseDetail();
        if (mounted) {
          context.showAppToast('Đã rời khóa học thành công!');
        }
      }
    } catch (e) {
      if (mounted) {
        context.showAppToast('Không thể rời khóa học: $e', variant: AppToastVariant.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLeaving = false);
      }
    }
  }

  void _onStartLearning() {
    context.go('/employee/learn/${widget.courseId}?from=course_detail');
  }

  void _onNavigateTo(String path) {
    context.go(path);
  }

  void _handleLogout() async {
    await AuthService.logout();
    if (!mounted) return;
    context.go('/login');
  }

  BreadcrumbItem _buildBreadcrumbParent() {
    switch (widget.from) {
      case 'my_courses':
        return const BreadcrumbItem(label: 'Khóa học của tôi', route: '/employee/my-courses');
      case 'dashboard':
        return const BreadcrumbItem(label: 'Trang chủ', route: '/employee/dashboard');
      case 'search':
        return const BreadcrumbItem(label: 'Tìm kiếm', route: '/employee/search');
      case 'learning_path':
        return const BreadcrumbItem(label: 'Lộ trình học tập', route: '/employee/my-learning-paths');
      default:
        return const BreadcrumbItem(label: 'Danh mục khóa học', route: '/employee/courses');
    }
  }

  void _onShare() {
    if (mounted) {
      context.showAppToast('Đã sao chép liên kết khóa học!');
    }
  }

  void _onBookmark() {
    if (mounted) {
      context.showAppToast('Đã lưu khóa học!');
    }
  }

  Future<void> _onChatWithMentor() async {
    if (_course == null || _course!.mentorId <= 0) {
      if (mounted) {
        context.showAppToast('Không có mentor cho khóa học này');
      }
      return;
    }

    try {
      final courseIdInt = int.tryParse(widget.courseId) ?? 0;
      final roomId = await ChatService.createOrGetRoom(
        mentorId: _course!.mentorId,
        contextType: ChatContextType.COURSE,
        contextId: courseIdInt,
      );
      floatingChatKey.currentState?.openChatWithRoom(roomId);
    } catch (e) {
      debugPrint('Error opening chat with mentor: $e');
      if (mounted) {
        context.showAppToast('Không thể mở chat với mentor', variant: AppToastVariant.error);
      }
    }
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
              const Icon(Icons.error_outline, size: 64, color: Color(0xFFEF4444)),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(fontSize: 16, color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadCourseDetail, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      body: SafeArea(
        child: Column(
          children: [
            if (_isPreviewMode)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.amber.shade100,
                child: Row(
                  children: [
                    Icon(Icons.visibility, color: Colors.amber.shade800, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Chế độ xem trước — Bạn đang xem với tư cách admin/mentor',
                        style: TextStyle(
                          color: Colors.amber.shade800,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/user_management'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text('Quay về', style: TextStyle(color: Colors.amber.shade900, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (kIsWeb || constraints.maxWidth > 850) {
                  return CourseDetailWeb(
                    course: _course!,
                    expandedModules: _expandedModules,
                    onToggleModule: _toggleModule,
                    isEnrolling: _isEnrolling || _isLeaving,
                    isPreviewMode: _isPreviewMode,
                    onEnroll: _onEnroll,
                    onLeaveCourse: _onLeaveCourse,
                    onStartLearning: _onStartLearning,
                    onShare: _onShare,
                    onBookmark: _onBookmark,
                    onChatWithMentor: _onChatWithMentor,
                    breadcrumbs: [
                      const BreadcrumbItem(label: 'Trang chủ', route: '/employee/dashboard'),
                      _buildBreadcrumbParent(),
                      BreadcrumbItem(label: _course?.title ?? 'Chi tiết khóa học'),
                    ],
                  );
                  } else {
                  return CourseDetailMobile(
                    course: _course!,
                    expandedModules: _expandedModules,
                    onToggleModule: _toggleModule,
                    isEnrolling: _isEnrolling || _isLeaving,
                    isPreviewMode: _isPreviewMode,
                    onEnroll: _onEnroll,
                    onLeaveCourse: _onLeaveCourse,
                    onStartLearning: _onStartLearning,
                    onNavigate: _onNavigateTo,
                    onLogout: _handleLogout,
                    onChatWithMentor: _onChatWithMentor,
                  );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
