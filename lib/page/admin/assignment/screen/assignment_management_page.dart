import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:smet/service/employee/assignment_service.dart';
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
  final AssignmentService _assignmentService = AssignmentService();
  final LmsAssignmentService _lmsAssignmentService = LmsAssignmentService();
  final Color _primaryColor = const Color(0xFF6366F1);

  late TabController _tabController;

  BuildContext? _loadingDialogContext;

  // --- Tab 1: Courses ---
  List<UserEnrollmentData> _enrollments = [];
  bool _isLoadingEnrollments = false;
  int _enrollmentPage = 0;
  int _enrollmentTotalPages = 1;
  int _enrollmentTotalElements = 0;
  String? _enrollmentStatus;
  int? _enrollmentMinProgress;
  int? _enrollmentMaxProgress;
  final TextEditingController _enrollmentSearchController = TextEditingController();
  String? _enrollmentSearchQ;

  // --- Tab 2: Learning Paths ---
  List<UserLearningPathData> _lpAssignments = [];
  bool _isLoadingLP = false;
  int _lpPage = 0;
  int _lpTotalPages = 1;
  int _lpTotalElements = 0;
  final TextEditingController _lpSearchController = TextEditingController();
  String? _lpSearchQ;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _enrollmentSearchController.dispose();
    _lpSearchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index == 1 && _enrollments.isEmpty && !_isLoadingEnrollments) {
      _loadEnrollments();
    } else if (_tabController.index == 2 && _lpAssignments.isEmpty && !_isLoadingLP) {
      _loadLPAssignments();
    }
  }

  // ======================== ENROLLMENT (COURSES) ========================

  Future<void> _loadEnrollments({int page = 0}) async {
    setState(() {
      _isLoadingEnrollments = true;
      _enrollmentPage = page;
    });
    try {
      final result = await _lmsAssignmentService.getEnrollments(
        page: page,
        size: 20,
        status: _enrollmentStatus,
        minProgress: _enrollmentMinProgress,
        maxProgress: _enrollmentMaxProgress,
        q: _enrollmentSearchQ,
      );
      if (mounted) {
        setState(() {
          _enrollments = result.data;
          _enrollmentPage = result.page;
          _enrollmentTotalPages = result.totalPages;
          _enrollmentTotalElements = result.totalElements;
          _isLoadingEnrollments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingEnrollments = false);
      }
    }
  }

  void _applyEnrollmentFilters() {
    _enrollmentSearchQ = _enrollmentSearchController.text.isNotEmpty
        ? _enrollmentSearchController.text
        : null;
    _loadEnrollments();
  }

  void _clearEnrollmentFilters() {
    setState(() {
      _enrollmentStatus = null;
      _enrollmentMinProgress = null;
      _enrollmentMaxProgress = null;
      _enrollmentSearchController.clear();
      _enrollmentSearchQ = null;
    });
    _loadEnrollments();
  }

  void _onEnrollmentStatusChanged(String? value) {
    setState(() => _enrollmentStatus = value);
    _loadEnrollments();
  }

  // ======================== LEARNING PATH ========================

  Future<void> _loadLPAssignments({int page = 0}) async {
    setState(() {
      _isLoadingLP = true;
      _lpPage = page;
    });
    try {
      final result = await _lmsAssignmentService.getLearningPathAssignments(
        page: page,
        size: 20,
        q: _lpSearchQ,
      );
      if (mounted) {
        setState(() {
          _lpAssignments = result.data;
          _lpPage = result.page;
          _lpTotalPages = result.totalPages;
          _lpTotalElements = result.totalElements;
          _isLoadingLP = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLP = false);
      }
    }
  }

  void _applyLPSearch() {
    _lpSearchQ = _lpSearchController.text.isNotEmpty
        ? _lpSearchController.text
        : null;
    _loadLPAssignments();
  }

  void _clearLPSearch() {
    setState(() {
      _lpSearchController.clear();
      _lpSearchQ = null;
    });
    _loadLPAssignments();
  }

  // ======================== UNASSIGN ========================

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
      onConfirm: () => _lmsAssignmentService.unassignCourse(
        courseId: courseId,
        userId: userId,
      ),
    );
    if (confirmed == true) {
      GlobalNotificationService.show(
        context: context,
        message: 'Da huy gan khoa hoc',
        type: NotificationType.success,
      );
      _loadEnrollments(page: _enrollmentPage);
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
      onConfirm: () => _lmsAssignmentService.unassignLearningPath(
        learningPathId: pathId,
        userId: userId,
      ),
    );
    if (confirmed == true) {
      GlobalNotificationService.show(
        context: context,
        message: 'Da huy gan Learning Path',
        type: NotificationType.success,
      );
      _loadLPAssignments(page: _lpPage);
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

  // ======================== BUILD ========================

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Trang quan tri chi ho tro tren Web",
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
          _buildAssignManageTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAssignTab(),
                _buildCoursesTab(),
                _buildLearningPathsTab(),
              ],
            ),
          ),
        ],
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
                  text: 'Quan tri',
                  style: TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(
                  text: ' / Gan khoa hoc & Learning Path',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignManageTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: _primaryColor,
        unselectedLabelColor: const Color(0xFF6B7280),
        indicatorColor: _primaryColor,
        tabs: const [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline, size: 18),
                SizedBox(width: 8),
                Text('Gan moi'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school_outlined, size: 18),
                SizedBox(width: 8),
                Text('Khoa hoc'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.route_outlined, size: 18),
                SizedBox(width: 8),
                Text('Learning Path'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignTab() {
    return SingleChildScrollView(
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
    );
  }

  // ======================== COURSES TAB ========================

  Widget _buildCoursesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEnrollmentFilters(),
          const SizedBox(height: 16),
          _buildEnrollmentsTable(),
          const SizedBox(height: 16),
          _buildEnrollmentPagination(),
        ],
      ),
    );
  }

  Widget _buildEnrollmentFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _enrollmentSearchController,
                  decoration: InputDecoration(
                    hintText: 'Tim kiem nguoi dung hoac khoa hoc...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  onSubmitted: (_) => _applyEnrollmentFilters(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _enrollmentStatus,
                  decoration: InputDecoration(
                    hintText: 'Trang thai',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Tat ca')),
                    DropdownMenuItem(value: 'NOT_STARTED', child: Text('Chua hoc')),
                    DropdownMenuItem(value: 'IN_PROGRESS', child: Text('Dang hoc')),
                    DropdownMenuItem(value: 'COMPLETED', child: Text('Hoan thanh')),
                  ],
                  onChanged: _onEnrollmentStatusChanged,
                ),
              ),
              const SizedBox(width: 12),
              _buildProgressRangeFilter(),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _applyEnrollmentFilters,
                icon: const Icon(Icons.search),
                style: IconButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                ),
                tooltip: 'Tim kiem',
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _clearEnrollmentFilters,
                icon: const Icon(Icons.clear_all),
                tooltip: 'Xoa loc',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRangeFilter() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 70,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Min %',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (v) {
              setState(() {
                _enrollmentMinProgress = int.tryParse(v);
              });
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('-', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          width: 70,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Max %',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (v) {
              setState(() {
                _enrollmentMaxProgress = int.tryParse(v);
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEnrollmentsTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
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
                  'KHOA HOC DA GAN',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
                const Spacer(),
                Text(
                  '$_enrollmentTotalElements ban ghi',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_isLoadingEnrollments)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            )
          else if (_enrollments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.school_outlined, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text('Chua co khoa hoc nao duoc gan',
                        style: TextStyle(color: Colors.grey[500])),
                  ],
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24,
                columns: const [
                  DataColumn(label: Text('Nguoi dung')),
                  DataColumn(label: Text('Khoa hoc')),
                  DataColumn(label: Text('Trang thai')),
                  DataColumn(label: Text('Tien do')),
                  DataColumn(label: Text('Ngay dang ky')),
                  DataColumn(label: Text('Han')),
                  DataColumn(label: Text('Thao tac')),
                ],
                rows: _enrollments.map((e) {
                  return DataRow(
                    cells: [
                      DataCell(Text(e.userName,
                          style: const TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: Text(
                          e.courseTitle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                      DataCell(_buildAdminStatusBadge(e.status)),
                      DataCell(Text('${e.progressPercent}%')),
                      DataCell(Text(_formatDate(e.enrolledAt))),
                      DataCell(Text(_formatDate(e.deadline))),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              size: 20, color: Colors.red),
                          tooltip: 'Huy gan',
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

  Widget _buildEnrollmentPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _enrollmentPage > 0
              ? () => _loadEnrollments(page: _enrollmentPage - 1)
              : null,
          icon: const Icon(Icons.chevron_left),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade100,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Trang ${_enrollmentPage + 1} / $_enrollmentTotalPages',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _enrollmentPage < _enrollmentTotalPages - 1
              ? () => _loadEnrollments(page: _enrollmentPage + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade100,
          ),
        ),
      ],
    );
  }

  // ======================== LEARNING PATHS TAB ========================

  Widget _buildLearningPathsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLPFilters(),
          const SizedBox(height: 16),
          _buildLPAssignmentsTable(),
          const SizedBox(height: 16),
          _buildLPPagination(),
        ],
      ),
    );
  }

  Widget _buildLPFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _lpSearchController,
              decoration: InputDecoration(
                hintText: 'Tim kiem Learning Path...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onSubmitted: (_) => _applyLPSearch(),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _applyLPSearch,
            icon: const Icon(Icons.search),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            tooltip: 'Tim kiem',
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _clearLPSearch,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Xoa tim kiem',
          ),
        ],
      ),
    );
  }

  Widget _buildLPAssignmentsTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
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
                  'LEARNING PATH DA GAN',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
                const Spacer(),
                Text(
                  '$_lpTotalElements ban ghi',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_isLoadingLP)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            )
          else if (_lpAssignments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.route_outlined, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text('Chua co Learning Path nao duoc gan',
                        style: TextStyle(color: Colors.grey[500])),
                  ],
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24,
                columns: const [
                  DataColumn(label: Text('Nguoi dung')),
                  DataColumn(label: Text('Learning Path')),
                  DataColumn(label: Text('Ngay gan')),
                  DataColumn(label: Text('Han')),
                  DataColumn(label: Text('Thao tac')),
                ],
                rows: _lpAssignments.map((lp) {
                  return DataRow(
                    cells: [
                      DataCell(Text(lp.userName,
                          style: const TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 250),
                        child: Text(
                          lp.learningPathTitle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                      DataCell(Text(_formatDate(lp.assignedAt))),
                      DataCell(Text(_formatDate(lp.dueDate))),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              size: 20, color: Colors.red),
                          tooltip: 'Huy gan',
                          onPressed: () => _handleUnassignLearningPath(
                            lp.learningPathId,
                            lp.learningPathTitle,
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

  Widget _buildLPPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _lpPage > 0
              ? () => _loadLPAssignments(page: _lpPage - 1)
              : null,
          icon: const Icon(Icons.chevron_left),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade100,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Trang ${_lpPage + 1} / $_lpTotalPages',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _lpPage < _lpTotalPages - 1
              ? () => _loadLPAssignments(page: _lpPage + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade100,
          ),
        ),
      ],
    );
  }

  // ======================== SHARED WIDGETS ========================

  Widget _buildAdminStatusBadge(String status) {
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

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.day}/${dt.month}/${dt.year}';
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
        borderRadius: BorderRadius.circular(24),
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
                      'Gan khoa hoc & Learning Path',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gan hang loat khoa hoc hoac Learning Path cho nhieu nguoi dung cung luc.',
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
            title: 'Gan khoa hoc',
            description: 'Chon mot hoac nhieu khoa hoc va gan cho nguoi dung.',
            buttonLabel: 'Bat dau gan',
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
            title: 'Gan Learning Path',
            description: 'Chon mot hoac nhieu Learning Path va gan cho nguoi dung.',
            buttonLabel: 'Bat dau gan',
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
                'Thong tin',
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
            'Nguoi da dang ky khoa hoc se bi bo qua.',
            const Color(0xFF059669),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.skip_next_outlined,
            'Nguoi da hoan thanh khoa hoc se bi bo qua.',
            const Color(0xFFD97706),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.route_outlined,
            'Gan Learning Path se tu dong gan khoa hoc dau tien trong lo trinh.',
            const Color(0xFF4F46E5),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.group_outlined,
            'Chi nguoi dang hoat dong moi duoc gan.',
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

    // Admin: lay danh sach user co the gan bang GET /assignments/assignable
    final users = await AssignableUserDialog.show(
      context: context,
      primaryColor: _primaryColor,
      title: 'Chon nguoi duoc gan khoa hoc',
      customUserFetcher: ({
        String? keyword,
        String? role,
        int? departmentId,
        int? page,
        int? size,
      }) =>
          _assignmentService.getAssignableUsers(
        keyword: keyword,
        departmentId: departmentId,
        page: page ?? 0,
        size: size ?? 20,
      ),
    );
    if (users == null || users.isEmpty) return;

    _showLoadingDialog(context);

    try {
      // Admin: POST /assignments voi projectId = null
      final result = await _assignmentService.assignCourses(
        userIds: users.map((u) => u.userId).toList(),
        courseIds: courses.map((c) => c.id).toList(),
      );

      _dismissLoadingDialog();

      if (!context.mounted) return;
      await AssignmentResultDialog.show(
        context: context,
        result: result,
        assignmentType: 'khoa hoc',
      );
    } catch (e) {
      _dismissLoadingDialog();

      if (!context.mounted) return;
      GlobalNotificationService.show(
        context: context,
        message: 'Loi: $e',
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

    // Admin: lay danh sach user co the gan bang GET /assignments/assignable
    final users = await AssignableUserDialog.show(
      context: context,
      primaryColor: const Color(0xFF059669),
      title: 'Chon nguoi duoc gan Learning Path',
      customUserFetcher: ({
        String? keyword,
        String? role,
        int? departmentId,
        int? page,
        int? size,
      }) =>
          _assignmentService.getAssignableUsers(
        keyword: keyword,
        departmentId: departmentId,
        page: page ?? 0,
        size: size ?? 20,
      ),
    );
    if (users == null || users.isEmpty) return;

    _showLoadingDialog(context);

    try {
      // Admin: POST /assignments voi projectId = null
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
        message: 'Loi: $e',
        type: NotificationType.error,
      );
    }
  }

  Color get _bgLight => const Color(0xFFF3F6FC);
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
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isHovered
                  ? widget.primaryColor.withValues(alpha: 0.3)
                  : Colors.grey.shade200.withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? widget.primaryColor.withValues(alpha: 0.08)
                    : widget.primaryColor.withValues(alpha: 0.06),
                blurRadius: _isHovered ? 24 : 36,
                spreadRadius: _isHovered ? 2 : 4,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
