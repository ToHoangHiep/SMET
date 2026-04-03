import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/service/mentor/course_service.dart';
import 'package:smet/service/common/auth_service.dart';

/// Mentor Course - Web Layout (Danh sách khóa học)
class MentorCourseWeb extends StatefulWidget {
  const MentorCourseWeb({super.key});

  @override
  State<MentorCourseWeb> createState() => _MentorCourseWebState();
}

class _MentorCourseWebState extends State<MentorCourseWeb> {
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
  /// `DEPT_ALL` = mọi khóa trong phòng ban (`isMine: null`); `MINE` = chỉ khóa của tôi (`isMine: true`).
  String _listScope = 'DEPT_ALL';

  // Pagination
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  final int _pageSize = 9;

  final _searchController = TextEditingController();

  int? get _currentUserId => AuthService.currentUserCached?.id;

  bool? get _isMineQueryParam => _listScope == 'MINE' ? true : null;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uri = GoRouterState.of(context).uri;
      if (uri.queryParameters.containsKey('refresh')) {
        _loadCourses(page: _currentPage);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses({int page = 0}) async {
    setState(() {
      _isLoading = true;
      _error = null;
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
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onFilterChanged(String filter) {
    setState(() => _selectedFilter = filter);
    _loadCourses();
  }

  void _onListScopeChanged(String scope) {
    setState(() => _listScope = scope);
    _loadCourses();
  }

  void _onSearch(String query) {
    _searchQuery = query;
    _loadCourses();
  }

  void _goToPage(int page) {
    if (page >= 0 && page < _totalPages) {
      _loadCourses(page: page);
    }
  }

  Future<void> _deleteCourse(CourseResponse course) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xóa khóa học"),
        content: Text("Bạn có chắc chắn muốn xóa khóa học \"${course.title}\" không?"),
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
        _loadCourses(page: _currentPage);
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

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    int crossAxisCount = 3;
    if (width > 1600) {
      crossAxisCount = 4;
    } else if (width < 1200) {
      crossAxisCount = 2;
    }

    return Scaffold(
      backgroundColor: _bgLight,
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(30, 30, 30, 0),
            child: BreadcrumbPageHeader(
              pageTitle: "Quản lý khóa học",
              pageIcon: Icons.menu_book_rounded,
              breadcrumbs: const [
                BreadcrumbItem(label: "Mentor", route: "/mentor/dashboard"),
                BreadcrumbItem(label: "Khóa học"),
              ],
              primaryColor: _primary,
              actions: [
                ElevatedButton.icon(
                  onPressed: () => context.go('/mentor/courses/create'),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text("Tạo khóa học mới"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Phạm vi",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _textDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            _scopeChip("DEPT_ALL", "Tất cả khóa học"),
                            _scopeChip("MINE", "Khóa của tôi"),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Divider(height: 1, color: _cardBorder),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            SizedBox(
                              width: 320,
                              child: TextField(
                                controller: _searchController,
                                onSubmitted: _onSearch,
                                decoration: InputDecoration(
                                  hintText: "Tìm kiếm khóa học...",
                                  hintStyle: TextStyle(color: _textMedium.withValues(alpha: 0.8)),
                                  prefixIcon: Icon(Icons.search, color: _textMedium, size: 22),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: _cardBorder),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: _cardBorder),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: _primary, width: 1.5),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            _filterChip("ALL"),
                            _filterChip("PUBLISHED"),
                            _filterChip("DRAFT"),
                            _filterChip("ARCHIVED"),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  /// COURSE GRID
                  Expanded(child: _buildContent(crossAxisCount)),
                  const SizedBox(height: 10),

                  /// PAGINATION
                  if (!_isLoading)
                    _buildPagination(),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _scopeChip(String value, String title) {
    final selected = _listScope == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(title),
        selected: selected,
        showCheckmark: true,
        checkmarkColor: _primary,
        selectedColor: _primary.withValues(alpha: 0.12),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: selected ? _primary.withValues(alpha: 0.35) : _cardBorder,
        ),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? _primary : _textMedium,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        onSelected: (v) {
          if (v) _onListScopeChanged(value);
        },
      ),
    );
  }

  Widget _filterChip(String label) {
    final selected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(_filterLabel(label)),
        selected: selected,
        showCheckmark: true,
        checkmarkColor: _primary,
        selectedColor: _primary.withValues(alpha: 0.12),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: selected ? _primary.withValues(alpha: 0.35) : _cardBorder,
        ),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? _primary : _textMedium,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        onSelected: (value) {
          if (value) _onFilterChanged(label);
        },
      ),
    );
  }

  String _filterLabel(String label) {
    switch (label) {
      case 'ALL': return 'Tất cả';
      case 'PUBLISHED': return 'Đã xuất bản';
      case 'DRAFT': return 'Bản nháp';
      case 'ARCHIVED': return 'Đã lưu trữ';
      default: return label;
    }
  }

  Widget _buildContent(int crossAxisCount) {
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
              onPressed: () => _loadCourses(),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
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
              child: Icon(Icons.menu_book_rounded, size: 40, color: _primary.withValues(alpha: 0.55)),
            ),
            const SizedBox(height: 20),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'ALL'
                  ? "Không tìm thấy khóa học phù hợp"
                  : "Chưa có khóa học nào",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textDark),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'ALL'
                  ? "Thử đổi bộ lọc hoặc từ khóa tìm kiếm."
                  : "Tạo khóa học đầu tiên để bắt đầu.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: _textMedium, height: 1.4),
            ),
            if (_searchQuery.isEmpty && _selectedFilter == 'ALL') ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/mentor/courses/create'),
                icon: const Icon(Icons.add, size: 20),
                label: const Text("Tạo khóa học đầu tiên"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.35,
      ),
      itemCount: _courses.length,
      itemBuilder: (context, index) => _buildCourseCard(_courses[index]),
    );
  }

  Widget _buildCourseCard(CourseResponse course) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
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
                                  Icon(Icons.edit_outlined, size: 18),
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
                                    Icon(Icons.publish, size: 18),
                                    SizedBox(width: 8),
                                    Text("Xuất bản"),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 18, color: Colors.red),
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
                    fontSize: 15,
                    color: _textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                /// DESCRIPTION
                Expanded(
                  child: Text(
                    course.description.isEmpty
                        ? "Không có mô tả"
                        : course.description,
                    style: TextStyle(fontSize: 12, color: _textMedium),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 10),

                /// STATS
                Row(
                  children: [
                    _statIcon(Icons.folder_outlined, "${course.moduleCount} chương"),
                    const SizedBox(width: 12),
                    _statIcon(Icons.play_lesson_outlined, "${course.lessonCount} bài"),
                  ],
                ),
              ],
            ),
          ),
        ),
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
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _statIcon(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _textMedium),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: _textMedium),
        ),
      ],
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
          icon: const Icon(Icons.chevron_left),
          color: _textMedium,
        ),
        const SizedBox(width: 8),
        ...List.generate(
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
                onTap: () => _goToPage(pageNum),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isCurrent ? _primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "${pageNum + 1}",
                    style: TextStyle(
                      color: isCurrent ? Colors.white : _textMedium,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _currentPage < _totalPages - 1 ? () => _goToPage(_currentPage + 1) : null,
          icon: const Icon(Icons.chevron_right),
          color: _textMedium,
        ),
        const SizedBox(width: 16),
        Text(
          "$_totalElements khóa học",
          style: const TextStyle(fontSize: 12, color: _textMedium),
        ),
      ],
    );
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
}
