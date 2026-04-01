import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/employee/my_courses/screen/my_courses_web.dart';
import 'package:smet/page/employee/my_courses/screen/my_courses_mobile.dart';
import 'package:smet/page/employee/my_courses/widgets/enrolled_course_card.dart';
import 'package:smet/page/employee/my_courses/widgets/my_courses_stats_section.dart';
import 'package:smet/page/employee/my_courses/widgets/filter_tabs.dart';
import 'package:smet/service/employee/lms_service.dart';
import 'package:smet/service/common/auth_service.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';

class MyCoursesPage extends StatefulWidget {
  const MyCoursesPage({super.key});

  @override
  State<MyCoursesPage> createState() => _MyCoursesPageState();
}

class _MyCoursesPageState extends State<MyCoursesPage> {
  List<EnrolledCourse> _allCourses = [];
  bool _isLoading = true;
  String? _error;
  CourseFilter _selectedFilter = CourseFilter.all;

  // Pagination
  int _currentPage = 0;
  int _totalPages = 1;
  int _totalElements = 0;
  final int _pageSize = 12;
  bool _isPaging = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    await _fetchPage(0, isFullReload: true);
  }

  Future<void> _fetchPage(int page, {required bool isFullReload}) async {
    if (isFullReload) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      if (page < 0 || page >= _totalPages || page == _currentPage) return;
      setState(() => _isPaging = true);
    }

    try {
      final result = await LmsService.getMyCourses(
        page: page,
        size: _pageSize,
      );
      if (!mounted) return;
      final tp = result.totalPages <= 0 ? 1 : result.totalPages;
      final safePage = result.number.clamp(0, tp - 1);
      setState(() {
        _allCourses = result.content;
        _currentPage = safePage;
        _totalPages = tp;
        _totalElements = result.totalElements;
        _isLoading = false;
        _isPaging = false;
        _error = null;
      });
    } catch (e) {
      debugPrint('Error loading my courses: $e');
      if (!mounted) return;
      setState(() {
        if (isFullReload) {
          _error = 'Không thể tải danh sách khóa học';
        }
        _isLoading = false;
        _isPaging = false;
      });
    }
  }

  void _goToPage(int page) {
    if (page < 0 || page >= _totalPages || page == _currentPage) return;
    _fetchPage(page, isFullReload: false);
  }

  Widget _buildPaginationBar() {
    const primary = Color(0xFF137FEC);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: !_isPaging && _currentPage > 0
                ? () => _goToPage(_currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
            color: const Color(0xFF64748B),
          ),
          Opacity(
            opacity: _isPaging ? 0.5 : 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                _totalPages > 5 ? 5 : _totalPages,
                (index) {
                  int pageNum;
                  if (_totalPages > 5) {
                    if (_currentPage < 3) {
                      pageNum = index;
                    } else if (_currentPage > _totalPages - 3) {
                      pageNum = _totalPages - 5 + index;
                    } else {
                      pageNum = _currentPage - 2 + index;
                    }
                  } else {
                    pageNum = index;
                  }
                  final isCurrent = pageNum == _currentPage;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      onTap: _isPaging ? null : () => _goToPage(pageNum),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isCurrent ? primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${pageNum + 1}',
                          style: TextStyle(
                            color: isCurrent ? Colors.white : const Color(0xFF64748B),
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          IconButton(
            onPressed: !_isPaging && _currentPage < _totalPages - 1
                ? () => _goToPage(_currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            color: const Color(0xFF64748B),
          ),
          const SizedBox(width: 12),
          Text(
            'Trang ${_currentPage + 1}/$_totalPages · $_totalElements khóa học',
            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  List<EnrolledCourse> get _filteredCourses {
    switch (_selectedFilter) {
      case CourseFilter.all:
        return _allCourses;
      case CourseFilter.inProgress:
        return _allCourses
            .where((c) => c.status == EnrollmentStatus.inProgress)
            .toList();
      case CourseFilter.completed:
        return _allCourses
            .where((c) => c.status == EnrollmentStatus.completed)
            .toList();
      case CourseFilter.overdue:
        return _allCourses
            .where((c) => c.deadlineStatus == DeadlineStatus.overdue)
            .toList();
    }
  }

  Widget buildContent() {
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

    if (_allCourses.isEmpty) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats
        MyCoursesStatsSection(
          courses: _allCourses,
          totalCountOverride: _totalElements > 0 ? _totalElements : null,
        ),
        const SizedBox(height: 24),

        // Filter tabs
        FilterTabs(
          selected: _selectedFilter,
          onChanged: (filter) {
            setState(() {
              _selectedFilter = filter;
            });
          },
        ),
        const SizedBox(height: 16),

        // Course grid
        if (_filteredCourses.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Không có khóa học nào trong mục này',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: _isPaging ? 0.45 : 1,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 300,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _filteredCourses.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final course = _filteredCourses[index];
                        return EnrolledCourseCard(
                          course: course,
                          onTap: () => context.go('/employee/learn/${course.id}?from=my_courses'),
                        );
                      },
                    ),
                  ),
                  if (_isPaging)
                    const Material(
                      color: Colors.transparent,
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF137FEC),
                        ),
                      ),
                    ),
                ],
              ),
              _buildPaginationBar(),
            ],
          ),
      ],
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
                content: buildContent(),
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
                courses: _filteredCourses,
                allCourses: _allCourses,
                isLoading: _isLoading,
                error: _error,
                selectedFilter: _selectedFilter,
                onFilterChanged: (filter) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                onRetry: _loadCourses,
                onCourseTap: (courseId) => context.go('/employee/learn/$courseId?from=my_courses'),
                onNavigate: (path) => context.go(path),
                onLogout: () async {
                  await AuthService.logout();
                  if (!mounted) return;
                  if (context.mounted) context.go('/login');
                },
                currentPage: _currentPage,
                totalPages: _totalPages,
                totalElements: _totalElements,
                isPaging: _isPaging,
                onPageChanged: _goToPage,
              );
            }
          },
        ),
      ),
    );
  }
}
