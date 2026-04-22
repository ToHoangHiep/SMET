import 'package:flutter/material.dart';
import 'package:smet/model/project_model.dart';
import 'package:smet/service/employee/employee_project_service.dart';
import 'package:smet/service/common/auth_service.dart';
import 'dart:developer';

class ProjectDetailMemberDialog extends StatefulWidget {
  final ProjectModel project;

  const ProjectDetailMemberDialog({
    super.key,
    required this.project,
  });

  @override
  State<ProjectDetailMemberDialog> createState() => _ProjectDetailMemberDialogState();
}

class _ProjectDetailMemberDialogState extends State<ProjectDetailMemberDialog> {
  List<ProjectAssignmentData> _assignments = [];
  MemberProgressData? _myProgress;
  bool _isLoading = true;
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
        EmployeeProjectService.getDashboard(widget.project.id),
        EmployeeProjectService.getReviewState(widget.project.id),
        EmployeeProjectService.getAssignments(widget.project.id),
      ]);

      final dashboard = results[0] as ProjectDashboardData;
      final userId = (await AuthService.getCurrentUser()).id;

      MemberProgressData? myProgress;
      for (final member in dashboard.members) {
        if (member.userId == userId) {
          myProgress = member;
          break;
        }
      }

      if (mounted) {
        setState(() {
          _assignments = results[2] as List<ProjectAssignmentData>;
          _myProgress = myProgress;
          _isLoading = false;
        });
      }
    } catch (e) {
      log('ProjectDetailMemberDialog._loadData failed: $e');
      if (mounted) {
        setState(() {
          _error = 'Khong the tai du lieu';
          _isLoading = false;
        });
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
                              _buildMyProgress(),
                              const SizedBox(height: 20),
                              _buildMyAssignments(),
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
          const Icon(Icons.person, color: Colors.white, size: 28),
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
                  'Thanh vien',
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
                    Text(
                      widget.project.leaderName!,
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMyProgress() {
    final myProgress = _myProgress;

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
            'Tien do cua toi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          if (myProgress != null) ...[
            Row(
              children: [
                _buildProgressCard(
                  '${myProgress.completedCourses}',
                  'Khoa hoc\nhoan thanh',
                  const Color(0xFF22C55E),
                ),
                const SizedBox(width: 12),
                _buildProgressCard(
                  '${myProgress.totalCourses}',
                  'Tong so\nkhoa hoc',
                  const Color(0xFF137FEC),
                ),
                const SizedBox(width: 12),
                _buildProgressCard(
                  '${myProgress.progressPercent}%',
                  'Tien do\nhoan thanh',
                  const Color(0xFF8B5CF6),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: myProgress.progressPercent / 100,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ] else
            const Center(
              child: Text(
                'Chua co tien do hoc tap',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
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

  Widget _buildMyAssignments() {
    if (_assignments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text(
            'Chua co bai tap nao duoc assign',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ),
      );
    }

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
              Icon(Icons.assignment, size: 20, color: Color(0xFF64748B)),
              SizedBox(width: 8),
              Text(
                'Bai tap duoc assign',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_assignments.take(5).map((assignment) => _buildAssignmentItem(assignment))),
        ],
      ),
    );
  }

  Widget _buildAssignmentItem(ProjectAssignmentData assignment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.book, size: 16, color: Color(0xFF137FEC)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    assignment.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Text(
                  '${assignment.completedCourses}/${assignment.totalCourses}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            if (assignment.courses.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: assignment.courses.take(3).map((course) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF137FEC).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 12,
                          color: Color(0xFF137FEC),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          course.title,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF137FEC),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
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
}