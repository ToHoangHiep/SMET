import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/employee/course_catalog/screen/course_catalog_web.dart';
import 'package:smet/page/employee/course_catalog/screen/course_catalog_mobile.dart';
import 'package:smet/page/employee/course_catalog/widgets/course_card.dart';
import 'package:smet/page/employee/course_catalog/widgets/search_filters.dart';
import 'package:smet/page/sidebar/sidebar_menu_item.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';

class CourseCatalogPage extends StatefulWidget {
  const CourseCatalogPage({super.key});

  @override
  State<CourseCatalogPage> createState() => _CourseCatalogPageState();
}

class _CourseCatalogPageState extends State<CourseCatalogPage> {
  String _selectedCategory = 'all';
  String _searchQuery = '';

  // Courses data - sẽ được load từ API sau
  List<Map<String, dynamic>> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  // Placeholder methods - sẽ gọi API thật sau
  Future<void> _loadCourses() async {
    try {
      // TODO: Gọi API lấy danh sách khóa học
      // final data = await CourseService.getCourses(
      //   category: _selectedCategory,
      //   search: _searchQuery,
      // );
      // setState(() {
      //   _courses = data;
      // });
      setState(() {
        _courses = [];
      });
    } catch (e) {
      debugPrint('Error loading courses: $e');
    }
  }

  void _onCategoryChanged(CourseCategory category) {
    setState(() {
      _selectedCategory = category.name;
    });
    _loadCourses();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _loadCourses();
  }

  String get pageTitle => 'Danh mục khóa học';

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

  // Search filters widget
  Widget buildSearchFilters() {
    return SearchFilters(
      selectedCategory: _selectedCategory,
      searchQuery: _searchQuery,
      onCategoryChanged: _onCategoryChanged,
      onSearchChanged: _onSearchChanged,
    );
  }

  // Course grid widget
  Widget buildCourseGrid() {
    if (_courses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school_outlined, size: 64, color: Color(0xFFE5E7EB)),
              SizedBox(height: 16),
              Text(
                'Không tìm thấy khóa học nào',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Hãy thử điều chỉnh tìm kiếm hoặc bộ lọc',
                style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _courses.length,
      padding: const EdgeInsets.only(top: 24),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final course = _courses[index];
        final courseId = course['id'] ?? '1';
        return CourseCard(
          title: course['title'] ?? '',
          imageUrl: course['imageUrl'],
          category: _parseCategory(course['category']),
          rating: (course['rating'] ?? 0).toDouble(),
          duration: course['duration'] ?? '',
          onJoin: () {},
          onTap: () => context.go('/employee/course/$courseId'),
        );
      },
    );
  }

  CourseCategory _parseCategory(String? category) {
    switch (category) {
      case 'technical':
        return CourseCategory.technical;
      case 'softSkills':
        return CourseCategory.softSkills;
      case 'leadership':
        return CourseCategory.leadership;
      default:
        return CourseCategory.all;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (kIsWeb || constraints.maxWidth > 850) {
              return CourseCatalogWeb(
                pageTitle: pageTitle,
                searchFilters: buildSearchFilters(),
                courseGrid: buildCourseGrid(),
                menuItems: _getMenuItems(),
                onNavigate: _onNavigateTo,
                onLogout: _onLogout,
                breadcrumbs: const [
                  BreadcrumbItem(
                    label: 'Trang chủ',
                    route: '/employee/dashboard',
                  ),
                  BreadcrumbItem(label: 'Danh mục khóa học'),
                ],
              );
            } else {
              return CourseCatalogMobile(
                pageTitle: pageTitle,
                searchFilters: buildSearchFilters(),
                courseGrid: buildCourseGrid(),
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
