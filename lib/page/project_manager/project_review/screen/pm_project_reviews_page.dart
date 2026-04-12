import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/project_manager/project_review/screen/pm_project_review_detail_page.dart';
import 'package:smet/page/project_manager/project_review/widgets/pm_approval_card.dart';
import 'package:smet/page/project_manager/widgets/shell/pm_shell.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/service/pm/pm_project_service.dart';
import 'package:smet/model/project_model.dart';
import 'dart:developer';

/// Trang danh sách dự án cần PM phê duyệt
class PmProjectReviewsPage extends StatefulWidget {
  const PmProjectReviewsPage({super.key});

  @override
  State<PmProjectReviewsPage> createState() => _PmProjectReviewsPageState();
}

class _PmProjectReviewsPageState extends State<PmProjectReviewsPage> {
  List<PmProjectListItem> _projects = [];
  bool _isLoading = true;
  String? _error;
  String _searchKeyword = '';
  String? _filterStatus;
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects({int page = 0}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await PmProjectService.getProjectsForReview(
        page: page,
        size: _pageSize,
        keyword: _searchKeyword.isNotEmpty ? _searchKeyword : null,
        status: _filterStatus,
      );

      if (mounted) {
        setState(() {
          _projects = response.content;
          _currentPage = response.page;
          _totalPages = response.totalPages;
          _totalElements = response.totalElements;
          _isLoading = false;
        });
      }
    } catch (e) {
      log('PmProjectReviewsPage._loadProjects failed: $e');
      if (mounted) {
        setState(() {
          _error = 'Không thể tải danh sách dự án';
          _isLoading = false;
        });
      }
    }
  }

  List<PmProjectListItem> get _filteredProjects {
    if (_searchKeyword.isEmpty) return _projects;

    return _projects.where((p) {
      return p.title.toLowerCase().contains(_searchKeyword.toLowerCase()) ||
          (p.description?.toLowerCase().contains(_searchKeyword.toLowerCase()) ?? false) ||
          (p.leaderName?.toLowerCase().contains(_searchKeyword.toLowerCase()) ?? false) ||
          (p.mentorName?.toLowerCase().contains(_searchKeyword.toLowerCase()) ?? false);
    }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchKeyword = value;
    });
    _loadProjects(page: 0);
  }

  void _onStatusFilterChanged(String? status) {
    setState(() {
      _filterStatus = status;
    });
    _loadProjects(page: 0);
  }

  void _onProjectTap(PmProjectListItem project) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PmProjectReviewDetailPage(
          projectId: project.id,
          onRefresh: () => _loadProjects(page: _currentPage),
        ),
      ),
    );
  }

  void _goToPage(int page) {
    if (page < 0 || page >= _totalPages) return;
    _loadProjects(page: page);
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb || MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          SharedBreadcrumb(
            items: [
              BreadcrumbItem(label: 'Trang chủ', route: '/pm/dashboard'),
              const BreadcrumbItem(label: 'Duyệt dự án'),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorState()
                    : _buildContent(isWeb),
          ),
        ],
      ),
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
            onPressed: () => _loadProjects(),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isWeb) {
    if (isWeb) {
      return _buildWebContent();
    }
    return _buildMobileContent();
  }

  Widget _buildWebContent() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sidebar filter
              _buildFilterSidebar(),
              const SizedBox(width: 16),
              // Main content
              Expanded(child: _buildProjectList()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileContent() {
    return Column(
      children: [
        _buildHeader(),
        _buildFilterChips(),
        Expanded(child: _buildProjectList()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Duyệt dự án',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Xem và phê duyệt các dự án đã nộp',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: PmShell.pmPrimaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.pending_actions,
                      size: 16,
                      color: PmShell.pmPrimaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_totalElements dự án',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: PmShell.pmPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo tên, mô tả, nhóm trưởng...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchKeyword.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _onSearchChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: PmShell.pmPrimaryColor),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSidebar() {
    return Container(
      width: 220,
      padding: const EdgeInsets.fromLTRB(24, 0, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trạng thái',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildFilterItem(
            label: 'Tất cả',
            value: null,
            icon: Icons.list,
          ),
          _buildFilterItem(
            label: 'Chờ duyệt',
            value: 'REVIEW_PENDING',
            icon: Icons.hourglass_empty,
          ),
          _buildFilterItem(
            label: 'Hoàn thành',
            value: 'COMPLETED',
            icon: Icons.check_circle,
          ),
          _buildFilterItem(
            label: 'Đang hoạt động',
            value: 'ACTIVE',
            icon: Icons.play_circle_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterItem({
    required String label,
    required String? value,
    required IconData icon,
  }) {
    final isSelected = _filterStatus == value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => _onStatusFilterChanged(value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? PmShell.pmPrimaryColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: PmShell.pmPrimaryColor.withValues(alpha: 0.3))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? PmShell.pmPrimaryColor : Colors.grey[600],
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? PmShell.pmPrimaryColor : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildChipFilterItem(label: 'Tất cả', value: null),
          _buildChipFilterItem(label: 'Chờ duyệt', value: 'REVIEW_PENDING'),
          _buildChipFilterItem(label: 'Hoàn thành', value: 'COMPLETED'),
          _buildChipFilterItem(label: 'Đang hoạt động', value: 'ACTIVE'),
        ],
      ),
    );
  }

  Widget _buildChipFilterItem({required String label, required String? value}) {
    final isSelected = _filterStatus == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _onStatusFilterChanged(value),
        selectedColor: PmShell.pmPrimaryColor.withValues(alpha: 0.15),
        checkmarkColor: PmShell.pmPrimaryColor,
        labelStyle: TextStyle(
          color: isSelected ? PmShell.pmPrimaryColor : Colors.grey[700],
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildProjectList() {
    final projects = _filteredProjects;

    if (projects.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return PmApprovalCard(
                project: project,
                onTap: () => _onProjectTap(project),
              );
            },
          ),
        ),
        if (_totalPages > 1) _buildPagination(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Không có dự án nào cần duyệt',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Danh sách sẽ cập nhật khi có dự án được nộp',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
          ),
          const SizedBox(width: 8),
          Text(
            'Trang ${_currentPage + 1} / $_totalPages',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages - 1
                ? () => _goToPage(_currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }
}
