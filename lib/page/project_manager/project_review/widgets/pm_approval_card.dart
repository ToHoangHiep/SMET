import 'package:flutter/material.dart';
import 'package:smet/service/common/user_service.dart';
import 'package:smet/service/pm/pm_project_service.dart';

/// Card hiển thị dự án cần PM phê duyệt
class PmApprovalCard extends StatefulWidget {
  final PmProjectListItem project;
  final VoidCallback onTap;

  const PmApprovalCard({
    super.key,
    required this.project,
    required this.onTap,
  });

  @override
  State<PmApprovalCard> createState() => _PmApprovalCardState();
}

class _PmApprovalCardState extends State<PmApprovalCard> {
  String? _leaderName;
  String? _mentorName;
  bool _isLoadingNames = false;

  @override
  void initState() {
    super.initState();
    _loadMissingNames();
  }

  @override
  void didUpdateWidget(PmApprovalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project.id != widget.project.id) {
      _loadMissingNames();
    }
  }

  Future<void> _loadMissingNames() async {
    final project = widget.project;
    final needsLeader = project.leaderName == null && project.leaderId > 0;
    final needsLeaderViaSubmitter = project.leaderName == null
        && project.leaderId <= 0
        && project.submittedBy != null;
    final needsMentor = project.hasMentor && project.mentorName == null && project.mentorId != null;

    if (!needsLeader && !needsLeaderViaSubmitter && !needsMentor) return;

    setState(() => _isLoadingNames = true);

    try {
      final results = await Future.wait([
        needsLeader ? _resolveLeaderName(project.leaderId) : Future.value(null),
        needsLeaderViaSubmitter ? _resolveLeaderName(project.submittedBy!) : Future.value(null),
        needsMentor ? _resolveMentorName(project.mentorId!) : Future.value(null),
      ]);

      if (mounted) {
        setState(() {
          _leaderName = (needsLeader ? results[0] : null) ?? (needsLeaderViaSubmitter ? results[1] : null);
          _mentorName = needsMentor ? results[2] : null;
          _isLoadingNames = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingNames = false);
      }
    }
  }

  Future<String?> _resolveLeaderName(int leaderId) async {
    if (leaderId <= 0) return null;
    try {
      final user = await UserService.getUserById(leaderId);
      return user?.fullName;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _resolveMentorName(int mentorId) async {
    if (mentorId <= 0) return null;
    try {
      final user = await UserService.getUserById(mentorId);
      return user?.fullName;
    } catch (_) {
      return null;
    }
  }

  String get _displayLeaderName =>
      widget.project.leaderName ?? _leaderName ?? 'N/A';

  String get _displayMentorName =>
      widget.project.mentorName ?? _mentorName ?? 'N/A';

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF137FEC);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.project.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(context),
                ],
              ),
              const SizedBox(height: 8),
              if (widget.project.description != null && widget.project.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    widget.project.description!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.person_outline,
                    label: _isLoadingNames && widget.project.leaderName == null
                        ? '...'
                        : _displayLeaderName,
                    color: Colors.grey[700]!,
                  ),
                  const SizedBox(width: 8),
                  if (widget.project.hasMentor)
                    _buildInfoChip(
                      icon: Icons.school_outlined,
                      label: _isLoadingNames && widget.project.mentorName == null
                          ? '...'
                          : _displayMentorName,
                      color: Colors.purple[600]!,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStatusIndicator(
                    icon: Icons.check_circle_outline,
                    label: widget.project.mentorApproved == true
                        ? 'Mentor da duyet'
                        : 'Chua co mentor',
                    isActive: widget.project.mentorApproved == true,
                    hasMentor: widget.project.hasMentor,
                  ),
                  const SizedBox(width: 16),
                  _buildStatusIndicator(
                    icon: Icons.verified_user_outlined,
                    label: 'PM',
                    isActive: widget.project.pmApproved == true,
                    hasMentor: true,
                  ),
                ],
              ),
              if (widget.project.submittedAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Ngay nop: ${_formatDate(widget.project.submittedAt!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
              if (widget.project.submissionLink != null && widget.project.submissionLink!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.link, size: 14, color: primaryColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.project.submissionLink!,
                        style: TextStyle(
                          fontSize: 12,
                          color: primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final primaryColor = const Color(0xFF137FEC);

    Color bgColor;
    Color textColor;
    String label;

    if (widget.project.pmApproved == true) {
      bgColor = Colors.green.shade50;
      textColor = Colors.green[700]!;
      label = 'Da duyet';
    } else if (widget.project.canApproveByPM) {
      bgColor = primaryColor.withValues(alpha: 0.1);
      textColor = primaryColor;
      label = 'San sang duyet';
    } else if (widget.project.currentStage == 'WAITING_MENTOR') {
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange[700]!;
      label = 'Cho mentor';
    } else {
      bgColor = Colors.grey.shade100;
      textColor = Colors.grey[600]!;
      label = 'Cho PM';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator({
    required IconData icon,
    required String label,
    required bool isActive,
    required bool hasMentor,
  }) {
    Color activeColor = Colors.grey[400]!;
    if (isActive) {
      activeColor = Colors.green;
    } else if (hasMentor && label == 'Mentor da duyet') {
      activeColor = Colors.orange;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: activeColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: activeColor,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
