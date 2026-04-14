import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smet/model/report_model.dart';
import 'package:smet/model/user_model.dart';
import 'package:smet/page/report/shared/report_badges.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/service/mentor/course_service.dart';
import 'package:smet/service/project/project_service.dart';
import 'package:smet/service/report/report_service.dart';

final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

// ================================================================
// REPORT LIST SCREEN (BASE)
// Unified for all roles: ADMIN, MENTOR, PM, USER
// ================================================================

class ReportListScreen extends StatefulWidget {
  final UserRole currentRole;
  final Color primaryColor;
  final String rolePrefix;
  final int currentUserId;

  const ReportListScreen({
    super.key,
    required this.currentRole,
    required this.primaryColor,
    required this.rolePrefix,
    required this.currentUserId,
  });

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  final _svc = reportService;

  // Pagination
  int _page = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  static const int _pageSize = 10;

  // Filters
  ReportType? _selectedType;
  ReportStatus? _selectedStatus;
  DateTimeRange? _dateRange;
  bool _isLoading = true;
  String? _error;

  List<ReportResponse> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = widget.currentRole == UserRole.ADMIN
          ? await _svc.listAdminReports(
              type: _selectedType,
              status: _selectedStatus,
              fromDate: _dateRange?.start,
              toDate: _dateRange?.end,
              page: _page,
              size: _pageSize,
            )
          : await _svc.listReports(
              type: _selectedType,
              status: _selectedStatus,
              fromDate: _dateRange?.start,
              toDate: _dateRange?.end,
              page: _page,
              size: _pageSize,
            );

      if (!mounted) return;

      setState(() {
        _reports = result.data;
        _totalPages = result.totalPages;
        _totalElements = result.totalElements;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedType = null;
      _selectedStatus = null;
      _dateRange = null;
      _page = 0;
    });
    _loadReports();
  }

  Future<void> _onDeleteReport(ReportResponse report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa báo cáo'),
        content: Text(
          'Bạn có chắc chắn muốn xóa báo cáo #${report.id}?\nHành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _svc.deleteDraftReport(report.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa báo cáo thành công!')),
      );
      _loadReports();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _onFilterChanged() {
    _page = 0;
    _loadReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(30, 30, 30, 0),
              child: BreadcrumbPageHeader(
                pageTitle: 'Danh sách Báo cáo',
                pageIcon: Icons.assessment_rounded,
                breadcrumbs: [
                  BreadcrumbItem(
                    label: 'Tổng quan',
                    route: _roleRoute(),
                  ),
                  const BreadcrumbItem(label: 'Báo cáo'),
                ],
                primaryColor: widget.primaryColor,
                actions: [
                  _buildGenerateButton(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _FilterBar(
                        primaryColor: widget.primaryColor,
                        currentRole: widget.currentRole,
                        selectedType: _selectedType,
                        selectedStatus: _selectedStatus,
                        dateRange: _dateRange,
                        onTypeChanged: (v) {
                          setState(() => _selectedType = v);
                          _onFilterChanged();
                        },
                        onStatusChanged: (v) {
                          setState(() => _selectedStatus = v);
                          _onFilterChanged();
                        },
                        onDateRangeChanged: (v) {
                          setState(() => _dateRange = v);
                          _onFilterChanged();
                        },
                        onReset: _resetFilters,
                      ),
                      const SizedBox(height: 24),
                      _buildContent(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return ElevatedButton.icon(
      onPressed: () => _showGenerateDialog(),
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text('Tạo báo cáo', style: TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return _ErrorCard(
        message: _error!,
        onRetry: _loadReports,
      );
    }

    if (_reports.isEmpty) {
      return _EmptyState(
        primaryColor: widget.primaryColor,
        onReset: _resetFilters,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ResultInfo(
          total: _totalElements,
          showing: _reports.length,
          primaryColor: widget.primaryColor,
        ),
        const SizedBox(height: 16),
        _ReportTable(
          reports: _reports,
          primaryColor: widget.primaryColor,
          rolePrefix: widget.rolePrefix,
          currentRole: widget.currentRole,
          currentUserId: widget.currentUserId,
          onView: (r) {
            final detailRoute = switch (widget.currentRole) {
              UserRole.ADMIN => '/admin/report/${r.id}',
              UserRole.MENTOR => '/mentor/report/${r.id}',
              UserRole.PROJECT_MANAGER => '/reports/${r.id}',
              UserRole.USER => '/report/${r.id}',
            };
            context.go(detailRoute);
          },
          onDelete: (r) => _onDeleteReport(r),
        ),
        const SizedBox(height: 24),
        _PaginationBar(
          page: _page,
          totalPages: _totalPages,
          onPageChanged: (p) {
            setState(() => _page = p);
            _loadReports();
          },
        ),
      ],
    );
  }

  String _roleRoute([String? suffix]) {
    switch (widget.currentRole) {
      case UserRole.ADMIN:
        return suffix == 'report' ? '/admin/reports' : '/user_management';
      case UserRole.PROJECT_MANAGER:
        return suffix == 'report' ? '/reports' : '/pm/dashboard';
      case UserRole.MENTOR:
        return suffix == 'report' ? '/mentor/reports' : '/mentor/dashboard';
      case UserRole.USER:
        return suffix == 'report' ? '/reports' : '/employee/dashboard';
    }
  }

  void _showGenerateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _GenerateReportDialog(
        primaryColor: widget.primaryColor,
        currentRole: widget.currentRole,
        onGenerated: (type, scopeId) async {
          Navigator.of(ctx).pop();
          try {
            final report = await _svc.generateReport(type: type, scopeId: scopeId);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tạo báo cáo thành công!')),
            );
            _loadReports();
            final detailRoute = switch (widget.currentRole) {
              UserRole.ADMIN => '/admin/report/${report.id}',
              UserRole.MENTOR => '/mentor/report/${report.id}',
              UserRole.PROJECT_MANAGER => '/report/${report.id}',
              UserRole.USER => '/report/${report.id}',
            };
            context.go(detailRoute);
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi: $e')),
            );
          }
        },
      ),
    );
  }
}

// ================================================================
// FILTER BAR
// ================================================================

class _FilterBar extends StatelessWidget {
  final Color primaryColor;
  final ReportType? selectedType;
  final ReportStatus? selectedStatus;
  final DateTimeRange? dateRange;
  final UserRole currentRole;
  final ValueChanged<ReportType?> onTypeChanged;
  final ValueChanged<ReportStatus?> onStatusChanged;
  final ValueChanged<DateTimeRange?> onDateRangeChanged;
  final VoidCallback onReset;

  const _FilterBar({
    required this.primaryColor,
    required this.selectedType,
    required this.selectedStatus,
    required this.dateRange,
    required this.currentRole,
    required this.onTypeChanged,
    required this.onStatusChanged,
    required this.onDateRangeChanged,
    required this.onReset,
  });

  List<ReportType> get _availableTypes {
    switch (currentRole) {
      case UserRole.ADMIN:
        return ReportType.values;
      case UserRole.MENTOR:
        return [ReportType.MENTOR_WEEKLY, ReportType.MENTOR_MONTHLY];
      case UserRole.PROJECT_MANAGER:
        return [ReportType.PM_WEEKLY, ReportType.PM_MONTHLY];
      case UserRole.USER:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _typeDropdown()),
          const SizedBox(width: 16),
          Expanded(child: _statusDropdown()),
          const SizedBox(width: 16),
          Expanded(child: _dateRangePicker(context)),
          const SizedBox(width: 16),
          _resetButton(),
        ],
      ),
    );
  }

  Widget _typeDropdown() {
    final types = _availableTypes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Loại báo cáo',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<ReportType>(
          value: selectedType,
          decoration: _inputDecoration(),
          hint: const Text('Tất cả loại', style: TextStyle(fontSize: 14)),
          isExpanded: true,
          items: [
            const DropdownMenuItem(value: null, child: Text('Tất cả loại')),
            ...types.map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t.shortName, style: const TextStyle(fontSize: 14)),
                )),
          ],
          onChanged: onTypeChanged,
        ),
      ],
    );
  }

  Widget _statusDropdown() {
    // ADMIN: backend hard-codes status=SUBMITTED, so filter is disabled
    if (currentRole == UserRole.ADMIN) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trạng thái',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Chỉ hiển thị báo cáo đã gửi',
                    style: TextStyle(fontSize: 14, color: Color(0xFF717785)),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trạng thái',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<ReportStatus>(
          value: selectedStatus,
          decoration: _inputDecoration(),
          hint: const Text('Tất cả trạng thái', style: TextStyle(fontSize: 14)),
          isExpanded: true,
          items: [
            const DropdownMenuItem(value: null, child: Text('Tất cả trạng thái')),
            ...ReportStatus.values.map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s.displayName, style: const TextStyle(fontSize: 14)),
                )),
          ],
          onChanged: onStatusChanged,
        ),
      ],
    );
  }

  Widget _dateRangePicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Khoảng ngày',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final range = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              initialDateRange: dateRange,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: primaryColor,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (range != null) {
              onDateRangeChanged(range);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Icon(Icons.date_range_rounded, size: 18, color: primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dateRange == null
                        ? 'Tất cả thời gian'
                        : '${_fmt(dateRange!.start)} - ${_fmt(dateRange!.end)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: dateRange == null ? const Color(0xFF717785) : const Color(0xFF181C22),
                    ),
                  ),
                ),
                if (dateRange != null)
                  InkWell(
                    onTap: () => onDateRangeChanged(null),
                    child: Icon(Icons.close, size: 16, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _fmt(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  Widget _resetButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: onReset,
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Đặt lại', style: TextStyle(fontSize: 14)),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      isDense: true,
    );
  }
}

// ================================================================
// REPORT TABLE
// ================================================================

class _ReportTable extends StatelessWidget {
  final List<ReportResponse> reports;
  final Color primaryColor;
  final String rolePrefix;
  final UserRole currentRole;
  final int currentUserId;
  final void Function(ReportResponse) onView;
  final void Function(ReportResponse) onDelete;

  const _ReportTable({
    required this.reports,
    required this.primaryColor,
    required this.rolePrefix,
    required this.currentRole,
    required this.currentUserId,
    required this.onView,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _buildReportCard(reports[index]),
    );
  }

  Widget _buildReportCard(ReportResponse r) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.assessment_rounded, color: primaryColor),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('#${r.id}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(width: 10),
                    VersionBadge(version: r.version),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  r.generatedAt != null ? _dateFormat.format(r.generatedAt!) : '—',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Người tạo', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                const SizedBox(height: 4),
                Text(r.ownerName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ReportTypeBadge(type: r.type),
                ReportScopeBadge(scope: r.scope),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: ReportStatusBadge(status: r.status),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => onView(r),
                icon: Icon(Icons.visibility_rounded, color: primaryColor, size: 20),
                tooltip: 'Xem chi tiết',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF8FAFC),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(12),
                ),
              ),
              if (r.ownerId == currentUserId && r.status == ReportStatus.DRAFT) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => onDelete(r),
                  icon: Icon(Icons.delete_outline_rounded, color: Colors.red[400], size: 20),
                  tooltip: 'Xóa báo cáo',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFFEF2F2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ================================================================
// PAGINATION BAR
// ================================================================

class _PaginationBar extends StatelessWidget {
  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: page > 0 ? () => onPageChanged(page - 1) : null,
          icon: const Icon(Icons.chevron_left_rounded),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(width: 8),
        ...List.generate(totalPages > 7 ? 7 : totalPages, (i) {
          int p;
          if (totalPages > 7) {
            if (page < 4) {
              p = i;
            } else if (page > totalPages - 5) {
              p = totalPages - 7 + i;
            } else {
              p = page - 3 + i;
            }
          } else {
            p = i;
          }

          final isActive = p == page;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              onTap: () => onPageChanged(p),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF6366F1) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  '${p + 1}',
                  style: TextStyle(
                    color: isActive ? Colors.white : const Color(0xFF64748B),
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 8),
        IconButton(
          onPressed: page < totalPages - 1 ? () => onPageChanged(page + 1) : null,
          icon: const Icon(Icons.chevron_right_rounded),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}

// ================================================================
// RESULT INFO
// ================================================================

class _ResultInfo extends StatelessWidget {
  final int total;
  final int showing;
  final Color primaryColor;

  const _ResultInfo({
    required this.total,
    required this.showing,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      'Hiển thị $showing trong $total báo cáo',
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF64748B),
      ),
    );
  }
}

// ================================================================
// EMPTY STATE
// ================================================================

class _EmptyState extends StatelessWidget {
  final Color primaryColor;
  final VoidCallback onReset;

  const _EmptyState({required this.primaryColor, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.assessment_outlined, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Không có báo cáo nào',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onReset,
            child: const Text('Xóa bộ lọc', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// ERROR CARD
// ================================================================

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFF991B1B)),
          const SizedBox(height: 12),
          Text(
            'Đã xảy ra lỗi',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF991B1B)),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(fontSize: 14, color: Color(0xFFB91C1C)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF991B1B),
              foregroundColor: Colors.white,
            ),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// GENERATE REPORT DIALOG
// ================================================================

class _GenerateReportDialog extends StatefulWidget {
  final Color primaryColor;
  final UserRole currentRole;
  final void Function(ReportType type, int? scopeId) onGenerated;

  const _GenerateReportDialog({
    required this.primaryColor,
    required this.currentRole,
    required this.onGenerated,
  });

  @override
  State<_GenerateReportDialog> createState() => _GenerateReportDialogState();
}

class _GenerateReportDialogState extends State<_GenerateReportDialog> {
  ReportType? _selectedType;
  int? _selectedScopeId;
  bool _isLoading = false;
  bool _isLoadingScopes = false;
  List<_ScopeOption> _scopeOptions = [];

  List<ReportType> get _availableTypes {
    switch (widget.currentRole) {
      case UserRole.ADMIN:
        return ReportType.values;
      case UserRole.MENTOR:
        return [ReportType.MENTOR_WEEKLY, ReportType.MENTOR_MONTHLY];
      case UserRole.PROJECT_MANAGER:
        return [ReportType.PM_WEEKLY, ReportType.PM_MONTHLY];
      case UserRole.USER:
        return [];
    }
  }

  bool get _needsScopeSelection {
    return _selectedType != null &&
        (_selectedType == ReportType.MENTOR_WEEKLY ||
            _selectedType == ReportType.MENTOR_MONTHLY ||
            _selectedType == ReportType.PM_WEEKLY ||
            _selectedType == ReportType.PM_MONTHLY);
  }

  @override
  void initState() {
    super.initState();
    _loadScopeOptions();
  }

  Future<void> _loadScopeOptions() async {
    if (!mounted) return;
    setState(() => _isLoadingScopes = true);

    try {
      final options = await _fetchScopeOptions();
      if (!mounted) return;
      setState(() {
        _scopeOptions = options;
        _isLoadingScopes = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _scopeOptions = [_ScopeOption(id: null, label: 'Tất cả (toàn hệ thống)')];
        _isLoadingScopes = false;
      });
    }
  }

  Future<List<_ScopeOption>> _fetchScopeOptions() async {
    switch (widget.currentRole) {
      case UserRole.MENTOR:
        final courseSvc = MentorCourseService();
        final resp = await courseSvc.listCourses(isMine: true, size: 100);
        return [
          _ScopeOption(id: null, label: 'Tất cả khóa học của tôi'),
          ...resp.content.map((c) => _ScopeOption(
                id: c.id.value,
                label: c.title,
              )),
        ];
      case UserRole.PROJECT_MANAGER:
        final result = await ProjectService.getAll(size: 100);
        return [
          _ScopeOption(id: null, label: 'Tất cả dự án'),
          ...result.projects.map((p) => _ScopeOption(
                id: p.id,
                label: p.title,
              )),
        ];
      case UserRole.ADMIN:
        return [_ScopeOption(id: null, label: 'Toàn hệ thống')];
      case UserRole.USER:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.add_chart_rounded, color: widget.primaryColor),
          const SizedBox(width: 10),
          const Text('Tạo báo cáo mới', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn loại báo cáo:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            ..._availableTypes.map((t) => RadioListTile<ReportType>(
                  title: Text(t.displayName),
                  subtitle: Text('Phạm vi: ${_scopeOf(t).displayName}'),
                  value: t,
                  groupValue: _selectedType,
                  activeColor: widget.primaryColor,
                  onChanged: (v) => setState(() {
                    _selectedType = v;
                    _selectedScopeId = null;
                  }),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                )),
            const SizedBox(height: 8),
            // Scope dropdown — only for MENTOR and PM
            if (_needsScopeSelection) ...[
              const SizedBox(height: 8),
              const Text(
                'Chọn phạm vi (tùy chọn):',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              if (_isLoadingScopes)
                const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)))
              else
                DropdownButtonFormField<int?>(
                  value: _selectedScopeId,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: widget.primaryColor, width: 1.5)),
                    isDense: true,
                  ),
                  hint: Text(_scopeOptions.isNotEmpty ? _scopeOptions.first.label : 'Đang tải...', style: const TextStyle(fontSize: 14)),
                  isExpanded: true,
                  items: _scopeOptions.map((o) => DropdownMenuItem(value: o.id, child: Text(o.label, style: const TextStyle(fontSize: 14)))).toList(),
                  onChanged: (v) => setState(() => _selectedScopeId = v),
                ),
            ],
            const SizedBox(height: 12),
            if (_selectedType != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: widget.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Báo cáo sẽ được tạo dưới dạng bản nháp (DRAFT) và chỉ bạn mới có thể chỉnh sửa.',
                        style: TextStyle(fontSize: 12, color: widget.primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _selectedType == null || _isLoading
              ? null
              : () {
                  setState(() => _isLoading = true);
                  widget.onGenerated(_selectedType!, _selectedScopeId);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Tạo báo cáo'),
        ),
      ],
    );
  }

  ReportScope _scopeOf(ReportType type) {
    switch (type) {
      case ReportType.MENTOR_WEEKLY:
      case ReportType.MENTOR_MONTHLY:
        return ReportScope.COURSE;
      case ReportType.PM_WEEKLY:
      case ReportType.PM_MONTHLY:
        return ReportScope.PROJECT;
      case ReportType.ADMIN_WEEKLY:
      case ReportType.ADMIN_MONTHLY:
        return ReportScope.SYSTEM;
    }
  }
}

class _ScopeOption {
  final int? id;
  final String label;

  _ScopeOption({required this.id, required this.label});
}
