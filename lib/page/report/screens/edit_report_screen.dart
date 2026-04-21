import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/report_model.dart';
import 'package:smet/model/user_model.dart';
import 'package:smet/page/report/report.dart';
import 'package:smet/page/report/shared/report_badges.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/service/report/report_service.dart';

// ================================================================
// EDIT REPORT SCREEN
// Owner only, DRAFT only
// Allows editing editableJson (JSON editor or structured form)
// Shows version increment
// ================================================================

class EditReportScreen extends StatefulWidget {
  final int reportId;
  final UserRole currentRole;
  final int currentUserId;
  final Color primaryColor;
  final String rolePrefix;

  const EditReportScreen({
    super.key,
    required this.reportId,
    required this.currentRole,
    required this.currentUserId,
    required this.primaryColor,
    required this.rolePrefix,
  });

  @override
  State<EditReportScreen> createState() => _EditReportScreenState();
}

class _EditReportScreenState extends State<EditReportScreen> {
  final _svc = reportService;

  ReportDetailResponse? _report;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  // Edit form
  late TextEditingController _commentController;
  late TextEditingController _editableJsonController;
  bool _isJsonMode = true;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _editableJsonController = TextEditingController();
    _loadReport();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _editableJsonController.dispose();
    super.dispose();
  }

  Future<void> _loadReport() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final report = await _svc.getReportDetail(widget.reportId);

      if (!mounted) return;

      // Check access
      if (report.status != ReportStatus.DRAFT) {
        setState(() {
          _error = 'Chỉ có thể chỉnh sửa báo cáo ở trạng thái Nháp (DRAFT)';
          _isLoading = false;
        });
        return;
      }

      // Pre-fill editable JSON (or show a template)
      final editableJson = report.editableJson;
      if (editableJson != null && editableJson.isNotEmpty) {
        _editableJsonController.text = _prettyPrintJson(editableJson);
      } else {
        // Start with a template derived from snapshot data
        final snapshot = report.snapshotData;
        if (snapshot != null && snapshot.isMentor) {
          _editableJsonController.text = _prettyPrintJson(jsonEncode({
            'assignedProjects': snapshot.assignedProjects,
            'completedCourses': snapshot.completedCourses,
            'inProgressCourses': snapshot.inProgressCourses,
            'notStartedCourses': snapshot.notStartedCourses,
            'totalCourses': snapshot.totalCourses,
            'notes': '',
          }));
        } else if (snapshot != null && snapshot.isPm) {
          _editableJsonController.text = _prettyPrintJson(jsonEncode({
            'totalProjects': snapshot.totalProjects,
            'completedProjects': snapshot.completedProjects,
            'completedCourses': snapshot.completedCourses,
            'inProgressCourses': snapshot.inProgressCourses,
            'notStartedCourses': snapshot.notStartedCourses,
            'notes': '',
          }));
        } else if (snapshot != null && snapshot.isAdmin) {
          _editableJsonController.text = _prettyPrintJson(jsonEncode({
            'totalUsers': snapshot.totalUsers,
            'totalProjects': snapshot.totalProjects,
            'completedCourses': snapshot.completedCourses,
            'inProgressCourses': snapshot.inProgressCourses,
            'notStartedCourses': snapshot.notStartedCourses,
            'notes': '',
          }));
        }
      }

      _report = report;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _prettyPrintJson(String json) {
    try {
      final parsed = jsonDecode(json);
      return const JsonEncoder.withIndent('  ').convert(parsed);
    } catch (_) {
      return json;
    }
  }

  void _validateJson(String text) {
    if (text.trim().isEmpty) {
      setState(() => _validationError = null);
      return;
    }
    try {
      jsonDecode(text);
      setState(() => _validationError = null);
    } catch (e) {
      setState(() => _validationError = 'JSON không hợp lệ: ${e.toString()}');
    }
  }

  Future<void> _save() async {
    if (_report == null) return;

    final jsonText = _editableJsonController.text.trim();
    if (jsonText.isNotEmpty) {
      try {
        jsonDecode(jsonText); // validate
      } catch (e) {
        setState(() => _validationError = 'JSON không hợp lệ');
        return;
      }
    }

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Lưu báo cáo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phiên bản sẽ tăng từ v${_report!.version} lên v${_report!.version + 1}.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'Nhập ghi chú thay đổi (tùy chọn):',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Mô tả thay đổi...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);

    try {
      await _svc.updateReport(
        widget.reportId,
        editableJson: jsonText.isNotEmpty ? jsonText : null,
        comment: _commentController.text.trim().isNotEmpty
            ? _commentController.text.trim()
            : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lưu báo cáo thành công!')),
      );

      // Navigate back to detail
      final detailRoute = switch (widget.currentRole) {
        UserRole.ADMIN => '/admin/report/${widget.reportId}',
        UserRole.MENTOR => '/mentor/report/${widget.reportId}',
        UserRole.PROJECT_MANAGER => '/pm/report/${widget.reportId}',
        UserRole.USER => '/report/${widget.reportId}',
      };
      context.go(detailRoute);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: const Color(0xFF991B1B),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
                pageTitle: 'Chỉnh sửa Báo cáo #${widget.reportId}',
                pageIcon: Icons.edit_note_rounded,
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
                  const BreadcrumbItem(label: 'Chỉnh sửa'),
                ],
                primaryColor: widget.primaryColor,
                actions: [
                  if (_report != null && !_isSaving)
                    OutlinedButton.icon(
                      onPressed: () {
                        final detailRoute = switch (widget.currentRole) {
                          UserRole.ADMIN => '/admin/report/${widget.reportId}',
                          UserRole.MENTOR => '/mentor/report/${widget.reportId}',
                          UserRole.PROJECT_MANAGER => '/pm/report/${widget.reportId}',
                          UserRole.USER => '/report/${widget.reportId}',
                        };
                        context.go(detailRoute);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  const SizedBox(width: 12),
                  if (_report != null)
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded, size: 18),
                      label: Text(
                        _isSaving ? 'Đang lưu...' : 'Lưu thay đổi',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
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

  String _roleRoute([String? suffix]) {
    switch (widget.currentRole) {
      case UserRole.ADMIN:
        return suffix == 'report' ? '/admin/reports' : '/user_management';
      case UserRole.PROJECT_MANAGER:
        return suffix == 'report' ? '/pm/reports' : '/pm/dashboard';
      case UserRole.MENTOR:
        return suffix == 'report' ? '/mentor/reports' : '/mentor/dashboard';
      case UserRole.USER:
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
            Text(
              _error!,
              style: const TextStyle(fontSize: 14, color: Color(0xFFB91C1C)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(_roleRoute()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF991B1B),
                foregroundColor: Colors.white,
              ),
              child: const Text('Quay lại'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info bar
        _EditInfoBar(report: _report!, primaryColor: widget.primaryColor),
        const SizedBox(height: 24),
        // Editor
        _EditorSection(
          report: _report!,
          primaryColor: widget.primaryColor,
          controller: _editableJsonController,
          isJsonMode: _isJsonMode,
          validationError: _validationError,
          onValidate: _validateJson,
          onToggleMode: () => setState(() => _isJsonMode = !_isJsonMode),
        ),
        const SizedBox(height: 24),
        // Snapshot data reference
        _SnapshotReference(
          report: _report!,
          primaryColor: widget.primaryColor,
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

// ================================================================
// EDIT INFO BAR
// ================================================================

class _EditInfoBar extends StatelessWidget {
  final ReportDetailResponse report;
  final Color primaryColor;

  const _EditInfoBar({required this.report, required this.primaryColor});

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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.edit_note_rounded, color: primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.type.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    ReportStatusBadge(status: report.status),
                    const SizedBox(width: 12),
                    VersionBadge(version: report.version),
                    const SizedBox(width: 12),
                    const Text(
                      '→ Phiên bản tiếp theo: ',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    Text(
                      'v${report.version + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFB45309)),
                SizedBox(width: 6),
                Text(
                  'Chỉnh sửa JSON sẽ được lưu vào currentEditableJson',
                  style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// EDITOR SECTION
// ================================================================

class _EditorSection extends StatelessWidget {
  final ReportDetailResponse report;
  final Color primaryColor;
  final TextEditingController controller;
  final bool isJsonMode;
  final String? validationError;
  final ValueChanged<String> onValidate;
  final VoidCallback onToggleMode;

  const _EditorSection({
    required this.report,
    required this.primaryColor,
    required this.controller,
    required this.isJsonMode,
    required this.validationError,
    required this.onValidate,
    required this.onToggleMode,
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
          Row(
            children: [
              const Text(
                'Nội dung chỉnh sửa',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              const Spacer(),
              // Mode toggle
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('JSON')),
                  ButtonSegment(value: false, label: Text('Form')),
                ],
                selected: {isJsonMode},
                onSelectionChanged: (_) => onToggleMode(),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isJsonMode) _buildJsonEditor() else _buildFormEditor(),
          if (validationError != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFF991B1B)),
                const SizedBox(width: 6),
                Text(
                  validationError!,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJsonEditor() {
    return TextField(
      controller: controller,
      maxLines: 20,
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        height: 1.6,
      ),
      decoration: InputDecoration(
        hintText: '{\n  "notes": "...",\n  "actionItems": []\n}',
        hintStyle: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: Colors.grey[400],
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
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
        contentPadding: const EdgeInsets.all(16),
      ),
      onChanged: onValidate,
    );
  }

  Widget _buildFormEditor() {
    final snapshot = report.snapshotData;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (snapshot != null && snapshot.isMentor) ...[
            _FormField(
              label: 'Dự án được giao',
              value: '${snapshot.assignedProjects ?? 0}',
              enabled: false,
              primaryColor: primaryColor,
            ),
            _FormField(
              label: 'Hoàn thành',
              value: '${snapshot.completedCourses ?? 0}',
              enabled: false,
              primaryColor: primaryColor,
            ),
            _FormField(
              label: 'Đang học',
              value: '${snapshot.inProgressCourses ?? 0}',
              enabled: false,
              primaryColor: primaryColor,
            ),
            _FormField(
              label: 'Chưa bắt đầu',
              value: '${snapshot.notStartedCourses ?? 0}',
              enabled: false,
              primaryColor: primaryColor,
            ),
          ] else if (snapshot != null && snapshot.isPm) ...[
            _FormField(
              label: 'Tổng dự án',
              value: '${snapshot.totalProjects ?? 0}',
              enabled: false,
              primaryColor: primaryColor,
            ),
            _FormField(
              label: 'Hoàn thành',
              value: '${snapshot.completedProjects ?? 0}',
              enabled: false,
              primaryColor: primaryColor,
            ),
            _FormField(
              label: 'Đang học',
              value: '${snapshot.inProgressCourses ?? 0}',
              enabled: false,
              primaryColor: primaryColor,
            ),
            _FormField(
              label: 'Chưa bắt đầu',
              value: '${snapshot.notStartedCourses ?? 0}',
              enabled: false,
              primaryColor: primaryColor,
            ),
          ] else if (snapshot != null && snapshot.isAdmin) ...[
            _FormField(
              label: 'Tổng người dùng',
              value: '${snapshot.totalUsers ?? 0}',
              enabled: false,
              primaryColor: primaryColor,
            ),
            _FormField(
              label: 'Tổng dự án',
              value: '${snapshot.totalProjects ?? 0}',
              enabled: false,
              primaryColor: primaryColor,
            ),
            _FormField(
              label: 'Hoàn thành',
              value: '${snapshot.completedCourses ?? 0}',
              enabled: false,
              primaryColor: primaryColor,
            ),
            _FormField(
              label: 'Đang học',
              value: '${snapshot.inProgressCourses ?? 0}',
              enabled: false,
              primaryColor: primaryColor,
            ),
            _FormField(
              label: 'Chưa bắt đầu',
              value: '${snapshot.notStartedCourses ?? 0}',
              enabled: false,
              primaryColor: primaryColor,
            ),
          ],
          _FormField(
            label: 'Ghi chú',
            value: _extractField(controller.text, 'notes'),
            enabled: true,
            primaryColor: primaryColor,
            multiline: true,
            hint: 'Nhập ghi chú, nhận xét về báo cáo...',
          ),
          _FormField(
            label: 'Hành động cần thực hiện',
            value: _extractField(controller.text, 'actionItems'),
            enabled: true,
            primaryColor: primaryColor,
            multiline: true,
            hint: 'Liệt kê các hành động cần thực hiện...',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF9C3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_rounded, size: 14, color: Color(0xFFB45309)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chuyển sang chế độ JSON để chỉnh sửa chi tiết hơn.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _extractField(String json, String key) {
    try {
      if (json.isEmpty) return '';
      final map = jsonDecode(json) as Map<String, dynamic>;
      final val = map[key];
      if (val == null) return '';
      if (val is List) return val.toString();
      return val.toString();
    } catch (_) {
      return '';
    }
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final String value;
  final bool enabled;
  final Color primaryColor;
  final bool multiline;
  final String? hint;

  const _FormField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.primaryColor,
    this.multiline = false,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: value,
            enabled: enabled,
            maxLines: multiline ? 3 : 1,
            style: TextStyle(
              fontSize: 14,
              color: enabled ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: enabled ? Colors.white : const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: enabled ? const Color(0xFFE2E8F0) : const Color(0xFFE2E8F0),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: primaryColor, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// SNAPSHOT REFERENCE (Read-only)
// ================================================================

class _SnapshotReference extends StatelessWidget {
  final ReportDetailResponse report;
  final Color primaryColor;

  const _SnapshotReference({required this.report, required this.primaryColor});

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
                'Dữ liệu Snapshot (Chỉ đọc)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded, size: 11, color: Color(0xFF16A34A)),
                    SizedBox(width: 4),
                    Text(
                      'IMMUTABLE',
                      style: TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Dữ liệu bên dưới được cố định tại thời điểm tạo báo cáo, không thể chỉnh sửa.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          if (snapshot == null)
            _buildRawData()
          else if (snapshot.isMentor)
            _buildMentorSnapshotData(snapshot)
          else if (snapshot.isPm)
            _buildPmSnapshotData(snapshot)
          else if (snapshot.isAdmin)
            _buildAdminSnapshotData(snapshot),
        ],
      ),
    );
  }

  Widget _buildRawData() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SelectableText(
        report.dataJson ?? '{}',
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }

  Widget _buildMentorSnapshotData(ReportSnapshotData s) {
    return Column(
      children: [
        _ReadOnlyField(label: 'Dự án được giao', value: '${s.assignedProjects ?? 0}'),
        _ReadOnlyField(label: 'Hoàn thành', value: '${s.completedCourses ?? 0}'),
        _ReadOnlyField(label: 'Đang học', value: '${s.inProgressCourses ?? 0}'),
        _ReadOnlyField(label: 'Chưa bắt đầu', value: '${s.notStartedCourses ?? 0}'),
        _ReadOnlyField(label: 'Tổng', value: '${s.totalCourses}'),
        _ReadOnlyField(label: 'Tỷ lệ hoàn thành', value: '${s.completionRate.toStringAsFixed(1)}%'),
      ],
    );
  }

  Widget _buildPmSnapshotData(ReportSnapshotData s) {
    return Column(
      children: [
        _ReadOnlyField(label: 'Tổng dự án', value: '${s.totalProjects ?? 0}'),
        _ReadOnlyField(label: 'Hoàn thành', value: '${s.completedProjects ?? 0}'),
        _ReadOnlyField(label: 'Hoàn thành (khóa học)', value: '${s.completedCourses ?? 0}'),
        _ReadOnlyField(label: 'Đang học', value: '${s.inProgressCourses ?? 0}'),
        _ReadOnlyField(label: 'Chưa bắt đầu', value: '${s.notStartedCourses ?? 0}'),
        _ReadOnlyField(label: 'Tỷ lệ hoàn thành', value: '${s.completionRate.toStringAsFixed(1)}%'),
      ],
    );
  }

  Widget _buildAdminSnapshotData(ReportSnapshotData s) {
    return Column(
      children: [
        _ReadOnlyField(label: 'Tổng người dùng', value: '${s.totalUsers ?? 0}'),
        _ReadOnlyField(label: 'Tổng dự án', value: '${s.totalProjects ?? 0}'),
        _ReadOnlyField(label: 'Hoàn thành', value: '${s.completedCourses ?? 0}'),
        _ReadOnlyField(label: 'Đang học', value: '${s.inProgressCourses ?? 0}'),
        _ReadOnlyField(label: 'Chưa bắt đầu', value: '${s.notStartedCourses ?? 0}'),
        _ReadOnlyField(label: 'Tổng khóa học', value: '${s.totalCourses}'),
        _ReadOnlyField(label: 'Tỷ lệ hoàn thành', value: '${s.completionRate.toStringAsFixed(1)}%'),
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const Icon(Icons.lock_outline_rounded, size: 12, color: Color(0xFF16A34A)),
        ],
      ),
    );
  }
}
