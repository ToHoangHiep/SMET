import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/service/admin/department_management/api_department_management.dart';
import 'package:smet/service/admin/lms_assignment/lms_assignment_service.dart';
import 'package:smet/page/admin/assignment/widgets/dialog/assignable_user_dialog.dart';
import 'package:smet/page/admin/assignment/widgets/dialog/assignment_result_dialog.dart';
import 'package:smet/service/common/global_notification_service.dart';

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
  final LmsAssignmentService _assignmentService = LmsAssignmentService();
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
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_courses.length} khóa học',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _handleAssignCourse(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Gán khóa học'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
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
                      context.go('/admin/course/$courseId');
                    }
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleAssignCourse(BuildContext context) async {
    // Chỉ gán 1 course tại đây - lấy từ danh sách courses trong department
    // Nếu muốn gán course chưa có trong department, dùng trang assignment_management
    final selectedCourse = await _showCourseSelectDialog(context);
    if (selectedCourse == null) return;

    // Step 2: Chon users (filter USER)
    final users = await AssignableUserDialog.show(
      context: context,
      primaryColor: widget.primaryColor,
      title: 'Chọn người được gán khóa học',
      roleFilter: 'USER',
    );
    if (users == null || users.isEmpty) return;

    // Step 3: Call API
    if (!context.mounted) return;
    _showLoadingDialog(context);

    try {
      final result = await _assignmentService.assignCourses(
        userIds: users.map((u) => u.userId).toList(),
        courseIds: [selectedCourse['id'] as int],
      );

      if (!context.mounted) return;
      Navigator.of(context).pop();

      await AssignmentResultDialog.show(
        context: context,
        result: result,
        primaryColor: widget.primaryColor,
        assignmentType: 'khóa học',
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      GlobalNotificationService.show(
        context: context,
        message: 'Lỗi: $e',
        type: NotificationType.error,
      );
    }
  }

  Future<Map<String, dynamic>?> _showCourseSelectDialog(BuildContext context) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chọn khóa học'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: ListView.separated(
            itemCount: _courses.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, index) {
              final course = _courses[index];
              final title = course['title'] ?? course['name'] ?? 'Khóa học';
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.school_outlined, color: widget.primaryColor, size: 20),
                ),
                title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => Navigator.pop(ctx, course),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
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
