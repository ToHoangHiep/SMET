import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/service/mentor/course_service.dart';
import 'package:smet/service/common/auth_service.dart';

/// Mentor Course - Mobile Layout (Danh sách khóa học)
class MentorCourseMobile extends StatefulWidget {
  const MentorCourseMobile({super.key});

  @override
  State<MentorCourseMobile> createState() => _MentorCourseMobileState();
}

class _MentorCourseMobileState extends State<MentorCourseMobile> {
  static const _primary = Color(0xFF6366F1);
  static const _bgLight = Color(0xFFF3F6FC);
  static const _cardBorder = Color(0xFFE8ECF4);
  static const _textDark = Color(0xFF0F172A);
  static const _textMedium = Color(0xFF64748B);

  final MentorCourseService _service = MentorCourseService();

  List<CourseResponse> _courses = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedFilter = 'ALL';
  /// `DEPT_ALL` = mọi khóa trong phòng ban; `MINE` = chỉ khóa của tôi.
  String _listScope = 'DEPT_ALL';

  // Pagination
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  final int _pageSize = 10;
  bool _isLoadingMore = false;

  final _searchController = TextEditingController();

  int? get _currentUserId => AuthService.currentUserCached?.id;

  bool? get _isMineQueryParam => _listScope == 'MINE' ? true : null;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses({int page = 0}) async {
    setState(() {
      if (page == 0) {
        _isLoading = true;
        _error = null;
      }
      _currentPage = page;
    });

    try {
      String? status;
      if (_selectedFilter == 'PUBLISHED') {
        status = 'PUBLISHED';
      } else if (_selectedFilter == 'DRAFT') {
        status = 'DRAFT';
      } else if (_selectedFilter == 'ARCHIVED') {
        status = 'ARCHIVED';
      }

      final result = await _service.listCourses(
        keyword: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: status,
        isMine: _isMineQueryParam,
        page: page,
        size: _pageSize,
      );

      setState(() {
        _courses = result.content;
        _totalPages = result.totalPages;
        _totalElements = result.totalElements;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMoreCourses() async {
    if (_isLoadingMore || _currentPage >= _totalPages - 1) return;

    setState(() => _isLoadingMore = true);

    try {
      String? status;
      if (_selectedFilter == 'PUBLISHED') {
        status = 'PUBLISHED';
      } else if (_selectedFilter == 'DRAFT') {
        status = 'DRAFT';
      } else if (_selectedFilter == 'ARCHIVED') {
        status = 'ARCHIVED';
      }

      final result = await _service.listCourses(
        keyword: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: status,
        isMine: _isMineQueryParam,
        page: _currentPage + 1,
        size: _pageSize,
      );

      setState(() {
        _courses = [..._courses, ...result.content];
        _currentPage = result.number;
        _totalPages = result.totalPages;
        _totalElements = result.totalElements;
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint('Error loading more courses: $e');
      setState(() => _isLoadingMore = false);
    }
  }

  void _onFilterChanged(String filter) {
    setState(() => _selectedFilter = filter);
    _loadCourses(page: 0);
  }

  void _onListScopeChanged(String scope) {
    setState(() => _listScope = scope);
    _loadCourses(page: 0);
  }

  Future<void> _deleteCourse(CourseResponse course) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xóa khóa học"),
        content: Text("Bạn có chắc chắn muốn xóa \"${course.title}\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteCourse(course.id);
        // Reload current page; if empty, go to previous page
        final targetPage = _courses.length == 1 && _currentPage > 0
            ? _currentPage - 1
            : _currentPage;
        _loadCourses(page: targetPage);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Xóa khóa học thành công")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Xóa thất bại: $e")),
          );
        }
      }
    }
  }

  Future<void> _publishCourse(CourseResponse course) async {
    try {
      await _service.publishCourse(course.id);
      _loadCourses(page: _currentPage);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Xuất bản thành công")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Xuất bản thất bại: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          "Quản lý khóa học",
          style: TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: _textDark),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: _primary),
            onPressed: () => context.go('/mentor/courses/create'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: (q) => setState(() {
                  _searchQuery = q;
                  _loadCourses(page: 0);
                }),
                decoration: InputDecoration(
                  hintText: "Tìm kiếm khóa học...",
                  hintStyle: TextStyle(color: _textMedium.withValues(alpha: 0.85)),
                  prefixIcon: Icon(Icons.search, color: _textMedium),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Phạm vi',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              children: [
                _mobileScopeChip('DEPT_ALL', 'Tất cả khóa học'),
                _mobileScopeChip('MINE', 'Khóa của tôi'),
              ],
            ),
          ),
          const SizedBox(height: 6),

          /// FILTER CHIPS (trạng thái)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Trạng thái',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              children: [
                _mobileFilterChip('ALL', 'Tất cả'),
                _mobileFilterChip('PUBLISHED', 'Đã xuất bản'),
                _mobileFilterChip('DRAFT', 'Bản nháp'),
                _mobileFilterChip('ARCHIVED', 'Đã lưu trữ'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          /// CONTENT
          Expanded(child: _buildContent()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/mentor/courses/create'),
        backgroundColor: _primary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _mobileScopeChip(String value, String label) {
    final isSelected = _listScope == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        showCheckmark: true,
        checkmarkColor: _primary,
        onSelected: (_) => _onListScopeChanged(value),
        backgroundColor: Colors.white,
        selectedColor: _primary.withValues(alpha: 0.12),
        labelStyle: TextStyle(
          color: isSelected ? _primary : _textMedium,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
        side: BorderSide(
          color: isSelected ? _primary.withValues(alpha: 0.35) : _cardBorder,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _mobileFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        showCheckmark: true,
        checkmarkColor: _primary,
        onSelected: (_) => _onFilterChanged(value),
        backgroundColor: Colors.white,
        selectedColor: _primary.withValues(alpha: 0.12),
        labelStyle: TextStyle(
          color: isSelected ? _primary : _textMedium,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
        side: BorderSide(
          color: isSelected ? _primary.withValues(alpha: 0.35) : _cardBorder,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: _primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCourses,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Thử lại"),
            ),
          ],
        ),
      );
    }

    if (_courses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _primary.withValues(alpha: 0.08),
                      _primary.withValues(alpha: 0.04),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.menu_book_rounded, size: 36, color: _primary.withValues(alpha: 0.55)),
              ),
              const SizedBox(height: 20),
              Text(
                _searchQuery.isNotEmpty || _selectedFilter != 'ALL'
                    ? "Không tìm thấy khóa học"
                    : "Chưa có khóa học nào",
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty || _selectedFilter != 'ALL'
                    ? "Thử đổi bộ lọc hoặc từ khóa."
                    : "Nhấn + để tạo khóa học đầu tiên.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: _textMedium, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200 &&
            !_isLoadingMore &&
            _currentPage < _totalPages - 1) {
          _loadMoreCourses();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () => _loadCourses(),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: _courses.length + 1,
          itemBuilder: (context, index) {
            if (index == _courses.length) {
              if (_isLoadingMore) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
                    ),
                  ),
                );
              }
              if (_currentPage >= _totalPages - 1) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      '$_totalElements khóa học',
                      style: const TextStyle(fontSize: 12, color: _textMedium),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }
            return _buildCourseCard(_courses[index]);
          },
        ),
      ),
    );
  }

  Widget _buildCourseCard(CourseResponse course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.go(
            '/mentor/courses/${course.id.value}?title=${Uri.encodeComponent(course.title)}',
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER ROW
                Row(
                  children: [
                    _statusBadge(course.status),
                    const SizedBox(width: 6),
                    _ownershipBadge(course),
                    const Spacer(),
                    if (_isOwner(course))
                      PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: _textMedium),
                          onSelected: (value) {
                            if (value == 'edit') {
                              context.go(
                                '/mentor/courses/${course.id.value}?title=${Uri.encodeComponent(course.title)}',
                              );
                            } else if (value == 'publish') {
                              _publishCourse(course);
                            } else if (value == 'delete') {
                              _deleteCourse(course);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 20),
                                  SizedBox(width: 8),
                                  Text("Chỉnh sửa"),
                                ],
                              ),
                            ),
                            if (!course.isPublished)
                              const PopupMenuItem(
                                value: 'publish',
                                child: Row(
                                  children: [
                                    Icon(Icons.publish, size: 20),
                                    SizedBox(width: 8),
                                    Text("Xuất bản"),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text("Xóa", style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                  ],
                ),
                const SizedBox(height: 8),

                /// TITLE
                Text(
                  course.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                /// DESCRIPTION
                Text(
                  course.description.isEmpty ? "Không có mô tả" : course.description,
                  style: TextStyle(fontSize: 13, color: _textMedium),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                /// STATS
                Row(
                  children: [
                    _statChip(Icons.folder_outlined, "${course.moduleCount} chương"),
                    const SizedBox(width: 12),
                    _statChip(Icons.play_lesson_outlined, "${course.lessonCount} bài"),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(CourseStatus status) {
    Color color;
    String label;
    switch (status) {
      case CourseStatus.PUBLISHED:
        color = const Color(0xff4caf50);
        label = 'Đã xuất bản';
        break;
      case CourseStatus.ARCHIVED:
        color = Colors.grey;
        label = 'Đã lưu trữ';
        break;
      default:
        color = Colors.orange;
        label = 'Bản nháp';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  bool _isOwner(CourseResponse course) =>
      _currentUserId != null && course.mentorId.value == _currentUserId;

  Widget _ownershipBadge(CourseResponse course) {
    final isOwner = _isOwner(course);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isOwner
            ? _primary.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOwner ? Icons.person : Icons.people,
            size: 11,
            color: isOwner ? _primary : Colors.grey,
          ),
          const SizedBox(width: 3),
          Text(
            isOwner ? 'Của bạn' : 'Mentor khác',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isOwner ? _primary : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _textMedium),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: _textMedium)),
      ],
    );
  }
}
