import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/project_model.dart';
import 'package:smet/page/project_manager/widgets/shell/pm_top_header.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/service/common/auth_service.dart';
import 'package:smet/service/admin/lms_assignment/lms_assignment_service.dart';
import 'package:smet/page/admin/assignment/widgets/dialog/course_lp_selection_dialog.dart';
import 'package:smet/page/admin/assignment/widgets/dialog/assignable_user_dialog.dart';
import 'package:smet/page/admin/assignment/widgets/dialog/assignment_result_dialog.dart';
import 'package:smet/page/admin/assignment/widgets/dialog/unassign_dialog.dart';
import 'package:smet/service/common/global_notification_service.dart';
import 'package:smet/service/mentor/mentor_project_service.dart';

class PmAssignmentPage extends StatefulWidget {
  const PmAssignmentPage({super.key});

  @override
  State<PmAssignmentPage> createState() => _PmAssignmentPageState();
}

class _PmAssignmentPageState extends State<PmAssignmentPage>
    with SingleTickerProviderStateMixin {
  final LmsAssignmentService _assignmentService = LmsAssignmentService();

  List<ProjectModel> _projects = [];
  ProjectModel? _selectedProject;
  List<ProjectAssignmentData> _assignments = [];
  bool _isLoadingProjects = false;
  bool _isLoadingAssignments = false;
  bool _isLoadingAssign = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProjects();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoadingProjects = true);
    try {
      final projects = await MentorProjectService.getMyProjects();
      setState(() {
        _projects = projects;
        _isLoadingProjects = false;
        if (projects.isNotEmpty && _selectedProject == null) {
          _selectedProject = projects.first;
          _loadAssignments();
        }
      });
    } catch (e) {
      setState(() => _isLoadingProjects = false);
    }
  }

  Future<void> _loadAssignments() async {
    if (_selectedProject == null) return;
    setState(() => _isLoadingAssignments = true);
    try {
      final assignments =
          await MentorProjectService.getAssignments(_selectedProject!.id);
      setState(() {
        _assignments = assignments;
        _isLoadingAssignments = false;
      });
    } catch (e) {
      setState(() => _isLoadingAssignments = false);
    }
  }

  Future<void> _handleAssignCourse() async {
    if (_selectedProject == null) return;

    final courses = await CourseLPSelectionDialog.showForCourse(
      context: context,
      primaryColor: const Color(0xFF137FEC),
    );
    if (courses == null || courses.isEmpty) return;

    final users = await AssignableUserDialog.show(
      context: context,
      primaryColor: const Color(0xFF137FEC),
      title: 'Chọn thành viên được gán khóa học',
      roleFilter: 'USER',
    );
    if (users == null || users.isEmpty) return;

    setState(() => _isLoadingAssign = true);
    try {
      final result = await _assignmentService.assignCourses(
        userIds: users.map((u) => u.userId).toList(),
        courseIds: courses.map((c) => c.id).toList(),
        projectId: Long(_selectedProject!.id),
      );
      if (!mounted) return;
      await AssignmentResultDialog.show(
        context: context,
        result: result,
        assignmentType: 'khóa học',
      );
      _loadAssignments();
    } catch (e) {
      if (!mounted) return;
      GlobalNotificationService.show(
        context: context,
        message: 'Lỗi: $e',
        type: NotificationType.error,
      );
    } finally {
      if (mounted) setState(() => _isLoadingAssign = false);
    }
  }

  Future<void> _handleAssignLearningPath() async {
    if (_selectedProject == null) return;

    final paths = await CourseLPSelectionDialog.showForLearningPath(
      context: context,
      primaryColor: const Color(0xFF059669),
    );
    if (paths == null || paths.isEmpty) return;

    final users = await AssignableUserDialog.show(
      context: context,
      primaryColor: const Color(0xFF059669),
      title: 'Chọn thành viên được gán Learning Path',
      roleFilter: 'USER',
    );
    if (users == null || users.isEmpty) return;

    setState(() => _isLoadingAssign = true);
    try {
      final result = await _assignmentService.assignLearningPaths(
        userIds: users.map((u) => u.userId).toList(),
        learningPathIds: paths.map((p) => p.id).toList(),
        projectId: Long(_selectedProject!.id),
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
      GlobalNotificationService.show(
        context: context,
        message: 'Lỗi: $e',
        type: NotificationType.error,
      );
    } finally {
      if (mounted) setState(() => _isLoadingAssign = false);
    }
  }

  Future<void> _handleUnassignCourse(
      int courseId, String courseName, int userId, String userName) async {
    if (_selectedProject == null) return;

    final confirmed = await UnassignConfirmDialog.show(
      context: context,
      itemName: courseName,
      userName: userName,
      userId: userId,
      itemId: courseId,
      type: UnassignTargetType.course,
      primaryColor: const Color(0xFF137FEC),
      onConfirm: () => _assignmentService.unassignCourseByProject(
        projectId: _selectedProject!.id,
        courseId: courseId,
        userId: userId,
      ),
    );

    if (confirmed == true) {
      GlobalNotificationService.show(
        context: context,
        message: 'Đã hủy gán khóa học',
        type: NotificationType.success,
      );
      _loadAssignments();
    }
  }

  Future<void> _handleUnassignLearningPath(
      int pathId, String pathName, int userId, String userName) async {
    if (_selectedProject == null) return;

    final confirmed = await UnassignConfirmDialog.show(
      context: context,
      itemName: pathName,
      userName: userName,
      userId: userId,
      itemId: pathId,
      type: UnassignTargetType.learningPath,
      primaryColor: const Color(0xFF137FEC),
      onConfirm: () => _assignmentService.unassignLearningPathByProject(
        projectId: _selectedProject!.id,
        learningPathId: pathId,
        userId: userId,
      ),
    );

    if (confirmed == true) {
      GlobalNotificationService.show(
        context: context,
        message: 'Đã hủy gán Learning Path',
        type: NotificationType.success,
      );
      _loadAssignments();
    }
  }

  void handleLogout() async {
    await AuthService.logout();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      body: SafeArea(
        child: Column(
          children: [
            PmTopHeader(
              currentPage: 'Gán khóa học',
              breadcrumbs: const [
                BreadcrumbItem(label: 'Trang chủ', route: '/home'),
                BreadcrumbItem(label: 'Gán khóa học'),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProjectSelector(),
                    const SizedBox(height: 20),
                    _buildActionCards(),
                    const SizedBox(height: 20),
                    _buildAssignmentTable(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF137FEC).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.folder_outlined,
                color: Color(0xFF137FEC), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dự án',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                _isLoadingProjects
                    ? const SizedBox(
                        height: 20,
                        width: 150,
                        child: LinearProgressIndicator(),
                      )
                    : _projects.isEmpty
                        ? const Text('Không có dự án nào',
                            style: TextStyle(color: Colors.grey))
                        : DropdownButton<ProjectModel>(
                            value: _selectedProject,
                            isExpanded: true,
                            underline: const SizedBox(),
                            hint: const Text('Chọn dự án'),
                            items: _projects.map((p) {
                              return DropdownMenuItem(
                                value: p,
                                child: Text(
                                  p.title,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (project) {
                              setState(() {
                                _selectedProject = project;
                                _assignments = [];
                              });
                              _loadAssignments();
                            },
                          ),
              ],
            ),
          ),
          if (_selectedProject != null) ...[
            const SizedBox(width: 16),
            IconButton(
              onPressed: _loadAssignments,
              icon: const Icon(Icons.refresh, color: Color(0xFF137FEC)),
              tooltip: 'Tải lại',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionCards() {
    final enabled = _selectedProject != null && !_isLoadingAssign;
    return Row(
      children: [
        Expanded(
          child: _AssignmentActionCard(
            icon: Icons.school_outlined,
            iconBgColor: const Color(0xFFEEF2FF),
            iconColor: const Color(0xFF4F46E5),
            title: 'Gán khóa học',
            description: 'Gán một hoặc nhiều khóa học cho thành viên.',
            buttonLabel: 'Bắt đầu gán',
            onTap: enabled ? _handleAssignCourse : null,
            primaryColor: const Color(0xFF4F46E5),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _AssignmentActionCard(
            icon: Icons.route_outlined,
            iconBgColor: const Color(0xFFECFDF5),
            iconColor: const Color(0xFF059669),
            title: 'Gán Learning Path',
            description: 'Gán Learning Path cho thành viên trong dự án.',
            buttonLabel: 'Bắt đầu gán',
            onTap: enabled ? _handleAssignLearningPath : null,
            primaryColor: const Color(0xFF059669),
          ),
        ),
      ],
    );
  }

  Widget _buildAssignmentTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.assignment_ind,
                    size: 20, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                const Text(
                  'DANH SÁCH GÁN HIỆN TẠI',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
                const Spacer(),
                if (_isLoadingAssignments)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Tab bar
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF137FEC),
            unselectedLabelColor: const Color(0xFF6B7280),
            indicatorColor: const Color(0xFF137FEC),
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.school_outlined, size: 16),
                    const SizedBox(width: 6),
                    const Text('Khóa học'),
                    const SizedBox(width: 6),
                    _buildCountBadge(
                        _assignments.fold(0, (sum, a) => sum + a.courses.length),
                        const Color(0xFF4F46E5)),
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
                    _buildCountBadge(
                        _assignments.fold(
                            0, (sum, a) => sum + a.learningPaths.length),
                        const Color(0xFF059669)),
                  ],
                ),
              ),
            ],
          ),
          // Tab content
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCourseList(),
                _buildLearningPathList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildCourseList() {
    if (_isLoadingAssignments) {
      return const Center(child: CircularProgressIndicator());
    }

    final items = <_AssignmentRowData>[];
    for (final a in _assignments) {
      for (final c in a.courses) {
        items.add(_AssignmentRowData(
          userId: a.userId,
          userName: a.userName,
          itemId: c.courseId,
          itemName: c.title,
          itemType: 'course',
          status: c.status,
          progress: c.progress,
        ));
      }
    }

    if (items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.school_outlined,
        message: 'Chưa có khóa học nào được gán',
        subMessage: 'Chọn dự án và gán khóa học cho thành viên.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Người dùng')),
          DataColumn(label: Text('Khóa học')),
          DataColumn(label: Text('Tiến độ')),
          DataColumn(label: Text('Thao tác')),
        ],
        rows: items.map((item) {
          return DataRow(
            cells: [
              DataCell(Text(item.userName,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
              DataCell(Expanded(
                child: Text(
                  item.itemName,
                  overflow: TextOverflow.ellipsis,
                ),
              )),
              DataCell(_buildStatusBadge(item.status, item.progress)),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      size: 20, color: Colors.red),
                  tooltip: 'Hủy gán',
                  onPressed: () => _handleUnassignCourse(
                    item.itemId,
                    item.itemName,
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
    if (_isLoadingAssignments) {
      return const Center(child: CircularProgressIndicator());
    }

    final items = <_AssignmentRowData>[];
    for (final a in _assignments) {
      for (final lp in a.learningPaths) {
        items.add(_AssignmentRowData(
          userId: a.userId,
          userName: a.userName,
          itemId: lp.pathId,
          itemName: lp.title,
          itemType: 'learningPath',
          status: '',
          progress: 0,
        ));
      }
    }

    if (items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.route_outlined,
        message: 'Chưa có Learning Path nào được gán',
        subMessage: 'Chọn dự án và gán Learning Path cho thành viên.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Người dùng')),
          DataColumn(label: Text('Learning Path')),
          DataColumn(label: Text('Thao tác')),
        ],
        rows: items.map((item) {
          return DataRow(
            cells: [
              DataCell(Text(item.userName,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
              DataCell(Expanded(
                child: Text(
                  item.itemName,
                  overflow: TextOverflow.ellipsis,
                ),
              )),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      size: 20, color: Colors.red),
                  tooltip: 'Hủy gán',
                  onPressed: () => _handleUnassignLearningPath(
                    item.itemId,
                    item.itemName,
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

  Widget _buildStatusBadge(String status, int progress) {
    Color color;
    String label;
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        color = Colors.green;
        label = 'Hoàn thành';
        break;
      case 'IN_PROGRESS':
      case 'INPROGRESS':
        color = Colors.orange;
        label = 'Đang học';
        break;
      default:
        color = Colors.grey;
        label = 'Chưa học';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subMessage,
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AssignmentRowData {
  final int userId;
  final String userName;
  final int itemId;
  final String itemName;
  final String itemType;
  final String status;
  final int progress;

  _AssignmentRowData({
    required this.userId,
    required this.userName,
    required this.itemId,
    required this.itemName,
    required this.itemType,
    required this.status,
    required this.progress,
  });
}

class _AssignmentActionCard extends StatefulWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback? onTap;
  final Color primaryColor;

  const _AssignmentActionCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onTap,
    required this.primaryColor,
  });

  @override
  State<_AssignmentActionCard> createState() => _AssignmentActionCardState();
}

class _AssignmentActionCardState extends State<_AssignmentActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered && enabled
                  ? widget.primaryColor.withValues(alpha: 0.3)
                  : const Color(0xFFE5E7EB),
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered && enabled
                    ? widget.primaryColor.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: _isHovered ? 16 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: widget.iconColor, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _isHovered && enabled
                      ? widget.primaryColor
                      : widget.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: _isHovered && enabled
                          ? Colors.white
                          : widget.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.buttonLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _isHovered && enabled
                            ? Colors.white
                            : widget.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
