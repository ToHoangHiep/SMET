import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/service/admin/department_management/api_department_management.dart';

class DepartmentCoursesTab extends StatefulWidget {
  final int departmentId;
  final Color primaryColor;

  const DepartmentCoursesTab({
    super.key,
    required this.departmentId,
    required this.primaryColor,
  });

  @override
  State<DepartmentCoursesTab> createState() => _DepartmentCoursesTabState();
}

class _DepartmentCoursesTabState extends State<DepartmentCoursesTab> {
  final DepartmentService _service = DepartmentService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;

  String _searchQuery = '';
  String? _selectedLevel;
  int _currentPage = 0;
  int _totalPages = 1;
  int _totalElements = 0;
  static const int _pageSize = 10;

  String _sortColumn = 'title';
  bool _sortAscending = true;

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

  Future<void> _loadCourses({bool loadMore = false}) async {
    if (loadMore) {
      if (_isLoadingMore || _currentPage >= _totalPages - 1) return;
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentPage = 0;
      });
    }

    try {
      final result = await _service.getDepartmentCourses(
        departmentId: widget.departmentId,
        keyword: _searchQuery.isEmpty ? null : _searchQuery,
        level: _selectedLevel,
        page: loadMore ? _currentPage + 1 : 0,
        size: _pageSize,
      );

      final courses = result['courses'] as List<dynamic>? ?? [];
      final totalPages = result['totalPages'] as int? ?? 1;
      final totalElements = result['totalElements'] as int? ?? 0;

      if (mounted) {
        setState(() {
          if (loadMore) {
            _courses.addAll(courses.cast<Map<String, dynamic>>());
            _isLoadingMore = false;
          } else {
            _courses = courses.cast<Map<String, dynamic>>();
            _isLoading = false;
          }
          _currentPage = loadMore ? _currentPage + 1 : 0;
          _totalPages = totalPages;
          _totalElements = totalElements;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Không thể tải danh sách khóa học';
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onSearch(String value) {
    setState(() => _searchQuery = value);
    _loadCourses();
  }

  void _onLevelFilterChanged(String? level) {
    setState(() => _selectedLevel = level);
    _loadCourses();
  }

  void _sortData(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
  }

  List<Map<String, dynamic>> _getSortedCourses() {
    final sorted = List<Map<String, dynamic>>.from(_courses);
    sorted.sort((a, b) {
      int compare;
      switch (_sortColumn) {
        case 'title':
          final titleA = a['title'] ?? a['name'] ?? '';
          final titleB = b['title'] ?? b['name'] ?? '';
          compare = titleA.toString().compareTo(titleB.toString());
          break;
        case 'enrolled':
          final enrolledA = _parseIntValue(a['enrolledCount'] ?? a['studentCount'] ?? a['enrolled'] ?? 0);
          final enrolledB = _parseIntValue(b['enrolledCount'] ?? b['studentCount'] ?? b['enrolled'] ?? 0);
          compare = enrolledA.compareTo(enrolledB);
          break;
        default:
          compare = 0;
      }
      return _sortAscending ? compare : -compare;
    });
    return sorted;
  }

  int _parseIntValue(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? 0;
    }
    if (value is Map || value is List) return 0;
    try {
      return int.parse(value.toString());
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoading();
    }

    if (_error != null) {
      return _buildError();
    }

    return _buildCourseLayout();
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Align(
        alignment: Alignment.centerLeft,
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: Colors.red[600])),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _loadCourses(),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryRow(),
        const SizedBox(height: 16),
        _buildSearchAndFilter(),
        const SizedBox(height: 16),
        Expanded(
          child: _courses.isEmpty ? _buildEmpty() : _buildCourseList(),
        ),
        if (_courses.isNotEmpty) _buildPagination(),
      ],
    );
  }

  Widget _buildSummaryRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: widget.primaryColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.school_outlined, size: 18, color: widget.primaryColor),
          const SizedBox(width: 8),
          Text('Tổng cộng: ', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Text(
            '$_totalElements khóa học',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: widget.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        SizedBox(
          width: 300,
          child: TextField(
            controller: _searchController,
            onChanged: _onSearch,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm khóa học...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded, color: Colors.grey[400], size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _onSearch('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: widget.primaryColor, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _selectedLevel,
              hint: Text('Tất cả cấp độ', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('Tất cả cấp độ')),
                const DropdownMenuItem<String?>(value: 'BEGINNER', child: Text('Cơ bản')),
                const DropdownMenuItem<String?>(value: 'INTERMEDIATE', child: Text('Trung bình')),
                const DropdownMenuItem<String?>(value: 'ADVANCED', child: Text('Nâng cao')),
              ],
              onChanged: _onLevelFilterChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy khóa học',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedLevel != null
                ? 'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm'
                : 'Phòng ban này chưa được gán khóa học nào.',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseList() {
    final sortedCourses = _getSortedCourses();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Expanded(
            child: ListView.separated(
              itemCount: sortedCourses.length + (_isLoadingMore ? 1 : 0),
              separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE5E7EB)),
              itemBuilder: (context, index) {
                if (index >= sortedCourses.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final course = sortedCourses[index];
                return _CourseListItem(
                  course: course,
                  index: index,
                  primaryColor: widget.primaryColor,
                  onTap: () {
                    final courseId = course['id']?.toString();
                    if (courseId != null) {
                      context.go('/admin/course/$courseId');
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          _buildHeaderCell('STT', 'index', width: 60),
          _buildHeaderCell('Tên khóa học', 'title', flex: 4),
          _buildHeaderCell('Người đăng ký', 'enrolled', width: 140),
          _buildHeaderCell('Thao tác', 'actions', width: 100),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label, String column, {double? width, int flex = 1}) {
    final isActive = _sortColumn == column;

    return width != null
        ? SizedBox(
            width: width,
            child: InkWell(
              onTap: () => _sortData(column),
              child: Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive ? widget.primaryColor : const Color(0xFF64748B),
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 4),
                    Icon(
                      _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 14,
                      color: widget.primaryColor,
                    ),
                  ],
                ],
              ),
            ),
          )
        : Expanded(
            flex: flex,
            child: InkWell(
              onTap: () => _sortData(column),
              child: Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive ? widget.primaryColor : const Color(0xFF64748B),
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 4),
                    Icon(
                      _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 14,
                      color: widget.primaryColor,
                    ),
                  ],
                ],
              ),
            ),
          );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 0 ? () => _loadCourses() : null,
            icon: const Icon(Icons.chevron_left),
            color: widget.primaryColor,
            disabledColor: Colors.grey[300],
          ),
          const SizedBox(width: 8),
          Text(
            'Trang ${_currentPage + 1} / $_totalPages',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(width: 8),
          if (_isLoadingMore)
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
          else
            IconButton(
              onPressed: _currentPage < _totalPages - 1 ? () => _loadCourses(loadMore: true) : null,
              icon: const Icon(Icons.chevron_right),
              color: widget.primaryColor,
              disabledColor: Colors.grey[300],
            ),
        ],
      ),
    );
  }
}

class _CourseListItem extends StatefulWidget {
  final Map<String, dynamic> course;
  final int index;
  final Color primaryColor;
  final VoidCallback onTap;

  const _CourseListItem({
    required this.course,
    required this.index,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  State<_CourseListItem> createState() => _CourseListItemState();
}

class _CourseListItemState extends State<_CourseListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final title = widget.course['title'] ?? widget.course['name'] ?? 'Khóa học';
    final description = widget.course['description'] ?? '';
    final imageUrl = widget.course['imageUrl'] ?? widget.course['thumbnail'];
    final enrolledCount = _parseIntValue(
        widget.course['enrolledCount'] ??
        widget.course['studentCount'] ??
        widget.course['enrolled'] ??
        0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: _isHovered ? widget.primaryColor.withValues(alpha: 0.04) : Colors.transparent,
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  '${widget.index + 1}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ),
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.primaryColor.withValues(alpha: 0.15),
                            widget.primaryColor.withValues(alpha: 0.05),
                          ],
                        ),
                        image: imageUrl != null
                            ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                            : null,
                      ),
                      child: imageUrl == null
                          ? Icon(Icons.school, size: 22, color: widget.primaryColor.withValues(alpha: 0.6))
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 140,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 6),
                    Text(
                      enrolledCount > 0 ? '$enrolledCount' : '-',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 100,
                child: IconButton(
                  onPressed: widget.onTap,
                  icon: Icon(Icons.visibility_outlined, size: 20, color: widget.primaryColor),
                  tooltip: 'Xem chi tiết',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _parseIntValue(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? 0;
    }
    if (value is Map || value is List) return 0;
    try {
      return int.parse(value.toString());
    } catch (_) {
      return 0;
    }
  }
}
