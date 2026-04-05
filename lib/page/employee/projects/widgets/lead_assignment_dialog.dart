import 'package:flutter/material.dart';
import 'package:smet/model/project_model.dart';
import 'package:smet/service/employee/employee_project_service.dart';
import 'package:smet/page/admin/assignment/widgets/dialog/course_lp_selection_dialog.dart';
import 'package:smet/page/admin/assignment/widgets/dialog/assignable_user_dialog.dart';
import 'package:smet/page/admin/assignment/widgets/dialog/assignment_result_dialog.dart';
import 'package:smet/page/admin/assignment/widgets/dialog/unassign_dialog.dart';
import 'dart:developer';

class LeadAssignmentDialog extends StatefulWidget {
  final ProjectModel project;

  const LeadAssignmentDialog({
    super.key,
    required this.project,
  });

  static Future<void> show({
    required BuildContext context,
    required ProjectModel project,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => LeadAssignmentDialog(project: project),
    );
  }

  @override
  State<LeadAssignmentDialog> createState() => _LeadAssignmentDialogState();
}

class _LeadAssignmentDialogState extends State<LeadAssignmentDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ProjectAssignmentData> _assignments = [];
  bool _isLoading = true;
  bool _isAssigning = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAssignments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAssignments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final assignments = await EmployeeProjectService.getAssignments(widget.project.id);
      if (mounted) {
        setState(() {
          _assignments = assignments;
          _isLoading = false;
        });
      }
    } catch (e) {
      log('LeadAssignmentDialog._loadAssignments failed: $e');
      if (mounted) {
        setState(() {
          _error = 'Khong the tai danh sach gán';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAssignCourse() async {
    final courses = await CourseLPSelectionDialog.showForCourse(
      context: context,
      primaryColor: const Color(0xFF4F46E5),
    );
    if (courses == null || courses.isEmpty) return;

    final users = await AssignableUserDialog.show(
      context: context,
      primaryColor: const Color(0xFF4F46E5),
      title: 'Chon thanh vien duoc gan khoa hoc',
      roleFilter: 'USER',
    );
    if (users == null || users.isEmpty) return;

    setState(() => _isAssigning = true);
    try {
      final result = await EmployeeProjectService.assignCourses(
        projectId: widget.project.id,
        userIds: users.map((u) => u.userId).toList(),
        courseIds: courses.map((c) => c.id).toList(),
      );
      if (!mounted) return;
      await AssignmentResultDialog.show(
        context: context,
        result: result,
        assignmentType: 'khoa hoc',
      );
      _loadAssignments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loi: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isAssigning = false);
    }
  }

  Future<void> _handleAssignLearningPath() async {
    final paths = await CourseLPSelectionDialog.showForLearningPath(
      context: context,
      primaryColor: const Color(0xFF059669),
    );
    if (paths == null || paths.isEmpty) return;

    final users = await AssignableUserDialog.show(
      context: context,
      primaryColor: const Color(0xFF059669),
      title: 'Chon thanh vien duoc gan Learning Path',
      roleFilter: 'USER',
    );
    if (users == null || users.isEmpty) return;

    setState(() => _isAssigning = true);
    try {
      final result = await EmployeeProjectService.assignLearningPaths(
        projectId: widget.project.id,
        userIds: users.map((u) => u.userId).toList(),
        learningPathIds: paths.map((p) => p.id).toList(),
      );
      if (!mounted) return;
      await AssignmentResultDialog.show(
        context: context,
        result: result,
        assignmentType: 'Learning Path',
      );
      _loadAssignments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loi: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isAssigning = false);
    }
  }

  Future<void> _handleUnassignCourse(
    int courseId,
    String courseName,
    int userId,
    String userName,
  ) async {
    final confirmed = await UnassignConfirmDialog.show(
      context: context,
      itemName: courseName,
      userName: userName,
      userId: userId,
      itemId: courseId,
      type: UnassignTargetType.course,
      primaryColor: const Color(0xFF4F46E5),
      onConfirm: () => EmployeeProjectService.unassignCourse(
        projectId: widget.project.id,
        courseId: courseId,
        userId: userId,
      ),
    );

    if (confirmed == true) {
      _loadAssignments();
    }
  }

  Future<void> _handleUnassignLearningPath(
    int pathId,
    String pathName,
    int userId,
    String userName,
  ) async {
    final confirmed = await UnassignConfirmDialog.show(
      context: context,
      itemName: pathName,
      userName: userName,
      userId: userId,
      itemId: pathId,
      type: UnassignTargetType.learningPath,
      primaryColor: const Color(0xFF059669),
      onConfirm: () => EmployeeProjectService.unassignLearningPath(
        projectId: widget.project.id,
        learningPathId: pathId,
        userId: userId,
      ),
    );

    if (confirmed == true) {
      _loadAssignments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 800,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E40AF),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment_ind,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quan ly gan khoa hoc',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.project.title,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _ActionButton(
                icon: Icons.school_outlined,
                label: 'Gan khoa hoc',
                color: const Color(0xFF4F46E5),
                onPressed: _isAssigning ? null : _handleAssignCourse,
              ),
              const SizedBox(width: 12),
              _ActionButton(
                icon: Icons.route_outlined,
                label: 'Gan Learning Path',
                color: const Color(0xFF059669),
                onPressed: _isAssigning ? null : _handleAssignLearningPath,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(60),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadAssignments,
              child: const Text('Thu lai'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1E40AF),
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: const Color(0xFF1E40AF),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.school_outlined, size: 16),
                  const SizedBox(width: 6),
                  const Text('Khoa hoc'),
                  const SizedBox(width: 6),
                  _buildBadge(
                    _assignments.fold(0, (sum, a) => sum + a.courses.length),
                    const Color(0xFF4F46E5),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.route_outlined, size: 16),
                  const SizedBox(width: 6),
                  const Text('Learning Path'),
                  const SizedBox(width: 6),
                  _buildBadge(
                    _assignments.fold(0, (sum, a) => sum + a.learningPaths.length),
                    const Color(0xFF059669),
                  ),
                ],
              ),
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCourseList(),
              _buildLearningPathList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildCourseList() {
    final items = <_CourseAssignmentRow>[];
    for (final a in _assignments) {
      for (final c in a.courses) {
        items.add(_CourseAssignmentRow(
          userId: a.userId,
          userName: a.userName,
          courseId: c.courseId,
          courseName: c.title,
          status: c.status,
          progress: c.progress,
        ));
      }
    }

    if (items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.school_outlined,
        message: 'Chua co khoa hoc nao duoc gan',
        subMessage: 'Nhan "Gan khoa hoc" de bat dau.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
        columns: const [
          DataColumn(label: Text('Thanh vien', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Khoa hoc', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Tien do', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Thao tac', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: items.map((item) {
          return DataRow(
            cells: [
              DataCell(Text(item.userName, style: const TextStyle(fontWeight: FontWeight.w500))),
              DataCell(Expanded(
                child: Text(item.courseName, overflow: TextOverflow.ellipsis),
              )),
              DataCell(_buildStatusChip(item.status, item.progress)),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.red),
                  tooltip: 'Huy gan',
                  onPressed: () => _handleUnassignCourse(
                    item.courseId,
                    item.courseName,
                    item.userId,
                    item.userName,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLearningPathList() {
    final items = <_LPRow>[];
    for (final a in _assignments) {
      for (final lp in a.learningPaths) {
        items.add(_LPRow(
          userId: a.userId,
          userName: a.userName,
          pathId: lp.pathId,
          pathName: lp.title,
        ));
      }
    }

    if (items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.route_outlined,
        message: 'Chua co Learning Path nao duoc gan',
        subMessage: 'Nhan "Gan Learning Path" de bat dau.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
        columns: const [
          DataColumn(label: Text('Thanh vien', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Learning Path', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Thao tac', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: items.map((item) {
          return DataRow(
            cells: [
              DataCell(Text(item.userName, style: const TextStyle(fontWeight: FontWeight.w500))),
              DataCell(Expanded(
                child: Text(item.pathName, overflow: TextOverflow.ellipsis),
              )),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.red),
                  tooltip: 'Huy gan',
                  onPressed: () => _handleUnassignLearningPath(
                    item.pathId,
                    item.pathName,
                    item.userId,
                    item.userName,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusChip(String status, int progress) {
    Color color;
    String label;
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        color = Colors.green;
        label = 'Hoan thanh';
        break;
      case 'IN_PROGRESS':
      case 'INPROGRESS':
        color = Colors.orange;
        label = 'Dang hoc';
        break;
      default:
        color = Colors.grey;
        label = 'Chua hoc';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String subMessage,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            subMessage,
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
    );
  }
}

class _CourseAssignmentRow {
  final int userId;
  final String userName;
  final int courseId;
  final String courseName;
  final String status;
  final int progress;

  _CourseAssignmentRow({
    required this.userId,
    required this.userName,
    required this.courseId,
    required this.courseName,
    required this.status,
    required this.progress,
  });
}

class _LPRow {
  final int userId;
  final String userName;
  final int pathId;
  final String pathName;

  _LPRow({
    required this.userId,
    required this.userName,
    required this.pathId,
    required this.pathName,
  });
}
