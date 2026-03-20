import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/service/mentor/course_service.dart';

/// Mentor Course - Web Layout (Danh sách khóa học)
class MentorCourseWeb extends StatefulWidget {
  const MentorCourseWeb({super.key});

  @override
  State<MentorCourseWeb> createState() => _MentorCourseWebState();
}

class _MentorCourseWebState extends State<MentorCourseWeb> {
  final MentorCourseService _service = MentorCourseService();

  List<CourseResponse> _courses = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedFilter = 'ALL';

  // Pagination
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  final int _pageSize = 9;

  final _searchController = TextEditingController();

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
      _isLoading = true;
      _error = null;
      _currentPage = page;
    });

    try {
      bool? published;
      if (_selectedFilter == 'PUBLISHED') {
        published = true;
      } else if (_selectedFilter == 'DRAFT') {
        published = false;
      }

      final result = await _service.listCourses(
        keyword: _searchQuery.isNotEmpty ? _searchQuery : null,
        published: published,
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
      backgroundColor: const Color(0xfff5f6fa),
      body: Column(
        children: [
          /// TOPBAR
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 30),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "Quản lý khóa học",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xff1a90ff),
                  child: Icon(Icons.person, color: Colors.white, size: 18),
                )
              ],
            ),
          ),

          /// CONTENT
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// CREATE BUTTON
                  ElevatedButton.icon(
                    onPressed: () => context.go('/mentor/courses/create'),
                    icon: const Icon(Icons.add),
                    label: const Text("Tạo khóa học mới"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// SEARCH + FILTER
                  Row(
                    children: [
                      SizedBox(
                        width: 320,
                        child: TextField(
                          controller: _searchController,
                          onSubmitted: _onSearch,
                          decoration: InputDecoration(
                            hintText: "Tìm kiếm khóa học...",
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      _filterChip("ALL"),
                      _filterChip("PUBLISHED"),
                      _filterChip("DRAFT"),
                    ],
                  ),
                  const SizedBox(height: 20),

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

  Widget _filterChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: ChoiceChip(
        label: Text(_filterLabel(label)),
        selected: _selectedFilter == label,
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
      default: return label;
    }
  }

  Widget _buildContent(int crossAxisCount) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
            Icon(Icons.menu_book, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'ALL'
                  ? "Không tìm thấy khóa học phù hợp"
                  : "Chưa có khóa học nào",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (_searchQuery.isEmpty && _selectedFilter == 'ALL') ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => context.go('/mentor/courses/create'),
                icon: const Icon(Icons.add),
                label: const Text("Tạo khóa học đầu tiên"),
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
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
                    const Spacer(),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.grey[600]),
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
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
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
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
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
          color: Colors.grey[600],
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
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isCurrent ? const Color(0xff1a90ff) : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "${pageNum + 1}",
                    style: TextStyle(
                      color: isCurrent ? Colors.white : Colors.grey[700],
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
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
          color: Colors.grey[600],
        ),
        const SizedBox(width: 16),
        Text(
          "$_totalElements khóa học",
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
