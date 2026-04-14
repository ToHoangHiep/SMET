import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/service/pm/pm_dashboard_service.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/service/common/global_notification_service.dart';

// ============================================================
// INSIGHT DETAIL SCREEN
// GET /api/pm/insights/{id}
// GET /api/pm/insights/{id}/preview
// POST /api/pm/insights/{id}/execute
// ============================================================
class InsightDetailScreen extends StatefulWidget {
  final int insightId;

  const InsightDetailScreen({super.key, required this.insightId});

  @override
  State<InsightDetailScreen> createState() => _InsightDetailScreenState();
}

class _InsightDetailScreenState extends State<InsightDetailScreen> {
  static const _primary = Color(0xFF137FEC);
  static const _bgPage = Color(0xFFF3F6FC);
  static const _bgCard = Color(0xFFFFFFFF);
  static const _border = Color(0xFFE5E7EB);
  static const _textDark = Color(0xFF0F172A);
  static const _textMedium = Color(0xFF64748B);
  static const _textMuted = Color(0xFF94A3B8);
  static const _success = Color(0xFF22C55E);
  static const _warning = Color(0xFFF59E0B);
  static const _error = Color(0xFFEF4444);
  static const _info = Color(0xFF3B82F6);

  final _svc = PmDashboardService();

  InsightDetail? _detail;
  InsightPreview? _preview;
  bool _isLoadingDetail = true;
  bool _isLoadingPreview = false;
  bool _isExecuting = false;
  String? _errorMessage;

  // ============================================
  // LIFECYCLE
  // ============================================
  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoadingDetail = true;
      _errorMessage = null;
    });

    try {
      final detail = await _svc.getInsightDetail(widget.insightId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _isLoadingDetail = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể tải chi tiết insight.';
        _isLoadingDetail = false;
      });
    }
  }

  Future<void> _loadPreview() async {
    setState(() => _isLoadingPreview = true);

    try {
      final preview = await _svc.getInsightPreview(widget.insightId);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _isLoadingPreview = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingPreview = false);
    }
  }

  // ============================================
  // BUILD: PAGE HEADER
  // ============================================
  Widget _buildPageHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SharedBreadcrumb(
            items: const [
              BreadcrumbItem(label: 'PM', route: '/pm/dashboard'),
              BreadcrumbItem(label: 'Insights', route: '/pm/insights'),
              BreadcrumbItem(label: 'Chi tiết'),
            ],
            primaryColor: _primary,
            fontSize: 13,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lightbulb_rounded, color: _success, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _detail?.content ?? 'Insight chi tiết',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================
  // BUILD: INSIGHT DETAIL CARD
  // ============================================
  Widget _buildDetailCard() {
    final detail = _detail;
    if (detail == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: _primary, size: 18),
              SizedBox(width: 8),
              Text('Thông tin insight', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textDark)),
            ],
          ),
          const SizedBox(height: 16),
          _detailRow('Key', detail.insightKey),
          const Divider(height: 24),
          _detailRow('Nội dung', detail.content),
          if (detail.actionLabel != null) ...[
            const Divider(height: 24),
            _detailRow('Hành động', detail.actionLabel!),
          ],
          const Divider(height: 24),
          _detailRow('Tạo lúc', _formatDate(detail.createdAt)),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textMuted)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, color: _textDark)),
        ),
      ],
    );
  }

  // ============================================
  // BUILD: PREVIEW SECTION
  // ============================================
  Widget _buildPreviewSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.visibility_rounded, color: _primary, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Xem trước tác động',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textDark),
              ),
              const Spacer(),
              if (_preview == null && !_isLoadingPreview)
                TextButton.icon(
                  onPressed: _loadPreview,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Tải preview'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingPreview)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_preview == null)
            Container(
              padding: const EdgeInsets.all(24),
              child: const Center(
                child: Text(
                  'Nhấn "Tải preview" để xem trước tác động của hành động này.',
                  style: TextStyle(fontSize: 13, color: _textMuted),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else ...[
            _buildPreviewStatCard(
              Icons.people_rounded,
              '${_preview!.affectedUsers}',
              'Người dùng bị ảnh hưởng',
              _info,
            ),
            const SizedBox(height: 12),
            _buildPreviewStatCard(
              Icons.menu_book_rounded,
              '${_preview!.affectedCourses}',
              'Khóa học bị ảnh hưởng',
              _warning,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.description_rounded, size: 18, color: _textMedium),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _preview!.description,
                      style: const TextStyle(fontSize: 13, color: _textMedium),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================
  // BUILD: ACTION BUTTONS
  // ============================================
  Widget _buildActionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.flash_on_rounded, color: _warning, size: 18),
              SizedBox(width: 8),
              Text(
                'Thực hiện hành động',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textDark),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
              final actions = [
                _ActionOption('NOTIFY_USERS', 'Thông báo người dùng', Icons.notifications_rounded, _info),
                _ActionOption('EXTEND_DEADLINE', 'Gia hạn deadline', Icons.schedule_rounded, _warning),
                _ActionOption('ASSIGN_MENTOR', 'Chỉ định mentor', Icons.person_add_rounded, _success),
                _ActionOption('GENERATE_REPORT', 'Tạo báo cáo', Icons.summarize_rounded, _primary),
              ];

              if (isNarrow) {
                return Column(
                  children: actions.map((a) => _buildActionBtn(a, fullWidth: true)).toList(),
                );
              }

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: actions.map((a) => _buildActionBtn(a, fullWidth: false)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(_ActionOption action, {required bool fullWidth}) {
    final canExecute = _preview != null;

    return InkWell(
      onTap: canExecute ? () => _showExecuteSheet(action) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: canExecute
              ? action.color.withValues(alpha: 0.08)
              : _textMuted.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: canExecute
                ? action.color.withValues(alpha: 0.3)
                : _textMuted.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Icon(
              action.icon,
              color: canExecute ? action.color : _textMuted,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                action.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: canExecute ? action.color : _textMuted,
                ),
              ),
            ),
            if (canExecute)
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: action.color.withValues(alpha: 0.6),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // EXECUTE BOTTOM SHEET
  // ============================================
  void _showExecuteSheet(_ActionOption action) {
    final preview = _preview;
    if (preview == null) return;

    final messageController = TextEditingController();
    final extendDaysController = TextEditingController(text: '3');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(action.icon, color: action.color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Thực hiện: ${action.label}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Confirmation notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: _warning, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Hành động này sẽ ảnh hưởng tới ${preview.affectedUsers} người dùng và ${preview.affectedCourses} khóa học.',
                      style: const TextStyle(fontSize: 13, color: _textDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Message input (for NOTIFY_USERS)
            if (action.key == 'NOTIFY_USERS') ...[
              const Text('Tin nhắn (tùy chọn)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textMedium)),
              const SizedBox(height: 8),
              TextField(
                controller: messageController,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn thông báo...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
            ],

            // Extend days input (for EXTEND_DEADLINE)
            if (action.key == 'EXTEND_DEADLINE') ...[
              const Text('Số ngày gia hạn', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textMedium)),
              const SizedBox(height: 8),
              TextField(
                controller: extendDaysController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Số ngày',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _executeAction(
                        action: action,
                        message: messageController.text,
                        extendDays: extendDaysController.text.isNotEmpty
                            ? int.tryParse(extendDaysController.text)
                            : null,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: action.color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Xác nhận', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ============================================
  // EXECUTE ACTION
  // ============================================
  Future<void> _executeAction({
    required _ActionOption action,
    String? message,
    int? extendDays,
  }) async {
    setState(() => _isExecuting = true);

    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận thực hiện'),
        content: Text(
          'Bạn có chắc chắn muốn thực hiện "${action.label}"? '
          'Hành động này sẽ ảnh hưởng tới ${_preview?.affectedUsers ?? 0} người dùng.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: action.color),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      setState(() => _isExecuting = false);
      return;
    }

    try {
      await _svc.executeInsightAction(
        insightId: widget.insightId,
        actionType: action.key,
        message: message,
        extendDays: extendDays,
      );

      if (!mounted) return;
      setState(() => _isExecuting = false);
      GlobalNotificationService.show(
        context: context,
        message: 'Thực hiện hành động thành công',
        type: NotificationType.success,
      );
      context.go('/pm/insights');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isExecuting = false);
      GlobalNotificationService.show(
        context: context,
        message: 'Thực hiện hành động thất bại',
        type: NotificationType.error,
      );
    }
  }

  // ============================================
  // UTILITIES
  // ============================================
  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // ============================================
  // MAIN BUILD
  // ============================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      body: _isLoadingDetail
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 48, color: _error.withValues(alpha: 0.7)),
                      const SizedBox(height: 16),
                      Text(_errorMessage ?? 'Lỗi', style: const TextStyle(fontSize: 14, color: _textMedium)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadDetail, child: const Text('Thử lại')),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPageHeader(),
                      const SizedBox(height: 20),
                      _buildDetailCard(),
                      const SizedBox(height: 20),
                      _buildPreviewSection(),
                      const SizedBox(height: 20),
                      _buildActionSection(),
                    ],
                  ),
                ),
    );
  }
}

// ============================================================
// ACTION OPTION
// ============================================================
class _ActionOption {
  final String key;
  final String label;
  final IconData icon;
  final Color color;

  _ActionOption(this.key, this.label, this.icon, this.color);
}
