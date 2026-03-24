import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/employee/course_detail/screen/course_detail_web.dart';
import 'package:smet/page/employee/course_detail/screen/course_detail_mobile.dart';
import 'package:smet/page/employee/course_detail/widgets/course_enroll_card.dart';
import 'package:smet/page/employee/course_detail/widgets/course_hero.dart';
import 'package:smet/page/employee/course_detail/widgets/course_instructor.dart';
import 'package:smet/page/employee/course_detail/widgets/course_reviews.dart';
import 'package:smet/page/employee/course_detail/widgets/course_syllabus.dart';
import 'package:smet/service/employee/course_service.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/page/sidebar/sidebar_menu_item.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';

class CourseDetailPage extends StatefulWidget {
  final String courseId;

  const CourseDetailPage({super.key, required this.courseId});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  CourseDetail? _course;
  bool _isLoading = true;
  String? _error;
  bool _isEnrolled = false;
  bool _isEnrolling = false;

  // Track expanded modules
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
      final course = await CourseService.getCourseDetail(widget.courseId);
      final enrolled = await CourseService.isEnrolled(widget.courseId);

      // Initialize expanded state for modules
      for (var i = 0; i < course.modules.length; i++) {
        _expandedModules[i] = course.modules[i].isExpanded;
      }

      setState(() {
        _course = course;
        _isEnrolled = enrolled;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading course detail: $e');
      setState(() {
        _error = 'Không thể tải thông tin khóa học';
        _isLoading = false;
      });
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
      final success = await CourseService.enrollCourse(widget.courseId);
      if (success) {
        setState(() => _isEnrolled = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng ký thành công!'),
              backgroundColor: Color(0xFF22C55E),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng ký thất bại: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isEnrolling = false);
    }
  }

  void _onStartLearning() {
    context.go('/employee/learn/${widget.courseId}');
  }

  void _onNavigateTo(String path) {
    context.go(path);
  }

  void _onLogout() {
    context.go('/login');
  }

  // Menu items for SharedSidebar
  List<SidebarMenuItem> _getMenuItems() {
    return const [
      SidebarMenuItem(
        icon: Icons.dashboard,
        title: 'Trang chủ',
        route: '/employee/dashboard',
        tooltip: 'Trang chủ',
      ),
      SidebarMenuItem(
        icon: Icons.library_books,
        title: 'Khóa học của tôi',
        route: '/employee/my-courses',
        tooltip: 'Khóa học của tôi',
      ),
      SidebarMenuItem(
        icon: Icons.explore,
        title: 'Danh mục',
        route: '/employee/courses',
        tooltip: 'Danh mục khóa học',
      ),
      SidebarMenuItem(
        icon: Icons.work,
        title: 'Dự án của tôi',
        route: '/employee/projects',
        tooltip: 'Dự án của tôi',
      ),
      SidebarMenuItem(
        icon: Icons.workspace_premium,
        title: 'Chứng chỉ',
        route: '/employee/certificates',
        tooltip: 'Chứng chỉ của tôi',
      ),
    ];
  }

  // Build Hero widget
  Widget buildHero() {
    if (_course == null) return const SizedBox.shrink();

    return CourseHero(
      title: _course!.title,
      description: _course!.description,
      imageUrl: _course!.imageUrl,
      duration: _course!.duration,
      level: _course!.level,
      rating: _course!.rating,
      studentsCount: _course!.studentsCount,
      isBestSeller: _course!.isBestSeller,
      category: _course!.category,
    );
  }

  // Build Syllabus widget
  Widget buildSyllabus() {
    if (_course == null) return const SizedBox.shrink();

    final modulesWithState =
        _course!.modules.asMap().entries.map((entry) {
          final index = entry.key;
          final module = entry.value;
          return Module(
            title: module.title,
            lessonCount: module.lessonCount,
            lessons: module.lessons,
            isExpanded: _expandedModules[index] ?? false,
            onToggle: () => _toggleModule(index),
          );
        }).toList();

    return CourseSyllabus(modules: modulesWithState);
  }

  // Build Instructor widget
  Widget buildInstructor() {
    if (_course == null) return const SizedBox.shrink();

    return CourseInstructor(
      name: _course!.instructor.name,
      title: _course!.instructor.title,
      avatarUrl: _course!.instructor.avatarUrl,
      bio: _course!.instructor.bio,
      linkedInUrl: _course!.instructor.linkedInUrl,
      websiteUrl: _course!.instructor.websiteUrl,
    );
  }

  // Build Reviews widget
  Widget buildReviews() {
    if (_course == null) return const SizedBox.shrink();

    return CourseReviews(
      reviews: _course!.reviews,
      onSeeAll: () {
        // TODO: Navigate to all reviews
      },
    );
  }

  // Build Enroll Card widget
  Widget buildEnrollCard() {
    if (_course == null) return const SizedBox.shrink();

    return CourseEnrollCard(
      onEnroll: () {
        if (!_isEnrolling) _onEnroll();
      },
      onStartLearning: _onStartLearning,
      videoHours: _course!.videoHours,
      resources: _course!.resources,
      hasCertificate: _course!.hasCertificate,
      enrolledCount: _course!.enrolledCount,
      isEnrolled: _isEnrolled,
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
                onPressed: _loadCourseDetail,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (kIsWeb || constraints.maxWidth > 850) {
              return CourseDetailWeb(
                hero: buildHero(),
                syllabus: buildSyllabus(),
                instructor: buildInstructor(),
                reviews: buildReviews(),
                enrollCard: buildEnrollCard(),
                menuItems: _getMenuItems(),
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
                  BreadcrumbItem(label: _course?.title ?? 'Chi tiết khóa học'),
                ],
              );
            } else {
              return CourseDetailMobile(
                hero: buildHero(),
                syllabus: buildSyllabus(),
                instructor: buildInstructor(),
                reviews: buildReviews(),
                enrollCard: buildEnrollCard(),
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
