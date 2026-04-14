import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/employee/course_catalog/screen/course_catalog_web.dart';
import 'package:smet/page/employee/course_catalog/screen/course_catalog_mobile.dart';
import 'package:smet/page/employee/course_catalog/widgets/course_card.dart';
import 'package:smet/page/employee/course_catalog/widgets/search_filters.dart';
import 'package:smet/page/shared/widgets/app_toast.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/service/employee/course_service.dart';
import 'package:smet/service/employee/lms_service.dart'
    show CatalogCourse, LmsService;
import 'package:smet/service/common/auth_service.dart';

class CourseCatalogPage extends StatefulWidget {
  const CourseCatalogPage({super.key});

  @override
  State<CourseCatalogPage> createState() => _CourseCatalogPageState();
}

class _CourseCatalogPageState extends State<CourseCatalogPage> {
  EnrollmentFilter _selectedEnrollment = EnrollmentFilter.all;
  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;
  Timer? _debounce;

  List<CatalogCourse> _courses = [];

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

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
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
      final result = await CourseService.getCourses(
        keyword: _searchQuery.isNotEmpty ? _searchQuery : null,
        departmentId: null,
        enrollmentStatus: _selectedEnrollment.apiValue,
        page: page,
        size: _pageSize,
      );
      if (!mounted) return;

      // Lấy danh sách khóa đã đăng ký của user để đánh dấu enrolled
      final myCourses = await LmsService.getMyCourses(page: 0, size: 1000);
      final enrolledIds = myCourses.content.map((c) => c.id).toSet();

      // Đánh dấu enrolled = true cho những khóa trùng ID
      for (var course in result.content) {
        course.enrolled = enrolledIds.contains(course.id);
      }

      final tp = result.totalPages <= 0 ? 1 : result.totalPages;
      final safePage = result.number.clamp(0, tp - 1);
      setState(() {
        _courses = result.content;
        _currentPage = safePage;
        _totalPages = tp;
        _totalElements = result.totalElements;
        _isLoading = false;
        _isPaging = false;
        _error = null;
      });
    } catch (e) {
      debugPrint('Error loading courses: $e');
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
            onPressed:
                !_isPaging && _currentPage > 0
                    ? () => _goToPage(_currentPage - 1)
                    : null,
            icon: const Icon(Icons.chevron_left),
            color: const Color(0xFF64748B),
          ),
          Opacity(
            opacity: _isPaging ? 0.5 : 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_totalPages > 5 ? 5 : _totalPages, (
                index,
              ) {
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
                          color:
                              isCurrent
                                  ? Colors.white
                                  : const Color(0xFF64748B),
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          IconButton(
            onPressed:
                !_isPaging && _currentPage < _totalPages - 1
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

  void _onEnrollmentFilterChanged(EnrollmentFilter filter) {
    setState(() {
      _selectedEnrollment = filter;
    });
    _loadCourses();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query;
      });
      _loadCourses();
    });
  }

  String get pageTitle => 'Danh mục khóa học';

  Widget buildSearchFilters() {
    return SearchFilters(
      searchQuery: _searchQuery,
      selectedEnrollment: _selectedEnrollment,
      onSearchChanged: _onSearchChanged,
      onEnrollmentChanged: _onEnrollmentFilterChanged,
    );
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
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 44,
                  color: Color(0xFFEF4444),
                ),
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
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC), // Lighter background
                  borderRadius: BorderRadius.circular(24), // Softer radius
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 44,
                  color: Color(0xFF94A3B8), // Slightly stronger icon
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Không tìm thấy khóa học nào',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hãy thử điều chỉnh tìm kiếm hoặc bộ lọc',
                style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _selectedEnrollment = EnrollmentFilter.all;
                  });
                  _loadCourses();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF137FEC),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Làm mới'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: _isPaging ? 0.45 : 1,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 330,
                  childAspectRatio: 0.82,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 24,
                ),
                itemCount: _courses.length,
                padding: const EdgeInsets.only(top: 16),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final course = _courses[index];
                  return CourseCard(
                    title: course.title,
                    description: course.description,
                    departmentName: course.departmentName,
                    status: course.status,
                    deadlineStatus: course.deadlineStatus,
                    fixedDeadline: course.fixedDeadline,
                    deadlineType: course.deadlineType,
                    defaultDeadlineDays: course.defaultDeadlineDays,
                    isEnrolled: course.enrolled,
                    moduleCount: course.moduleCount,
                    lessonCount: course.lessonCount,
                    mentorName: course.mentorName,
                    onJoin:
                        course.status == 'PUBLISHED' && !course.enrolled
                            ? () => _enrollCourse(course.id)
                            : null,
                    onTap:
                        () => context.go(
                          '/employee/course/${course.id}?from=catalog',
                        ),
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
    );
  }

  Future<void> _enrollCourse(String courseId) async {
    try {
      final success = await CourseService.enrollCourse(courseId);
      if (success && mounted) {
        context.showAppToast('Đăng ký khóa học thành công!');
        _loadCourses();
      }
    } catch (e) {
      debugPrint('Error enrolling course: $e');
      if (mounted) {
        context.showAppToast('Lỗi đăng ký: $e', variant: AppToastVariant.error);
      }
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
                onNavigate: (path) => context.go(path),
                onLogout: () async {
                  await AuthService.logout();
                  if (!mounted) return;
                  if (context.mounted) context.go('/login');
                },
              );
            }
          },
        ),
      ),
    );
  }
}
