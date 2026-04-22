import 'package:flutter/material.dart';
import 'package:smet/service/pm/pm_project_service.dart';

/// Hiển thị tiến trình phê duyệt: submitted -> mentor approved -> PM approved
class ApprovalStatusSection extends StatelessWidget {
  final ProjectReviewStateData reviewState;
  final String? mentorFeedback;
  final String? pmFeedback;
  final DateTime? mentorApprovedAt;
  final DateTime? pmApprovedAt;

  const ApprovalStatusSection({
    super.key,
    required this.reviewState,
    this.mentorFeedback,
    this.pmFeedback,
    this.mentorApprovedAt,
    this.pmApprovedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tien trinh phê duyệt',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildTimeline(),
          if (mentorFeedback != null && mentorFeedback!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildFeedbackCard(
              icon: Icons.feedback_outlined,
              label: 'Phan hoi cua Mentor',
              feedback: mentorFeedback!,
              color: Colors.orange,
            ),
          ],
          if (pmFeedback != null && pmFeedback!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildFeedbackCard(
              icon: Icons.feedback_outlined,
              label: 'Phan hoi cua PM',
              feedback: pmFeedback!,
              color: Colors.red,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Row(
      children: [
        // Bước 1: Đã nộp
        _buildStep(
          icon: Icons.upload_file,
          label: 'Da nop',
          isActive: reviewState.submitted,
          isCompleted: reviewState.submitted,
        ),
        _buildConnector(reviewState.submitted),
        // Bước 2: Mentor duyệt
        _buildStep(
          icon: Icons.school_outlined,
          label: 'Mentor duyet',
          isActive: reviewState.submitted && reviewState.hasMentor,
          isCompleted: reviewState.mentorApproved,
          isSkipped: !reviewState.hasMentor,
        ),
        _buildConnector(
          reviewState.mentorApproved ||
          (!reviewState.hasMentor && reviewState.submitted),
        ),
        // Bước 3: PM duyệt
        _buildStep(
          icon: Icons.verified_user_outlined,
          label: 'PM duyet',
          isActive: reviewState.submitted,
          isCompleted: reviewState.pmApproved,
        ),
      ],
    );
  }

  Widget _buildStep({
    required IconData icon,
    required String label,
    required bool isActive,
    required bool isCompleted,
    bool isSkipped = false,
  }) {
    Color circleColor;
    Color iconColor;
    Color textColor;

    if (isCompleted) {
      circleColor = Colors.green;
      iconColor = Colors.white;
      textColor = Colors.green[700]!;
    } else if (isActive) {
      if (isSkipped) {
        circleColor = Colors.grey.shade300;
        iconColor = Colors.grey;
        textColor = Colors.grey[500]!;
      } else {
        circleColor = const Color(0xFF137FEC).withValues(alpha: 0.15);
        iconColor = const Color(0xFF137FEC);
        textColor = const Color(0xFF137FEC);
      }
    } else {
      circleColor = Colors.grey.shade200;
      iconColor = Colors.grey.shade400;
      textColor = Colors.grey[500]!;
    }

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          if (isCompleted && label == 'Mentor duyet' && mentorApprovedAt != null) ...[
            const SizedBox(height: 2),
            Text(
              _formatDate(mentorApprovedAt!),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
          if (isCompleted && label == 'PM duyet' && pmApprovedAt != null) ...[
            const SizedBox(height: 2),
            Text(
              _formatDate(pmApprovedAt!),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConnector(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 28),
        color: isActive ? Colors.green : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildFeedbackCard({
    required IconData icon,
    required String label,
    required String feedback,
    required Color color,
  }) {
    return Container(
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
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
