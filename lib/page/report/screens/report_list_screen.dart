import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smet/model/report_model.dart';
import 'package:smet/model/user_model.dart';
import 'package:smet/page/report/shared/report_badges.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
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

  const ReportListScreen({
    super.key,
    required this.currentRole,
    required this.primaryColor,
    required this.rolePrefix,
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
      final result = await _svc.listReports(
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
                    route: _roleRoute('/${widget.rolePrefix}/dashboard'),
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
          onView: (r) => context.go('/report/$reportIdParam?reportId=${r.id}'),
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

  String _roleRoute(String path) {
    switch (widget.currentRole) {
      case UserRole.ADMIN:
        return '/user_management';
      case UserRole.PROJECT_MANAGER:
        return '/pm/dashboard';
      case UserRole.MENTOR:
        return '/mentor/dashboard';
      case UserRole.USER:
        return '/employee/dashboard';
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
            context.go('/report/$reportIdParam?reportId=${report.id}');
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
// ROUTE PARAM NAME (shared)
// ================================================================

const reportIdParam = 'reportId';

// ================================================================
// FILTER BAR
// ================================================================

class _FilterBar extends StatelessWidget {
  final Color primaryColor;
  final ReportType? selectedType;
  final ReportStatus? selectedStatus;
  final DateTimeRange? dateRange;
  final ValueChanged<ReportType?> onTypeChanged;
  final ValueChanged<ReportStatus?> onStatusChanged;
  final ValueChanged<DateTimeRange?> onDateRangeChanged;
  final VoidCallback onReset;

  const _FilterBar({
    required this.primaryColor,
    required this.selectedType,
    required this.selectedStatus,
    required this.dateRange,
    required this.onTypeChanged,
    required this.onStatusChanged,
    required this.onDateRangeChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
            ...ReportType.values.map((t) => DropdownMenuItem(
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
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
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
  final void Function(ReportResponse) onView;

  const _ReportTable({
    required this.reports,
    required this.primaryColor,
    required this.rolePrefix,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          dataRowColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return const Color(0xFFF1F5F9);
            }
            return Colors.white;
          }),
          columns: const [
            DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Loại báo cáo', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Người tạo', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Phạm vi', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Ngày tạo', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Phiên bản', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Hành động', style: TextStyle(fontWeight: FontWeight.w700))),
          ],
          rows: reports.map((r) => _buildRow(r)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(ReportResponse r) {
    return DataRow(
      cells: [
        DataCell(Text('#${r.id}', style: const TextStyle(fontWeight: FontWeight.w600))),
        DataCell(ReportTypeBadge(type: r.type)),
        DataCell(ReportStatusBadge(status: r.status)),
        DataCell(Text(r.ownerName, style: const TextStyle(fontSize: 14))),
        DataCell(ReportScopeBadge(scope: r.scope)),
        DataCell(Text(
          r.generatedAt != null ? _dateFormat.format(r.generatedAt!) : '—',
          style: const TextStyle(fontSize: 13),
        )),
        DataCell(VersionBadge(version: r.version)),
        DataCell(
          IconButton(
            onPressed: () => onView(r),
            icon: Icon(Icons.visibility_rounded, color: primaryColor, size: 20),
            tooltip: 'Xem chi tiết',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
      ],
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
  bool _isLoading = false;

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
        width: 400,
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
                  onChanged: (v) => setState(() => _selectedType = v),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                )),
            const SizedBox(height: 8),
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
                  widget.onGenerated(_selectedType!, null);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
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
