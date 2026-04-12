import 'package:flutter/material.dart';
import 'package:smet/service/pm/pm_project_service.dart';

/// Card hiển thị dự án cần PM phê duyệt
class PmApprovalCard extends StatelessWidget {
  final PmProjectListItem project;
  final VoidCallback onTap;

  const PmApprovalCard({
    super.key,
    required this.project,
    required this.onTap,
  });

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
        onTap: onTap,
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
                      project.title,
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
              if (project.description != null && project.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    project.description!,
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
                    label: project.leaderName ?? 'N/A',
                    color: Colors.grey[700]!,
                  ),
                  const SizedBox(width: 8),
                  if (project.hasMentor)
                    _buildInfoChip(
                      icon: Icons.school_outlined,
                      label: project.mentorName ?? 'N/A',
                      color: Colors.purple[600]!,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStatusIndicator(
                    icon: Icons.check_circle_outline,
                    label: project.mentorApproved == true ? 'Mentor da duyet' : 'Chua co mentor',
                    isActive: project.mentorApproved == true,
                    hasMentor: project.hasMentor,
                  ),
                  const SizedBox(width: 16),
                  _buildStatusIndicator(
                    icon: Icons.verified_user_outlined,
                    label: 'PM',
                    isActive: project.pmApproved == true,
                    hasMentor: true,
                  ),
                ],
              ),
              if (project.submittedAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Ngay nop: ${_formatDate(project.submittedAt!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
              if (project.submissionLink != null && project.submissionLink!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.link, size: 14, color: primaryColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        project.submissionLink!,
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

    if (project.pmApproved == true) {
      bgColor = Colors.green.shade50;
      textColor = Colors.green[700]!;
      label = 'Da duyet';
    } else if (project.canApproveByPM) {
      bgColor = primaryColor.withValues(alpha: 0.1);
      textColor = primaryColor;
      label = 'San sang duyet';
    } else if (project.currentStage == 'WAITING_MENTOR') {
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
