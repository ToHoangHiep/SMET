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
  static const int _pageSize = 9;

  final List<String> _levelOptions = ['BEGINNER', 'INTERMEDIATE', 'ADVANCED'];

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
      padding: EdgeInsets.fromLTRB(0, 24, 24, 24),
      child: Align(
        alignment: Alignment.centerLeft,
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
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
          child: _courses.isEmpty ? _buildEmpty() : _buildCourseGrid(),
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

  Widget _buildCourseGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 3
            : constraints.maxWidth > 600
                ? 2
                : 1;

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: _courses.length + (_isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= _courses.length) {
              return const Center(child: CircularProgressIndicator());
            }
            final course = _courses[index];
            return _CourseCard(
              course: course,
              primaryColor: widget.primaryColor,
              onTap: () {
                final courseId = course['id']?.toString();
                if (courseId != null) {
                  context.go('/admin/course/$courseId');
                }
              },
            );
          },
        );
      },
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

class _CourseCard extends StatefulWidget {
  final Map<String, dynamic> course;
  final Color primaryColor;
  final VoidCallback onTap;

  const _CourseCard({
    required this.course,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  State<_CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<_CourseCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final title = widget.course['title'] ?? widget.course['name'] ?? 'Khóa học';
    final description = widget.course['description'] ?? '';
    final level = widget.course['level'] ?? 'INTERMEDIATE';
    final imageUrl = widget.course['imageUrl'] ?? widget.course['thumbnail'];
    final enrolledCount = widget.course['enrolledCount'] ??
        widget.course['studentCount'] ??
        widget.course['enrolled'] ??
        0;
    final rating = (widget.course['rating'] ?? widget.course['averageRating'] ?? 0).toDouble();

    final levelLabel = _getLevelLabel(level);
    final levelColor = _getLevelColor(level);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered
                  ? widget.primaryColor.withValues(alpha: 0.3)
                  : const Color(0xFFE5E7EB),
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? widget.primaryColor.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: _isHovered ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
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
                    ? Center(
                        child: Icon(Icons.school, size: 40, color: widget.primaryColor.withValues(alpha: 0.5)),
                      )
                    : null,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
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
                      const SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: levelColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              levelLabel,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: levelColor),
                            ),
                          ),
                          const Spacer(),
                          if (enrolledCount is int && enrolledCount > 0) ...[
                            Icon(Icons.people_outline, size: 14, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Text(
                              '$enrolledCount',
                              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                            ),
                          ],
                          if (rating > 0) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.star, size: 14, color: Colors.amber[600]),
                            const SizedBox(width: 2),
                            Text(
                              rating.toStringAsFixed(1),
                              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLevelLabel(String level) {
    switch (level.toUpperCase()) {
      case 'BEGINNER':
        return 'Cơ bản';
      case 'INTERMEDIATE':
        return 'Trung bình';
      case 'ADVANCED':
        return 'Nâng cao';
      default:
        return level;
    }
  }

  Color _getLevelColor(String level) {
    switch (level.toUpperCase()) {
      case 'BEGINNER':
        return Colors.green;
      case 'INTERMEDIATE':
        return Colors.orange;
      case 'ADVANCED':
        return Colors.red;
      default:
        return widget.course['color'] ?? widget.primaryColor;
    }
  }
}
