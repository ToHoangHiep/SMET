import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smet/model/report_model.dart';
import 'package:smet/model/user_model.dart';
import 'package:smet/page/report/shared/report_badges.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/service/report/file_download_util.dart';
import 'package:smet/service/report/report_service.dart';

final _df = DateFormat('dd/MM/yyyy HH:mm');

// ================================================================
// REPORT DETAIL SCREEN
// Role-based actions:
//   ADMIN  → approve / reject (SUBMITTED reports)
//   OWNER  → edit / submit (DRAFT reports)
//   OTHERS → read-only
// ================================================================

class ReportDetailScreen extends StatefulWidget {
  final int reportId;
  final UserRole currentRole;
  final int currentUserId;
  final Color primaryColor;
  final String rolePrefix;

  const ReportDetailScreen({
    super.key,
    required this.reportId,
    required this.currentRole,
    required this.currentUserId,
    required this.primaryColor,
    required this.rolePrefix,
  });

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final _svc = reportService;

  ReportDetailResponse? _report;
  List<ReportVersionResponse>? _versions;
  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _svc.getReportDetail(widget.reportId),
        _svc.getReportVersions(widget.reportId),
      ]);

      if (!mounted) return;

      setState(() {
        _report = results[0] as ReportDetailResponse;
        _versions = results[1] as List<ReportVersionResponse>;
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

  bool get _isOwner => _report != null && _report!.id == widget.currentUserId;

  bool get _canEdit =>
      _isOwner && _report!.status == ReportStatus.DRAFT;

  bool get _canSubmit =>
      _isOwner && _report!.status == ReportStatus.DRAFT;

  bool get _canApproveReject =>
      widget.currentRole == UserRole.ADMIN &&
      _report!.status == ReportStatus.SUBMITTED;

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
                pageTitle: 'Chi tiết Báo cáo #${widget.reportId}',
                pageIcon: Icons.description_rounded,
                breadcrumbs: [
                  BreadcrumbItem(
                    label: 'Tổng quan',
                    route: _roleRoute(),
                  ),
                  BreadcrumbItem(
                    label: 'Báo cáo',
                    route: _roleRoute().replaceAll('/dashboard', '/reports'),
                  ),
                  BreadcrumbItem(label: '#${widget.reportId}'),
                ],
                primaryColor: widget.primaryColor,
                actions: _buildHeaderActions(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: _buildContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _roleRoute() {
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

  List<Widget> _buildHeaderActions() {
    if (_report == null) return [];
    return [
      // Version history button
      OutlinedButton.icon(
        onPressed: () => _showVersionHistory(),
        style: OutlinedButton.styleFrom(
          foregroundColor: widget.primaryColor,
          side: BorderSide(color: widget.primaryColor),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: const Icon(Icons.history_rounded, size: 18),
        label: const Text('Lịch sử', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      const SizedBox(width: 12),
      // Export buttons
      _ExportButton(
        reportId: widget.reportId,
        primaryColor: widget.primaryColor,
      ),
    ];
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return _buildError();
    }

    if (_report == null) {
      return const Center(child: Text('Không tìm thấy báo cáo'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetadataSection(report: _report!, primaryColor: widget.primaryColor),
        const SizedBox(height: 24),
        _SnapshotSection(report: _report!, primaryColor: widget.primaryColor),
        const SizedBox(height: 24),
        if (_report!.comment != null || _report!.reviewerComment != null)
          _CommentsSection(report: _report!, primaryColor: widget.primaryColor),
        const SizedBox(height: 24),
        _ActionsSection(
          report: _report!,
          primaryColor: widget.primaryColor,
          canEdit: _canEdit,
          canSubmit: _canSubmit,
          canApproveReject: _canApproveReject,
          isActionLoading: _isActionLoading,
          onEdit: _onEdit,
          onSubmit: _onSubmit,
          onApprove: _onApprove,
          onReject: _onReject,
          onRefresh: _loadAll,
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildError() {
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
            _error!,
            style: const TextStyle(fontSize: 14, color: Color(0xFFB91C1C)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAll,
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

  void _onEdit() {
    context.go('/report/edit/${widget.reportId}');
  }

  Future<void> _onSubmit() async {
    final confirmed = await _showConfirmDialog(
      title: 'Gửi báo cáo',
      message:
          'Báo cáo sẽ được gửi để quản trị viên duyệt. Bạn sẽ không thể chỉnh sửa sau khi gửi.',
      confirmText: 'Gửi báo cáo',
      confirmColor: Colors.green,
    );
    if (confirmed != true) return;

    await _doAction('submit', () => _svc.submitReport(widget.reportId));
  }

  Future<void> _onApprove() async {
    final confirmed = await _showConfirmDialog(
      title: 'Phê duyệt báo cáo',
      message: 'Bạn có chắc chắn muốn phê duyệt báo cáo này?',
      confirmText: 'Phê duyệt',
      confirmColor: Colors.green,
    );
    if (confirmed != true) return;

    await _doAction('approve', () => _svc.approveReport(widget.reportId));
  }

  Future<void> _onReject() async {
    final comment = await _showRejectDialog();
    if (comment == null) return;

    await _doAction('reject', () => _svc.rejectReport(widget.reportId, comment));
  }

  Future<void> _doAction(String actionName, Future<void> Function() action) async {
    if (!mounted) return;

    setState(() => _isActionLoading = true);

    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_actionLabel(actionName)} thành công!')),
      );
      _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: const Color(0xFF991B1B),
        ),
      );
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  String _actionLabel(String name) {
    switch (name) {
      case 'submit':
        return 'Gửi báo cáo';
      case 'approve':
        return 'Phê duyệt';
      case 'reject':
        return 'Từ chối';
      default:
        return name;
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Từ chối báo cáo'),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Lý do từ chối',
              hintText: 'Nhập lý do từ chối báo cáo...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.of(ctx).pop(controller.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF991B1B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }

  void _showVersionHistory() {
    if (_versions == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _VersionHistorySheet(
        versions: _versions!,
        primaryColor: widget.primaryColor,
      ),
    );
  }
}

// ================================================================
// METADATA SECTION
// ================================================================

class _MetadataSection extends StatelessWidget {
  final ReportDetailResponse report;
  final Color primaryColor;

  const _MetadataSection({required this.report, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Thông tin báo cáo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              const Spacer(),
              ReportStatusBadge(status: report.status, fontSize: 13),
              const SizedBox(width: 12),
              VersionBadge(version: report.version),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),
          Wrap(
            spacing: 48,
            runSpacing: 16,
            children: [
              _metaItem('Loại báo cáo', report.type.displayName, Icons.category_rounded),
              _metaItem('Phạm vi', _scopeOf(report.type).displayName, Icons.domain_rounded),
              _metaItem('Phiên bản', 'v${report.version}', Icons.history_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaItem(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: primaryColor),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
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

// ================================================================
// SNAPSHOT SECTION
// Renders parsed JSON data into structured UI
// ================================================================

class _SnapshotSection extends StatelessWidget {
  final ReportDetailResponse report;
  final Color primaryColor;

  const _SnapshotSection({required this.report, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final snapshot = report.snapshotData;

    return Container(
      padding: const EdgeInsets.all(28),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Dữ liệu Báo cáo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded, size: 12, color: Color(0xFF16A34A)),
                    SizedBox(width: 4),
                    Text(
                      'Snapshot cố định tại thời điểm tạo',
                      style: TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (snapshot == null)
            _buildRawJson()
          else if (snapshot.mentor != null)
            _buildMentorSnapshot(snapshot.mentor!)
          else if (snapshot.pm != null)
            _buildPmSnapshot(snapshot.pm!)
          else if (snapshot.admin != null)
            _buildAdminSnapshot(snapshot.admin!),
        ],
      ),
    );
  }

  Widget _buildRawJson() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SelectableText(
        report.dataJson ?? '{}',
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      ),
    );
  }

  // ---- MENTOR SNAPSHOT ----

  Widget _buildMentorSnapshot(MentorSnapshot m) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary KPIs
        _SectionTitle(title: 'Tổng quan', icon: Icons.analytics_rounded, primaryColor: primaryColor),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final count = constraints.maxWidth > 700 ? 4 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: count,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.2,
              children: [
                _KpiCard(
                  label: 'Tổng học viên',
                  value: '${m.totalStudents}',
                  icon: Icons.group_rounded,
                  color: const Color(0xFF6366F1),
                ),
                _KpiCard(
                  label: 'Hoàn thành',
                  value: '${m.completedStudents}',
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF16A34A),
                ),
                _KpiCard(
                  label: 'Tỷ lệ hoàn thành',
                  value: '${m.completionRate.toStringAsFixed(1)}%',
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF2563EB),
                ),
                _KpiCard(
                  label: 'Điểm trung bình',
                  value: m.avgScore.toStringAsFixed(1),
                  icon: Icons.star_rounded,
                  color: const Color(0xFFD97706),
                ),
              ],
            );
          },
        ),

        // At risk users
        if (m.atRiskUsers.isNotEmpty) ...[
          const SizedBox(height: 32),
          _SectionTitle(title: 'Học viên có nguy cơ', icon: Icons.warning_rounded, primaryColor: Colors.orange),
          const SizedBox(height: 16),
          _buildAtRiskTable(m.atRiskUsers),
        ],
      ],
    );
  }

  Widget _buildAtRiskTable(List<AtRiskUser> users) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1),
          1: FlexColumnWidth(3),
          2: FlexColumnWidth(2),
        },
        border: TableBorder(
          horizontalInside: BorderSide(color: Colors.grey.shade200),
        ),
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            children: const [
              Padding(
                padding: EdgeInsets.all(12),
                child: Text('ID', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text('Họ tên', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text('Hạn chót', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
          ...users.map((u) => TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('#${u.userId}', style: const TextStyle(fontSize: 13)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(u.userName ?? '—', style: const TextStyle(fontSize: 13)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      u.deadline != null ? _df.format(u.deadline!) : '—',
                      style: TextStyle(fontSize: 13, color: Colors.orange.shade700),
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }

  // ---- PM SNAPSHOT ----

  Widget _buildPmSnapshot(PmSnapshot m) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'Tổng quan Dự án', icon: Icons.analytics_rounded, primaryColor: primaryColor),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final count = constraints.maxWidth > 600 ? 3 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: count,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.2,
              children: [
                _KpiCard(
                  label: 'Tổng người dùng',
                  value: '${m.totalUsers}',
                  icon: Icons.group_rounded,
                  color: const Color(0xFF6366F1),
                ),
                _KpiCard(
                  label: 'Hoàn thành',
                  value: '${m.completed}',
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF16A34A),
                ),
                _KpiCard(
                  label: 'Tỷ lệ hoàn thành',
                  value: '${m.completionRate.toStringAsFixed(1)}%',
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF2563EB),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ---- ADMIN SNAPSHOT ----

  Widget _buildAdminSnapshot(AdminSnapshot m) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'Tổng quan Hệ thống', icon: Icons.analytics_rounded, primaryColor: primaryColor),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final count = constraints.maxWidth > 700 ? 3 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: count,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.2,
              children: [
                _KpiCard(
                  label: 'Tổng người dùng',
                  value: '${m.totalUsers}',
                  icon: Icons.people_rounded,
                  color: const Color(0xFF6366F1),
                ),
                _KpiCard(
                  label: 'Tổng khóa học',
                  value: '${m.totalCourses}',
                  icon: Icons.menu_book_rounded,
                  color: const Color(0xFF2563EB),
                ),
                _KpiCard(
                  label: 'Hoàn thành',
                  value: '${m.completedUsers}',
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF16A34A),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color primaryColor;

  const _SectionTitle({
    required this.title,
    required this.icon,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: primaryColor,
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// COMMENTS SECTION
// ================================================================

class _CommentsSection extends StatelessWidget {
  final ReportDetailResponse report;
  final Color primaryColor;

  const _CommentsSection({required this.report, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ghi chú & Phản hồi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 16),
          if (report.comment != null && report.comment!.isNotEmpty)
            _CommentCard(
              label: 'Ghi chú của người tạo',
              content: report.comment!,
              color: const Color(0xFF6366F1),
              icon: Icons.note_rounded,
            ),
          if (report.reviewerComment != null && report.reviewerComment!.isNotEmpty)
            _CommentCard(
              label: 'Phản hồi của quản trị viên',
              content: report.reviewerComment!,
              color: const Color(0xFFB45309),
              icon: Icons.rate_review_rounded,
            ),
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final String label;
  final String content;
  final Color color;
  final IconData icon;

  const _CommentCard({
    required this.label,
    required this.content,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// ACTIONS SECTION
// ================================================================

class _ActionsSection extends StatelessWidget {
  final ReportDetailResponse report;
  final Color primaryColor;
  final bool canEdit;
  final bool canSubmit;
  final bool canApproveReject;
  final bool isActionLoading;
  final VoidCallback onEdit;
  final VoidCallback onSubmit;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onRefresh;

  const _ActionsSection({
    required this.report,
    required this.primaryColor,
    required this.canEdit,
    required this.canSubmit,
    required this.canApproveReject,
    required this.isActionLoading,
    required this.onEdit,
    required this.onSubmit,
    required this.onApprove,
    required this.onReject,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hành động',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // Owner actions
              if (canEdit)
                _ActionButton(
                  label: 'Chỉnh sửa',
                  icon: Icons.edit_rounded,
                  color: primaryColor,
                  onPressed: onEdit,
                  isLoading: isActionLoading,
                ),
              if (canSubmit)
                _ActionButton(
                  label: 'Gửi duyệt',
                  icon: Icons.send_rounded,
                  color: Colors.blue,
                  onPressed: onSubmit,
                  isLoading: isActionLoading,
                ),
              // Admin actions
              if (canApproveReject) ...[
                _ActionButton(
                  label: 'Phê duyệt',
                  icon: Icons.check_circle_rounded,
                  color: Colors.green,
                  onPressed: onApprove,
                  isLoading: isActionLoading,
                ),
                _ActionButton(
                  label: 'Từ chối',
                  icon: Icons.cancel_rounded,
                  color: Colors.red,
                  onPressed: onReject,
                  isLoading: isActionLoading,
                ),
              ],
              // Read-only notice
              if (!canEdit && !canSubmit && !canApproveReject)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Bạn không có quyền thực hiện hành động nào với báo cáo này.',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool isLoading;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 2,
      ),
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

// ================================================================
// EXPORT BUTTON (Dropdown)
// ================================================================

class _ExportButton extends StatelessWidget {
  final int reportId;
  final Color primaryColor;

  const _ExportButton({required this.reportId, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.download_rounded, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            const Text(
              'Xuất file',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
      itemBuilder: (ctx) => [
        _buildItem('pdf', 'PDF', Icons.picture_as_pdf_rounded),
        _buildItem('excel', 'Excel (.xlsx)', Icons.table_chart_rounded),
        _buildItem('csv', 'CSV', Icons.grid_on_rounded),
      ],
      onSelected: (format) => _handleExport(context, format),
    );
  }

  PopupMenuItem<String> _buildItem(String format, String label, IconData icon) {
    return PopupMenuItem(
      value: format,
      child: Row(
        children: [
          Icon(icon, size: 18, color: primaryColor),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    );
  }

  Future<void> _handleExport(BuildContext context, String format) async {
    try {
      final result = await reportService.exportReport(reportId, format);
      FileDownloadUtil.downloadBytes(result: result);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã tải file ${format.toUpperCase()}')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi xuất file: $e'),
          backgroundColor: const Color(0xFF991B1B),
        ),
      );
    }
  }
}

// ================================================================
// VERSION HISTORY SHEET
// ================================================================

class _VersionHistorySheet extends StatelessWidget {
  final List<ReportVersionResponse> versions;
  final Color primaryColor;

  const _VersionHistorySheet({required this.versions, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollController) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(Icons.history_rounded, color: primaryColor),
                const SizedBox(width: 10),
                Text(
                  'Lịch sử phiên bản (${versions.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: versions.length,
              itemBuilder: (ctx, i) => _VersionItem(
                version: versions[i],
                primaryColor: primaryColor,
                isLast: i == versions.length - 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionItem extends StatelessWidget {
  final ReportVersionResponse version;
  final Color primaryColor;
  final bool isLast;

  const _VersionItem({
    required this.version,
    required this.primaryColor,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      VersionBadge(version: version.version),
                      const SizedBox(width: 8),
                      ActionTypeBadge(actionType: version.actionType),
                      const Spacer(),
                      Text(
                        version.changedAt != null
                            ? _df.format(version.changedAt!)
                            : '—',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_rounded, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        version.changedByName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  if (version.comment != null && version.comment!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      version.comment!,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
