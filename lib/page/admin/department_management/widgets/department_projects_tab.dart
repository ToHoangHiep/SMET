import 'package:flutter/material.dart';
import 'package:smet/model/project_model.dart';
import 'package:smet/service/project/project_service.dart';
import 'dart:developer';

class DepartmentProjectsTab extends StatefulWidget {
  final int departmentId;
  final Color primaryColor;

  const DepartmentProjectsTab({
    super.key,
    required this.departmentId,
    required this.primaryColor,
  });

  @override
  State<DepartmentProjectsTab> createState() => _DepartmentProjectsTabState();
}

class _DepartmentProjectsTabState extends State<DepartmentProjectsTab> {
  final TextEditingController _searchController = TextEditingController();

  List<ProjectModel> _projects = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;

  String _searchQuery = '';
  ProjectStatus? _selectedStatus;
  int _currentPage = 0;
  int _totalPages = 1;
  int _totalElements = 0;
  static const int _pageSize = 12;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects({bool loadMore = false}) async {
    if (loadMore) {
      if (_isLoadingMore || _currentPage >= _totalPages - 1) return;
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentPage = 0;
      });
    }

    try {
      final result = await ProjectService.getAll(
        departmentId: widget.departmentId,
        keyword: _searchQuery.isEmpty ? null : _searchQuery,
        status: _selectedStatus?.name,
        page: loadMore ? _currentPage + 1 : 0,
        size: _pageSize,
      );

      if (mounted) {
        setState(() {
          if (loadMore) {
            _projects.addAll(result.projects);
            _isLoadingMore = false;
          } else {
            _projects = result.projects;
            _isLoading = false;
          }
          _currentPage = loadMore ? _currentPage + 1 : 0;
          _totalPages = result.totalPages;
          _totalElements = result.totalElements;
        });
      }
    } catch (e) {
      log('DepartmentProjectsTab _loadProjects: $e');
      if (mounted) {
        setState(() {
          _error = 'Không thể tải danh sách dự án';
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onSearch(String value) {
    setState(() => _searchQuery = value);
    _loadProjects();
  }

  void _onStatusFilterChanged(ProjectStatus? status) {
    setState(() => _selectedStatus = status);
    _loadProjects();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(0, 24, 24, 24),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Colors.red[600])),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadProjects, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    return _buildProjectsLayout();
  }

  Widget _buildProjectsLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryRow(),
        const SizedBox(height: 16),
        _buildSearchAndFilter(),
        const SizedBox(height: 16),
        Expanded(
          child: _projects.isEmpty ? _buildEmpty() : _buildProjectsGrid(),
        ),
        if (_projects.isNotEmpty) _buildPagination(),
      ],
    );
  }

  Widget _buildSummaryRow() {
    final activeCount = _projects.where((p) => p.status == ProjectStatus.ACTIVE).length;
    final pendingCount = _projects.where((p) => p.status == ProjectStatus.REVIEW_PENDING).length;
    final completedCount = _projects.where((p) => p.status == ProjectStatus.COMPLETED).length;
    final inactiveCount = _projects.where((p) => p.status == ProjectStatus.INACTIVE).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: widget.primaryColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.folder_special, size: 18, color: widget.primaryColor),
          const SizedBox(width: 8),
          Text('Tổng cộng: ', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Text(
            '$_totalElements dự án',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: widget.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          if (inactiveCount > 0) ...[
            _buildStatusChip('Không hoạt động', inactiveCount, Colors.grey),
            const SizedBox(width: 8),
          ],
          if (activeCount > 0) ...[
            _buildStatusChip('Đang hoạt động', activeCount, Colors.green),
            const SizedBox(width: 8),
          ],
          if (pendingCount > 0) ...[
            _buildStatusChip('Chờ duyệt', pendingCount, Colors.orange),
            const SizedBox(width: 8),
          ],
          if (completedCount > 0) ...[
            _buildStatusChip('Hoàn thành', completedCount, Colors.blue),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        SizedBox(
          width: 300,
          child: TextField(
            controller: _searchController,
            onChanged: _onSearch,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm dự án...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded, color: Colors.grey[400], size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _onSearch('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: widget.primaryColor, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ProjectStatus?>(
              value: _selectedStatus,
              hint: Text('Tất cả trạng thái', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              items: [
                const DropdownMenuItem<ProjectStatus?>(value: null, child: Text('Tất cả trạng thái')),
                const DropdownMenuItem<ProjectStatus?>(value: ProjectStatus.ACTIVE, child: Text('Đang hoạt động')),
                const DropdownMenuItem<ProjectStatus?>(value: ProjectStatus.REVIEW_PENDING, child: Text('Chờ duyệt')),
                const DropdownMenuItem<ProjectStatus?>(value: ProjectStatus.COMPLETED, child: Text('Hoàn thành')),
                const DropdownMenuItem<ProjectStatus?>(value: ProjectStatus.INACTIVE, child: Text('Không hoạt động')),
              ],
              onChanged: _onStatusFilterChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy dự án',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedStatus != null
                ? 'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm'
                : 'Phòng ban này chưa có dự án nào được tạo.',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 3 : constraints.maxWidth > 500 ? 2 : 1;

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.8,
          ),
          itemCount: _projects.length + (_isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= _projects.length) {
              return const Center(child: CircularProgressIndicator());
            }
            final project = _projects[index];
            return _ProjectCard(project: project, primaryColor: widget.primaryColor);
          },
        );
      },
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 0 ? () => _loadProjects() : null,
            icon: const Icon(Icons.chevron_left),
            color: widget.primaryColor,
            disabledColor: Colors.grey[300],
          ),
          const SizedBox(width: 8),
          Text(
            'Trang ${_currentPage + 1} / $_totalPages',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(width: 8),
          if (_isLoadingMore)
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
          else
            IconButton(
              onPressed: _currentPage < _totalPages - 1 ? () => _loadProjects(loadMore: true) : null,
              icon: const Icon(Icons.chevron_right),
              color: widget.primaryColor,
              disabledColor: Colors.grey[300],
            ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatefulWidget {
  final ProjectModel project;
  final Color primaryColor;

  const _ProjectCard({required this.project, required this.primaryColor});

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  bool _isHovered = false;

  Color _statusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.INACTIVE:
        return Colors.grey;
      case ProjectStatus.ACTIVE:
        return Colors.green;
      case ProjectStatus.REVIEW_PENDING:
        return Colors.orange;
      case ProjectStatus.COMPLETED:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(widget.project.status);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isHovered ? widget.primaryColor.withValues(alpha: 0.35) : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? widget.primaryColor.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: _isHovered ? 14 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.primaryColor.withValues(alpha: 0.15),
                        widget.primaryColor.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: widget.primaryColor.withValues(alpha: 0.2)),
                  ),
                  child: Center(
                    child: Icon(Icons.work_outline, color: widget.primaryColor, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.project.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.project.description ?? 'Không có mô tả',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.project.status.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
