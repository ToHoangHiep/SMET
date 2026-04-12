import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:smet/page/project_manager/project_review/widgets/approval_status_section.dart';
import 'package:smet/page/project_manager/project_review/widgets/pm_action_buttons.dart';
import 'package:smet/page/project_manager/project_review/widgets/submission_viewer.dart';
import 'package:smet/page/project_manager/widgets/shell/pm_shell.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/service/common/global_notification_service.dart';
import 'package:smet/service/pm/pm_project_service.dart';
import 'package:smet/service/employee/employee_project_service.dart';
import 'dart:developer';

/// Trang chi tiết dự án cho PM - xem thông tin và phê duyệt
class PmProjectReviewDetailPage extends StatefulWidget {
  final int projectId;
  final VoidCallback? onRefresh;

  const PmProjectReviewDetailPage({
    super.key,
    required this.projectId,
    this.onRefresh,
  });

  @override
  State<PmProjectReviewDetailPage> createState() => _PmProjectReviewDetailPageState();
}

class _PmProjectReviewDetailPageState extends State<PmProjectReviewDetailPage> {
  PmProjectDetail? _project;
  ProjectReviewStateData? _reviewState;
  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final detail = await PmProjectService.getProjectDetail(widget.projectId);
      final reviewState = await PmProjectService.getReviewState(widget.projectId);

      if (mounted) {
        setState(() {
          _project = detail;
          _reviewState = reviewState;
          _isLoading = false;
        });
      }
    } catch (e) {
      log('PmProjectReviewDetailPage._loadData failed: $e');
      if (mounted) {
        setState(() {
          _error = 'Không thể tải chi tiết dự án';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleApprove() async {
    setState(() => _isActionLoading = true);

    try {
      await PmProjectService.approveByPM(widget.projectId);
      if (mounted) {
        GlobalNotificationService.show(
          context: context,
          message: 'Phê duyệt dự án thành công',
          type: NotificationType.success,
        );
        widget.onRefresh?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        GlobalNotificationService.show(
          context: context,
          message: 'Lỗi: ${e.toString().replaceAll('Exception: ', '')}',
          type: NotificationType.error,
        );
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _handleReject(String reason) async {
    setState(() => _isActionLoading = true);

    try {
      await PmProjectService.rejectByPM(widget.projectId, reason);
      if (mounted) {
        GlobalNotificationService.show(
          context: context,
          message: 'Đã từ chối dự án',
          type: NotificationType.success,
        );
        widget.onRefresh?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        GlobalNotificationService.show(
          context: context,
          message: 'Lỗi: ${e.toString().replaceAll('Exception: ', '')}',
          type: NotificationType.error,
        );
        setState(() => _isActionLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb || MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Chi tiết dự án'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildContent(isWeb),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error ?? 'Đã xảy ra lỗi'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isWeb) {
    final project = _project!;

    if (isWeb) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBreadcrumb(),
                const SizedBox(height: 16),
                _buildMainContent(project),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBreadcrumb(),
          const SizedBox(height: 16),
          _buildMainContent(project),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return SharedBreadcrumb(
      items: [
        BreadcrumbItem(label: 'Trang chủ', route: '/pm/dashboard'),
        BreadcrumbItem(label: 'Duyệt dự án', route: '/pm/project-reviews'),
        BreadcrumbItem(label: _project?.title ?? 'Chi tiết'),
      ],
    );
  }

  Widget _buildMainContent(PmProjectDetail project) {
    final canApprove = project.canApproveByPM;

    if (kIsWeb || MediaQuery.of(context).size.width >= 900) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProjectInfoCard(project),
                const SizedBox(height: 16),
                SubmissionViewer(submissionLink: project.submissionLink),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_reviewState != null)
                  ApprovalStatusSection(
                    reviewState: _reviewState!,
                    mentorFeedback: project.mentorFeedback,
                    pmFeedback: project.pmFeedback,
                    mentorApprovedAt: project.mentorApprovedAt,
                    pmApprovedAt: project.pmApprovedAt,
                  ),
                const SizedBox(height: 16),
                _buildActionSection(project, canApprove),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProjectInfoCard(project),
        const SizedBox(height: 16),
        if (_reviewState != null)
          ApprovalStatusSection(
            reviewState: _reviewState!,
            mentorFeedback: project.mentorFeedback,
            pmFeedback: project.pmFeedback,
            mentorApprovedAt: project.mentorApprovedAt,
            pmApprovedAt: project.pmApprovedAt,
          ),
        const SizedBox(height: 16),
        SubmissionViewer(submissionLink: project.submissionLink),
        const SizedBox(height: 16),
        _buildActionSection(project, canApprove),
      ],
    );
  }

  Widget _buildProjectInfoCard(PmProjectDetail project) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  project.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildStatusChip(project),
            ],
          ),
          const SizedBox(height: 12),
          if (project.description != null && project.description!.isNotEmpty) ...[
            Text(
              project.description!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Divider(),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.person_outline,
            label: 'Nhóm trưởng',
            value: project.leaderName ?? 'N/A',
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            icon: Icons.school_outlined,
            label: 'Mentor',
            value: project.hasMentor ? (project.mentorName ?? 'N/A') : 'Không có',
            valueColor: project.hasMentor ? null : Colors.grey[400],
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            icon: Icons.group_outlined,
            label: 'Thành viên',
            value: project.memberNames != null && project.memberNames!.isNotEmpty
                ? project.memberNames!.join(', ')
                : 'N/A',
          ),
          if (project.submittedAt != null) ...[
            const SizedBox(height: 10),
            _buildInfoRow(
              icon: Icons.schedule,
              label: 'Ngày nộp',
              value: _formatDateTime(project.submittedAt!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[500]),
        const SizedBox(width: 10),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor ?? Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(PmProjectDetail project) {
    Color bgColor;
    Color textColor;
    String label;

    if (project.pmApproved) {
      bgColor = Colors.green.shade50;
      textColor = Colors.green[700]!;
      label = 'Đã duyệt';
    } else if (project.canApproveByPM) {
      bgColor = PmShell.pmPrimaryColor.withValues(alpha: 0.1);
      textColor = PmShell.pmPrimaryColor;
      label = 'Sẵn sàng duyệt';
    } else if (project.currentStage == 'WAITING_MENTOR') {
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange[700]!;
      label = 'Chờ Mentor';
    } else {
      bgColor = Colors.grey.shade100;
      textColor = Colors.grey[600]!;
      label = project.currentStageLabel;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildActionSection(PmProjectDetail project, bool canApprove) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hành động',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          PmActionButtons(
            canApprove: canApprove,
            currentStage: project.currentStage,
            onApprove: _handleApprove,
            onReject: _handleReject,
            isLoading: _isActionLoading,
          ),
          if (!canApprove && project.currentStage == 'WAITING_MENTOR') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dự án này cần được Mentor phê duyệt trước.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (project.hasMentor && project.mentorApprovedAt != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 18, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mentor đã phê duyệt vào ${_formatDateTime(project.mentorApprovedAt!)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
