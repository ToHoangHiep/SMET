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
  List<Map<String, dynamic>> _courses = [];
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
      final courses = await _service.getDepartmentCourses(widget.departmentId);
      setState(() {
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải danh sách khóa học';
        _isLoading = false;
      });
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

    if (_courses.isEmpty) {
      return _buildEmpty();
    }

    return _buildCourseGrid();
  }

  Widget _buildLoading() {
    return Container(
      padding: const EdgeInsets.all(48),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Colors.red[600]),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadCourses,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có khóa học nào',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Phòng ban này chưa được gán khóa học nào.',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
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
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: _courses.length,
          itemBuilder: (context, index) {
            final course = _courses[index];
            return _CourseCard(
              course: course,
              primaryColor: widget.primaryColor,
              onTap: () {
                final courseId = course['id']?.toString();
                if (courseId != null) {
                  context.push('/employee/course/$courseId');
                }
              },
            );
          },
        );
      },
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
    final level = widget.course['level'] ?? 'Trung bình';
    final imageUrl = widget.course['imageUrl'] ?? widget.course['thumbnail'];
    final enrolledCount = widget.course['enrolledCount'] ??
        widget.course['studentCount'] ??
        widget.course['enrolled'] ??
        0;
    final rating = (widget.course['rating'] ?? widget.course['averageRating'] ?? 0).toDouble();

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
              // Image header
              Container(
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.primaryColor.withValues(alpha: 0.15),
                      widget.primaryColor.withValues(alpha: 0.05),
                    ],
                  ),
                  image: imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imageUrl == null
                    ? Center(
                        child: Icon(
                          Icons.school,
                          size: 40,
                          color: widget.primaryColor.withValues(alpha: 0.5),
                        ),
                      )
                    : null,
              ),
              // Content
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
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: widget.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              level,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: widget.primaryColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (enrolledCount is int && enrolledCount > 0) ...[
                            Icon(
                              Icons.people_outline,
                              size: 14,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$enrolledCount',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                          if (rating > 0) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber[600],
                            ),
                            const SizedBox(width: 2),
                            Text(
                              rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
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
}
