import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/service/admin/department_management/api_department_management.dart';

class DepartmentLearningPathsTab extends StatefulWidget {
  final int departmentId;
  final Color primaryColor;

  const DepartmentLearningPathsTab({
    super.key,
    required this.departmentId,
    required this.primaryColor,
  });

  @override
  State<DepartmentLearningPathsTab> createState() =>
      _DepartmentLearningPathsTabState();
}

class _DepartmentLearningPathsTabState
    extends State<DepartmentLearningPathsTab> {
  final DepartmentService _service = DepartmentService();
  List<Map<String, dynamic>> _learningPaths = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLearningPaths();
  }

  Future<void> _loadLearningPaths() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final paths =
          await _service.getDepartmentLearningPaths(widget.departmentId);
      setState(() {
        _learningPaths = paths;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải danh sách Learning Path';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoading();
    }

    if (_error != null) {
      return _buildError();
    }

    if (_learningPaths.isEmpty) {
      return _buildEmpty();
    }

    return _buildLearningPathList();
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(0, 24, 24, 24),
      child: Align(
        alignment: Alignment.centerLeft,
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(color: Colors.red[600]),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _loadLearningPaths,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.route_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có Learning Path nào',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Phòng ban này chưa được gán Learning Path nào.',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningPathList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _learningPaths.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final path = _learningPaths[index];
        return _LearningPathCard(
          path: path,
          primaryColor: widget.primaryColor,
          onTap: () {
            final pathId = path['id']?.toString();
            if (pathId != null) {
              context.push('/pm/learning_path?pathId=$pathId');
            }
          },
        );
      },
    );
  }
}

class _LearningPathCard extends StatefulWidget {
  final Map<String, dynamic> path;
  final Color primaryColor;
  final VoidCallback onTap;

  const _LearningPathCard({
    required this.path,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  State<_LearningPathCard> createState() => _LearningPathCardState();
}

class _LearningPathCardState extends State<_LearningPathCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final title = widget.path['title'] ?? widget.path['name'] ?? 'Learning Path';
    final description = widget.path['description'] ?? '';
    final courseCount = widget.path['courseCount'] ?? 0;
    final progress = (widget.path['progress'] ??
            widget.path['progressPercent'] ??
            0)
        .toDouble();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered
                  ? widget.primaryColor.withValues(alpha: 0.3)
                  : const Color(0xFFE5E7EB),
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? widget.primaryColor.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: _isHovered ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.primaryColor.withValues(alpha: 0.15),
                      widget.primaryColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.route,
                  color: widget.primaryColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 14,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$courseCount khóa học',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        if (progress > 0) ...[
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 80,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                minHeight: 6,
                                value: progress / 100,
                                backgroundColor: const Color(0xFFE5E7EB),
                                color: widget.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${progress.toInt()}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Arrow
              Icon(
                Icons.chevron_right,
                color: _isHovered ? widget.primaryColor : Colors.grey[300],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
