import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/employee/my_courses/screen/my_courses_web.dart';
import 'package:smet/page/employee/my_courses/screen/my_courses_mobile.dart';
import 'package:smet/page/employee/my_courses/widgets/enrolled_course_card.dart';
import 'package:smet/service/employee/lms_service.dart';
import 'package:smet/page/sidebar/sidebar_menu_item.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';

class MyCoursesPage extends StatefulWidget {
  const MyCoursesPage({super.key});

  @override
  State<MyCoursesPage> createState() => _MyCoursesPageState();
}

class _MyCoursesPageState extends State<MyCoursesPage> {
  List<EnrolledCourse> _courses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final courses = await LmsService.getMyCourses();
      setState(() {
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading my courses: $e');
      setState(() {
        _error = 'Không thể tải danh sách khóa học';
        _isLoading = false;
      });
    }
  }

  void _onNavigateTo(String path) {
    context.go(path);
  }

  void _onLogout() {
    context.go('/login');
  }

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

  Widget buildCourseGrid() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(color: Color(0xFF137FEC)),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
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
                onPressed: _loadCourses,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF137FEC),
                ),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_courses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.school_outlined,
                size: 64,
                color: Color(0xFFE5E7EB),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chưa có khóa học nào',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hãy đăng ký khóa học để bắt đầu học tập',
                style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/employee/courses'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF137FEC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.explore),
                label: const Text('Khám phá khóa học'),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        childAspectRatio: 0.72,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _courses.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final course = _courses[index];
        return EnrolledCourseCard(
          course: course,
          onTap: () => context.go('/employee/learn/${course.id}'),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (kIsWeb || constraints.maxWidth > 850) {
              return MyCoursesWeb(
                pageTitle: 'Khóa học của tôi',
                courseGrid: buildCourseGrid(),
                menuItems: _getMenuItems(),
                onNavigate: _onNavigateTo,
                onLogout: _onLogout,
                breadcrumbs: const [
                  BreadcrumbItem(
                    label: 'Trang chủ',
                    route: '/employee/dashboard',
                  ),
                  BreadcrumbItem(label: 'Khóa học của tôi'),
                ],
              );
            } else {
              return MyCoursesMobile(
                courses: _courses,
                isLoading: _isLoading,
                error: _error,
                onRetry: _loadCourses,
                onCourseTap:
                    (courseId) => context.go('/employee/learn/$courseId'),
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
