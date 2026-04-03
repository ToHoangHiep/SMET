import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:smet/service/admin/lms_assignment/lms_assignment_service.dart';
import 'package:smet/page/admin/assignment/widgets/dialog/course_lp_selection_dialog.dart';
import 'package:smet/page/admin/assignment/widgets/dialog/assignable_user_dialog.dart';
import 'package:smet/page/admin/assignment/widgets/dialog/assignment_result_dialog.dart';

class AssignmentManagementPage extends StatefulWidget {
  const AssignmentManagementPage({super.key});

  @override
  State<AssignmentManagementPage> createState() =>
      _AssignmentManagementPageState();
}

class _AssignmentManagementPageState extends State<AssignmentManagementPage> {
  final LmsAssignmentService _assignmentService = LmsAssignmentService();
  final Color _primaryColor = const Color(0xFF6366F1);
  final Color _bgLight = const Color(0xFFF3F6FC);

  BuildContext? _loadingDialogContext;

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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildWelcomeCard(),
                  const SizedBox(height: 24),
                  _buildActionCards(),
                  const SizedBox(height: 24),
                  _buildInfoSection(),
                ],
              ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
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
