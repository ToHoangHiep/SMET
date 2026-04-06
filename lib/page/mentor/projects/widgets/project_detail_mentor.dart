import 'package:flutter/material.dart';
import 'package:smet/model/project_model.dart';
import 'package:smet/service/mentor/mentor_project_service.dart';
import 'dart:developer';

class MentorProjectDetailDialog extends StatefulWidget {
  final ProjectModel project;
  final VoidCallback onRefresh;

  const MentorProjectDetailDialog({
    super.key,
    required this.project,
    required this.onRefresh,
  });

  @override
  State<MentorProjectDetailDialog> createState() => _MentorProjectDetailDialogState();
}

class _MentorProjectDetailDialogState extends State<MentorProjectDetailDialog> {
  ProjectDashboardData? _dashboard;
  ProjectReviewStateData? _reviewState;
  List<MemberProgressData> _membersProgress = [];
  bool _isLoading = true;
  bool _isApproving = false;
  bool _isRejecting = false;
  bool _isApprovingPM = false;
  bool _isRejectingPM = false;
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
      final results = await Future.wait([
        MentorProjectService.getDashboard(widget.project.id),
        MentorProjectService.getReviewState(widget.project.id),
        MentorProjectService.getMembersProgress(widget.project.id),
      ]);

      if (mounted) {
        setState(() {
          _dashboard = results[0] as ProjectDashboardData;
          _reviewState = results[1] as ProjectReviewStateData;
          _membersProgress = results[2] as List<MemberProgressData>;
          _isLoading = false;
        });
      }
    } catch (e) {
      log('MentorProjectDetailDialog._loadData failed: $e');
      if (mounted) {
        setState(() {
          _error = 'Khong the tai du lieu';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _approveProject() async {
    setState(() => _isApproving = true);

    try {
      await MentorProjectService.approveByMentor(widget.project.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Duyet du an thanh cong!')),
        );
        widget.onRefresh();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loi: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isApproving = false);
      }
    }
  }

  Future<void> _rejectProject() async {
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tu choi du an'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Ly do tu choi',
            hintText: 'Nhap ly do...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Huy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui long nhap ly do')),
                );
                return;
              }
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tu choi'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() => _isRejecting = true);

      try {
        await MentorProjectService.rejectByMentor(
          widget.project.id,
          reasonController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tu choi du an thanh cong!')),
          );
          widget.onRefresh();
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Loi: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isRejecting = false);
        }
      }
    }
  }

  Future<void> _approveByPM() async {
    setState(() => _isApprovingPM = true);

    try {
      await MentorProjectService.approveByPM(widget.project.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PM duyet du an thanh cong!')),
        );
        widget.onRefresh();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loi: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isApprovingPM = false);
      }
    }
  }

  Future<void> _rejectByPM() async {
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PM tu choi du an'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Ly do tu choi',
            hintText: 'Nhap ly do...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Huy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui long nhap ly do')),
                );
                return;
              }
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tu choi'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() => _isRejectingPM = true);

      try {
        await MentorProjectService.rejectByPM(
          widget.project.id,
          reasonController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PM tu choi du an thanh cong!')),
          );
          widget.onRefresh();
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Loi: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isRejectingPM = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 600 ? 600.0 : screenWidth * 0.9;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: dialogWidth,
        constraints: const BoxConstraints(maxHeight: 700),
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
                              _buildProgressSummary(),
                              const SizedBox(height: 20),
                              _buildMembersProgress(),
                              const SizedBox(height: 20),
                              _buildApprovalSection(),
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
        color: Color(0xFF8B5CF6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.school, color: Colors.white, size: 28),
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
                  'Nguoi huong dan',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
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
          if (widget.project.leaderName != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.project.leaderName!,
                        style: const TextStyle(color: Color(0xFF64748B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
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

  Widget _buildReviewStep(String label, bool isComplete, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: isComplete ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isComplete ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
              fontWeight: isComplete ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
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
                const Color(0xFF8B5CF6),
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
                const Color(0xFF137FEC),
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
          color: color.withOpacity(0.1),
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
            backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.1),
            child: Text(
              member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Color(0xFF8B5CF6),
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

  Widget _buildApprovalSection() {
    final reviewState = _reviewState;

    if (reviewState == null) return const SizedBox();

    // Da hoan thanh - PM da duyet
    if (reviewState.pmApproved) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF22C55E).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF22C55E)),
            SizedBox(width: 12),
            Text(
              'Da hoan thanh - Du an da duoc PM xac nhan',
              style: TextStyle(
                color: Color(0xFF22C55E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Cho PM duyet - hien thi nut PM approve
    if (reviewState.mentorApproved && reviewState.submitted) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3B82F6), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.manage_accounts, color: Color(0xFF3B82F6)),
                SizedBox(width: 8),
                Text(
                  'Cho PM xac nhan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Mentor da duyet. Vui long cho PM xac nhan de hoan thanh du an.',
              style: TextStyle(
                color: Color(0xFF1D4ED8),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isRejectingPM ? null : _rejectByPM,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isRejectingPM
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Tu choi',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isApprovingPM ? null : _approveByPM,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isApprovingPM
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'PM Duyet',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (reviewState.mentorApproved) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF22C55E).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF22C55E)),
            SizedBox(width: 12),
            Text(
              'Da duyet - Cho PM xac nhan',
              style: TextStyle(
                color: Color(0xFF22C55E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (!reviewState.submitted) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF94A3B8).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.hourglass_empty, color: Color(0xFF94A3B8)),
            SizedBox(width: 12),
            Text(
              'Chua co du an nao duoc nop',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
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
              Icon(Icons.pending_actions, color: Color(0xFFF59E0B)),
              SizedBox(width: 8),
              Text(
                'Yeu cau duyet du an',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF92400E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Truong nhom da nop du an. Ban co muon duyet hay tu choi?',
            style: TextStyle(
              color: Color(0xFF92400E),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isRejecting ? null : _rejectProject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isRejecting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Tu choi',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isApproving ? null : _approveProject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isApproving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Duyet',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
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