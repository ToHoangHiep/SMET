import 'package:flutter/material.dart';
import 'package:smet/model/project_model.dart';
import 'package:smet/service/employee/employee_project_service.dart';
import 'package:smet/page/employee/projects/widgets/lead_assignment_dialog.dart';
import 'dart:developer';

class ProjectDetailLeadDialog extends StatefulWidget {
  final ProjectModel project;
  final VoidCallback onRefresh;

  const ProjectDetailLeadDialog({
    super.key,
    required this.project,
    required this.onRefresh,
  });

  @override
  State<ProjectDetailLeadDialog> createState() => _ProjectDetailLeadDialogState();
}

class _ProjectDetailLeadDialogState extends State<ProjectDetailLeadDialog> {
  ProjectDashboardData? _dashboard;
  ProjectReviewStateData? _reviewState;
  ProjectModel? _projectDetail;
  List<MemberProgressData> _membersProgress = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  final _linkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        EmployeeProjectService.getDashboard(widget.project.id),
        EmployeeProjectService.getReviewState(widget.project.id),
        EmployeeProjectService.getMembersProgress(widget.project.id),
        EmployeeProjectService.getProjectDetail(widget.project.id),
      ]);

      if (mounted) {
        setState(() {
          _dashboard = results[0] as ProjectDashboardData;
          _reviewState = results[1] as ProjectReviewStateData;
          _membersProgress = results[2] as List<MemberProgressData>;
          _projectDetail = results[3] as ProjectModel;
          _isLoading = false;
        });
      }
    } catch (e) {
      log('ProjectDetailLeadDialog._loadData failed: $e');
      if (mounted) {
        setState(() {
          _error = 'Khong the tai du lieu';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitProject() async {
    final link = _linkController.text.trim();
    if (link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui long nhap link du an')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await EmployeeProjectService.submitProject(widget.project.id, link);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nop du an thanh cong!')),
        );
        _linkController.clear();
        await _loadData();
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loi: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _openAssignmentDialog() {
    LeadAssignmentDialog.show(
      context: context,
      project: widget.project,
    ).then((_) {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 600 ? 600.0 : screenWidth * 0.9;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: dialogWidth,
        constraints: const BoxConstraints(maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildError()
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProjectInfo(),
                              const SizedBox(height: 20),
                              _buildReviewState(),
                              const SizedBox(height: 20),
                              _buildFeedbackSection(),
                              const SizedBox(height: 20),
                              _buildProgressSummary(),
                              const SizedBox(height: 20),
                              _buildMembersProgress(),
                              const SizedBox(height: 20),
                              _buildSubmitSection(),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF137FEC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.project.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Truong nhom',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _openAssignmentDialog,
                icon: const Icon(Icons.assignment_ind, color: Colors.white),
                tooltip: 'Quan ly gan',
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error ?? 'Da xay ra loi'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Thu lai'),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getStatusColor(widget.project.status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            widget.project.status.label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: _getStatusColor(widget.project.status),
            ),
          ),
          if (widget.project.description != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  widget.project.description!,
                  style: const TextStyle(color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewState() {
    if (_reviewState == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trang thai review',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildReviewStep(
                'Da nop',
                _reviewState!.submitted,
                Icons.check_circle,
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF94A3B8)),
              const SizedBox(width: 8),
              _buildReviewStep(
                'Mentor duyet',
                _reviewState!.mentorApproved,
                Icons.school,
                isSkipped: !_reviewState!.hasMentor,
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF94A3B8)),
              const SizedBox(width: 8),
              _buildReviewStep(
                'PM duyet',
                _reviewState!.pmApproved,
                Icons.manage_accounts,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep(String label, bool isComplete, IconData icon, {bool isSkipped = false}) {
    Color circleColor;
    Color iconColor;
    Color textColor;

    if (isComplete) {
      circleColor = const Color(0xFF22C55E);
      iconColor = Colors.white;
      textColor = const Color(0xFF22C55E);
    } else if (isSkipped) {
      circleColor = Colors.grey.shade300;
      iconColor = Colors.grey.shade400;
      textColor = Colors.grey.shade400;
    } else {
      circleColor = const Color(0xFFE2E8F0);
      iconColor = const Color(0xFF94A3B8);
      textColor = const Color(0xFF94A3B8);
    }

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 4),
          Text(
            isSkipped ? '$label (skip)' : label,
            style: TextStyle(
              fontSize: 10,
              color: textColor,
              fontWeight: isComplete ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection() {
    final reviewState = _reviewState;
    final projectDetail = _projectDetail;

    if (reviewState == null) return const SizedBox();

    final mentorFeedback = projectDetail?.mentorFeedback;
    final pmFeedback = projectDetail?.pmFeedback;

    final showFeedback = (mentorFeedback != null && mentorFeedback.isNotEmpty) ||
        (pmFeedback != null && pmFeedback.isNotEmpty);

    if (!showFeedback) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.feedback_outlined, size: 18, color: Color(0xFF1E293B)),
              SizedBox(width: 8),
              Text(
                'Phan hoi tu he thong',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (mentorFeedback != null && mentorFeedback.isNotEmpty)
            _buildFeedbackItem(
              icon: Icons.school_outlined,
              label: 'Phan hoi tu Mentor',
              feedback: mentorFeedback,
              color: Colors.orange,
            ),
          if (pmFeedback != null && pmFeedback.isNotEmpty)
            _buildFeedbackItem(
              icon: Icons.manage_accounts_outlined,
              label: 'Phan hoi tu PM',
              feedback: pmFeedback,
              color: Colors.red,
            ),
        ],
      ),
    );
  }

  Widget _buildFeedbackItem({
    required IconData icon,
    required String label,
    required String feedback,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feedback,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSummary() {
    final summary = _dashboard?.summary;
    if (summary == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tien do tong quan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildProgressCard(
                '${summary.totalMembers}',
                'Thanh vien',
                const Color(0xFF137FEC),
              ),
              const SizedBox(width: 12),
              _buildProgressCard(
                '${summary.completedMembers}',
                'Da hoan thanh',
                const Color(0xFF22C55E),
              ),
              const SizedBox(width: 12),
              _buildProgressCard(
                '${summary.inProgressMembers}',
                'Dang hoc',
                const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 12),
              _buildProgressCard(
                '${summary.avgProgress.toStringAsFixed(0)}%',
                'Tien do TB',
                const Color(0xFF8B5CF6),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersProgress() {
    if (_membersProgress.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tien do thanh vien',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          ...(_membersProgress.take(5).map((member) => _buildMemberItem(member))),
        ],
      ),
    );
  }

  Widget _buildMemberItem(MemberProgressData member) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF137FEC).withValues(alpha: 0.1),
            child: Text(
              member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Color(0xFF137FEC),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: member.progressPercent / 100,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getStatusColorFromString(member.status),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${member.completedCourses}/${member.totalCourses}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitSection() {
    final reviewState = _reviewState;

    if (reviewState == null) return const SizedBox();

    if (reviewState.pmApproved) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF22C55E).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF22C55E)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Da hoan thanh - Du an da duoc PM xac nhan',
                style: TextStyle(
                  color: Color(0xFF22C55E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (reviewState.mentorApproved && reviewState.submitted) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.hourglass_empty, color: Color(0xFF3B82F6)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Da duyet boi Mentor - Dang cho PM xac nhan',
                style: TextStyle(
                  color: Color(0xFF3B82F6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (reviewState.submitted) {
      final isWaiting = reviewState.hasMentor && !reviewState.mentorApproved;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isWaiting
              ? Colors.orange.withValues(alpha: 0.1)
              : const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isWaiting ? Icons.hourglass_empty : Icons.check_circle,
              color: isWaiting ? Colors.orange : const Color(0xFFF59E0B),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isWaiting
                    ? 'Da nop - Dang cho Mentor duyet'
                    : 'Da nop - Dang cho PM duyet',
                style: TextStyle(
                  color: isWaiting ? Colors.orange.shade800 : const Color(0xFF92400E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber, color: Color(0xFFF59E0B)),
              SizedBox(width: 8),
              Text(
                'Nop du an',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF92400E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _linkController,
            decoration: InputDecoration(
              hintText: 'Nhap link du an (GitHub, Drive...)',
              prefixIcon: const Icon(Icons.link),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitProject,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Nop du an',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.ACTIVE:
        return const Color(0xFF22C55E);
      case ProjectStatus.COMPLETED:
        return const Color(0xFF137FEC);
      case ProjectStatus.INACTIVE:
        return const Color(0xFF94A3B8);
      case ProjectStatus.REVIEW_PENDING:
        return const Color(0xFFF59E0B);
    }
  }

  Color _getStatusColorFromString(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return const Color(0xFF22C55E);
      case 'IN_PROGRESS':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF94A3B8);
    }
  }
}