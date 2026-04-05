import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:smet/service/admin/lms_assignment/lms_assignment_service.dart';
import 'package:smet/service/common/global_notification_service.dart';
import 'package:smet/page/admin/assignment/widgets/dialog/course_lp_selection_dialog.dart';
import 'package:smet/page/admin/assignment/widgets/dialog/assignable_user_dialog.dart';
import 'package:smet/page/admin/assignment/widgets/dialog/assignment_result_dialog.dart';
import 'package:smet/page/admin/assignment/widgets/dialog/unassign_dialog.dart';

class AssignmentManagementPage extends StatefulWidget {
  const AssignmentManagementPage({super.key});

  @override
  State<AssignmentManagementPage> createState() =>
      _AssignmentManagementPageState();
}

class _AssignmentManagementPageState extends State<AssignmentManagementPage>
    with TickerProviderStateMixin {
  final LmsAssignmentService _assignmentService = LmsAssignmentService();
  final Color _primaryColor = const Color(0xFF6366F1);

  // Tab controller for switching between assign and manage
  late TabController _tabController;

  // Assignment data for unassign (system-wide — loaded from my-courses for admin)
  List<UserEnrollmentData> _enrollments = [];
  List<UserLearningPathData> _learningPaths = [];
  bool _isLoadingAssignments = false;
  final Color _bgLight = const Color(0xFFF3F6FC);

  BuildContext? _loadingDialogContext;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index == 1 && _enrollments.isEmpty && !_isLoadingAssignments) {
      _loadAssignments();
    }
  }

  Future<void> _loadAssignments() async {
    setState(() => _isLoadingAssignments = true);
    try {
      final results = await Future.wait([
        _assignmentService.getAllEnrollments(),
        _assignmentService.getAllLearningPathAssignments(),
      ]);
      if (mounted) {
        setState(() {
          _enrollments = results[0] as List<UserEnrollmentData>;
          _learningPaths = results[1] as List<UserLearningPathData>;
          _isLoadingAssignments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAssignments = false);
      }
    }
  }

  Future<void> _handleUnassignCourse(
      int courseId, String courseName, int userId, String userName) async {
    final confirmed = await UnassignConfirmDialog.show(
      context: context,
      itemName: courseName,
      userName: userName,
      userId: userId,
      itemId: courseId,
      type: UnassignTargetType.course,
      primaryColor: _primaryColor,
      onConfirm: () => _assignmentService.unassignCourse(
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
    final confirmed = await UnassignConfirmDialog.show(
      context: context,
      itemName: pathName,
      userName: userName,
      userId: userId,
      itemId: pathId,
      type: UnassignTargetType.learningPath,
      primaryColor: _primaryColor,
      onConfirm: () => _assignmentService.unassignLearningPath(
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

  void _showLoadingDialog(BuildContext context) {
    _loadingDialogContext = null;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        _loadingDialogContext = dialogCtx;
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  void _dismissLoadingDialog() {
    if (_loadingDialogContext != null) {
      Navigator.of(_loadingDialogContext!).pop();
      _loadingDialogContext = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Trang quản trị chỉ hỗ trợ trên Web",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return ColoredBox(
      color: _bgLight,
      child: Column(
        children: [
          _buildTopHeader(),
          // Tab bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: _primaryColor,
              unselectedLabelColor: const Color(0xFF6B7280),
              indicatorColor: _primaryColor,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_circle_outline, size: 18),
                      const SizedBox(width: 8),
                      const Text('Gán mới'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.list_alt, size: 18),
                      const SizedBox(width: 8),
                      const Text('Quản lý gán'),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_enrollments.length + _learningPaths.length}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Gán mới
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeCard(),
                      const SizedBox(height: 24),
                      _buildActionCards(),
                      const SizedBox(height: 24),
                      _buildInfoSection(),
                    ],
                  ),
                ),
                // Tab 2: Quản lý gán
                _buildAssignmentManagementTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentManagementTab() {
    if (_isLoadingAssignments) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEnrollmentsSection(),
          const SizedBox(height: 24),
          _buildLearningPathsSection(),
        ],
      ),
    );
  }

  Widget _buildEnrollmentsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school_outlined,
                      color: Color(0xFF4F46E5), size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'KHÓA HỌC ĐÃ GÁN',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
                const Spacer(),
                Text(
                  '${_enrollments.length} bản ghi',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_enrollments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.school_outlined, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text('Chưa có khóa học nào được gán',
                        style: TextStyle(color: Colors.grey[500])),
                  ],
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Người dùng')),
                  DataColumn(label: Text('Khóa học')),
                  DataColumn(label: Text('Trạng thái')),
                  DataColumn(label: Text('Tiến độ')),
                  DataColumn(label: Text('Thao tác')),
                ],
                rows: _enrollments.map((e) {
                  return DataRow(
                    cells: [
                      DataCell(Text(e.userName,
                          style: const TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(Expanded(
                        child: Text(
                          e.courseTitle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                      DataCell(_buildAdminStatusBadge(e.status)),
                      DataCell(Text('${e.progressPercent}%')),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              size: 20, color: Colors.red),
                          tooltip: 'Hủy gán',
                          onPressed: () => _handleUnassignCourse(
                            e.courseId,
                            e.courseTitle,
                            e.userId,
                            e.userName,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLearningPathsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.route_outlined,
                      color: Color(0xFF059669), size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'LEARNING PATH ĐÃ GÁN',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
                const Spacer(),
                Text(
                  '${_learningPaths.length} bản ghi',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_learningPaths.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.route_outlined, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text('Chưa có Learning Path nào được gán',
                        style: TextStyle(color: Colors.grey[500])),
                  ],
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Người dùng')),
                  DataColumn(label: Text('Learning Path')),
                  DataColumn(label: Text('Số khóa')),
                  DataColumn(label: Text('Thao tác')),
                ],
                rows: _learningPaths.map((lp) {
                  return DataRow(
                    cells: [
                      DataCell(Text(lp.userName,
                          style: const TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(Expanded(
                        child: Text(
                          lp.pathTitle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                      DataCell(Text('${lp.courseCount} khóa')),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              size: 20, color: Colors.red),
                          tooltip: 'Hủy gán',
                          onPressed: () => _handleUnassignLearningPath(
                            lp.pathId,
                            lp.pathTitle,
                            lp.userId,
                            lp.userName,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdminStatusBadge(String status) {
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

  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.assignment_ind,
              color: _primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14),
              children: [
                TextSpan(
                  text: 'Quản trị',
                  style: TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(
                  text: ' / Gán khóa học & Learning Path',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _primaryColor.withValues(alpha: 0.08),
            _primaryColor.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primaryColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.school_outlined,
                  color: _primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gán khóa học & Learning Path',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gán hàng loạt khóa học hoặc Learning Path cho nhiều người dùng cùng lúc.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCards() {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.school_outlined,
            iconBgColor: const Color(0xFFEEF2FF),
            iconColor: const Color(0xFF4F46E5),
            title: 'Gán khóa học',
            description: 'Chọn một hoặc nhiều khóa học và gán cho người dùng.',
            buttonLabel: 'Bắt đầu gán',
            onTap: () => _handleAssignCourse(context),
            primaryColor: _primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ActionCard(
            icon: Icons.route_outlined,
            iconBgColor: const Color(0xFFECFDF5),
            iconColor: const Color(0xFF059669),
            title: 'Gán Learning Path',
            description: 'Chọn một hoặc nhiều Learning Path và gán cho người dùng.',
            buttonLabel: 'Bắt đầu gán',
            onTap: () => _handleAssignLearningPath(context),
            primaryColor: const Color(0xFF059669),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Colors.grey[500]),
              const SizedBox(width: 8),
              Text(
                'Thông tin',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.check_circle_outline,
            'Người đã đăng ký khóa học sẽ bị bỏ qua.',
            const Color(0xFF059669),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.skip_next_outlined,
            'Người đã hoàn thành khóa học sẽ bị bỏ qua.',
            const Color(0xFFD97706),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.route_outlined,
            'Gán Learning Path sẽ tự động gán khóa học đầu tiên trong lộ trình.',
            const Color(0xFF4F46E5),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.group_outlined,
            'Chỉ người dùng đang hoạt động mới được gán.',
            const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAssignCourse(BuildContext context) async {
    final courses = await CourseLPSelectionDialog.showForCourse(
      context: context,
      primaryColor: _primaryColor,
    );
    if (courses == null || courses.isEmpty) return;

    final users = await AssignableUserDialog.show(
      context: context,
      primaryColor: _primaryColor,
      title: 'Chọn người được gán khóa học',
      roleFilter: 'USER',
    );
    if (users == null || users.isEmpty) return;

    _showLoadingDialog(context);

    try {
      final result = await _assignmentService.assignCourses(
        userIds: users.map((u) => u.userId).toList(),
        courseIds: courses.map((c) => c.id).toList(),
      );

      _dismissLoadingDialog();

      if (!context.mounted) return;
      await AssignmentResultDialog.show(
        context: context,
        result: result,
        assignmentType: 'khóa học',
      );
    } catch (e) {
      _dismissLoadingDialog();

      if (!context.mounted) return;
      GlobalNotificationService.show(
        context: context,
        message: 'Lỗi: $e',
        type: NotificationType.error,
      );
    }
  }

  Future<void> _handleAssignLearningPath(BuildContext context) async {
    final paths = await CourseLPSelectionDialog.showForLearningPath(
      context: context,
      primaryColor: const Color(0xFF059669),
    );
    if (paths == null || paths.isEmpty) return;

    final users = await AssignableUserDialog.show(
      context: context,
      primaryColor: const Color(0xFF059669),
      title: 'Chọn người được gán Learning Path',
      roleFilter: 'USER',
    );
    if (users == null || users.isEmpty) return;

    _showLoadingDialog(context);

    try {
      final result = await _assignmentService.assignLearningPaths(
        userIds: users.map((u) => u.userId).toList(),
        learningPathIds: paths.map((p) => p.id).toList(),
      );

      _dismissLoadingDialog();

      if (!context.mounted) return;
      await AssignmentResultDialog.show(
        context: context,
        result: result,
        assignmentType: 'Learning Path',
      );
    } catch (e) {
      _dismissLoadingDialog();

      if (!context.mounted) return;
      GlobalNotificationService.show(
        context: context,
        message: 'Lỗi: $e',
        type: NotificationType.error,
      );
    }
  }
}

class _ActionCard extends StatefulWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onTap;
  final Color primaryColor;

  const _ActionCard({
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
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered
                  ? widget.primaryColor.withValues(alpha: 0.3)
                  : const Color(0xFFE5E7EB),
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? widget.primaryColor.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: _isHovered ? 20 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: widget.iconBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.iconColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _isHovered
                      ? widget.primaryColor
                      : widget.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: _isHovered ? Colors.white : widget.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.buttonLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _isHovered ? Colors.white : widget.primaryColor,
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
