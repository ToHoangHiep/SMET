import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smet/model/report_model.dart';
import 'package:smet/page/report/shared/report_badges.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/service/report/report_service.dart';

final _df = DateFormat('dd/MM/yyyy HH:mm');

// ================================================================
// VERSION HISTORY SCREEN
// Dedicated page for viewing report version history
// ================================================================

class VersionHistoryScreen extends StatefulWidget {
  final int reportId;
  final Color primaryColor;
  final String rolePrefix;

  const VersionHistoryScreen({
    super.key,
    required this.reportId,
    required this.primaryColor,
    required this.rolePrefix,
  });

  @override
  State<VersionHistoryScreen> createState() => _VersionHistoryScreenState();
}

class _VersionHistoryScreenState extends State<VersionHistoryScreen> {
  final _svc = reportService;

  List<ReportVersionResponse>? _versions;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVersions();
  }

  Future<void> _loadVersions() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final versions = await _svc.getReportVersions(widget.reportId);
      if (!mounted) return;

      setState(() {
        _versions = versions;
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
                pageTitle: 'Lịch sử phiên bản',
                pageIcon: Icons.history_rounded,
                breadcrumbs: [
                  BreadcrumbItem(label: 'Tổng quan', route: _roleRoute()),
                  BreadcrumbItem(
                    label: 'Báo cáo',
                    route: _roleRoute('report'),
                  ),
                  BreadcrumbItem(
                    label: '#${widget.reportId}',
                    route: null, // current page
                  ),
                  const BreadcrumbItem(label: 'Lịch sử'),
                ],
                primaryColor: widget.primaryColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
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

  String _roleRoute([String? suffix]) {
    switch (widget.rolePrefix) {
      case 'admin':
        return suffix == 'report' ? '/admin/reports' : '/user_management';
      case 'pm':
        return suffix == 'report' ? '/reports' : '/pm/dashboard';
      case 'mentor':
        return suffix == 'report' ? '/mentor/reports' : '/mentor/dashboard';
      default:
        return suffix == 'report' ? '/reports' : '/employee/dashboard';
    }
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
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
            Text(_error!, style: const TextStyle(fontSize: 14, color: Color(0xFFB91C1C))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadVersions,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF991B1B), foregroundColor: Colors.white),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_versions == null || _versions!.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 80),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.history_rounded, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'Chưa có lịch sử phiên bản',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: widget.primaryColor, size: 20),
              const SizedBox(width: 10),
              Text(
                'Báo cáo #${widget.reportId} có ${_versions!.length} phiên bản',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: widget.primaryColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Timeline
        ...List.generate(_versions!.length, (i) => _VersionCard(
              version: _versions![i],
              primaryColor: widget.primaryColor,
              isLast: i == _versions!.length - 1,
            )),
        const SizedBox(height: 80),
      ],
    );
  }
}

// ================================================================
// VERSION CARD (Timeline item)
// ================================================================

class _VersionCard extends StatelessWidget {
  final ReportVersionResponse version;
  final Color primaryColor;
  final bool isLast;

  const _VersionCard({
    required this.version,
    required this.primaryColor,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _dotColor.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
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
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
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
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      children: [
                        VersionBadge(version: version.version),
                        const SizedBox(width: 10),
                        ActionTypeBadge(actionType: version.actionType),
                        const Spacer(),
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          version.changedAt != null ? _df.format(version.changedAt!) : '—',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  // Body
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: primaryColor.withValues(alpha: 0.1),
                              child: Icon(
                                Icons.person_rounded,
                                size: 14,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              version.changedByName,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(#${version.changedBy})',
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                        if (version.comment != null && version.comment!.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.format_quote_rounded, size: 14, color: Colors.grey[400]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    version.comment!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.5,
                                      fontStyle: FontStyle.italic,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // JSON diff preview
                        if (version.editableJson != null && version.editableJson!.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: EdgeInsets.zero,
                            title: Text(
                              'Xem nội dung JSON',
                              style: TextStyle(fontSize: 13, color: primaryColor, fontWeight: FontWeight.w500),
                            ),
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: SelectableText(
                                  version.editableJson!,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: Color(0xFFE2E8F0),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
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

  Color get _dotColor {
    switch (version.actionType) {
      case ReportActionType.EDIT:
        return Colors.blue;
      case ReportActionType.SUBMIT:
        return Colors.orange;
      case ReportActionType.APPROVE:
        return Colors.green;
      case ReportActionType.REJECT:
        return Colors.red;
      case ReportActionType.DELETE:
        return Colors.red;
    }
  }
}
