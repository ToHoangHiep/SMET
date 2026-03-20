import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/service/mentor/course_service.dart';

/// Mentor Course - Mobile Layout (Danh sách khóa học)
class MentorCourseMobile extends StatefulWidget {
  const MentorCourseMobile({super.key});

  @override
  State<MentorCourseMobile> createState() => _MentorCourseMobileState();
}

class _MentorCourseMobileState extends State<MentorCourseMobile> {
  final MentorCourseService _service = MentorCourseService();

  List<CourseResponse> _courses = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedFilter = 'ALL';

  // Pagination
  int _currentPage = 0;
  final int _pageSize = 10;

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
      backgroundColor: const Color(0xfff5f6fa),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Quản lý khóa học",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => context.go('/mentor/courses/create'),
          ),
        ],
      ),
      body: Column(
        children: [
          /// SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onSubmitted: (q) => setState(() {
                _searchQuery = q;
                _loadCourses();
              }),
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

          /// FILTER CHIPS
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _mobileFilterChip('ALL', 'Tất cả'),
                _mobileFilterChip('PUBLISHED', 'Đã xuất bản'),
                _mobileFilterChip('DRAFT', 'Bản nháp'),
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
        backgroundColor: const Color(0xff1a90ff),
        child: const Icon(Icons.add, color: Colors.white),
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
        onSelected: (_) => _onFilterChanged(value),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xffeef3ff),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xff1a90ff) : Colors.grey[700],
          fontSize: 13,
        ),
        side: BorderSide(
          color: isSelected ? const Color(0xff1a90ff) : Colors.grey.shade300,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _buildContent() {
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
              onPressed: _loadCourses,
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
                  ? "Không tìm thấy khóa học"
                  : "Chưa có khóa học nào",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadCourses(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _courses.length,
        itemBuilder: (context, index) => _buildCourseCard(_courses[index]),
      ),
    );
  }

  Widget _buildCourseCard(CourseResponse course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                /// DESCRIPTION
                Text(
                  course.description.isEmpty ? "Không có mô tả" : course.description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }
}
