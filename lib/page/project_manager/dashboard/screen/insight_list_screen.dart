import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/pm_dashboard_models.dart';
import 'package:smet/service/pm/pm_dashboard_service.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';

// ============================================================
// INSIGHT LIST SCREEN
// GET /api/pm/dashboard/insights
// ============================================================
class InsightListScreen extends StatefulWidget {
  const InsightListScreen({super.key});

  @override
  State<InsightListScreen> createState() => _InsightListScreenState();
}

class _InsightListScreenState extends State<InsightListScreen> {
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

  List<DashboardInsight> _items = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _svc.getInsights();
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể tải insights.';
        _isLoading = false;
      });
    }
  }

  Color _colorForKey(String key) {
    final k = key.toUpperCase();
    if (k.contains('RISK') || k.contains('LOW')) return _error;
    if (k.contains('WARNING') || k.contains('DEADLINE')) return _warning;
    if (k.contains('SUCCESS') || k.contains('COMPLETE')) return _success;
    if (k.contains('INFO') || k.contains('TREND')) return _info;
    return _primary;
  }

  IconData _iconForKey(String key) {
    final k = key.toUpperCase();
    if (k.contains('RISK') || k.contains('LOW')) return Icons.trending_down_rounded;
    if (k.contains('WARNING') || k.contains('DEADLINE')) return Icons.warning_rounded;
    if (k.contains('SUCCESS') || k.contains('COMPLETE')) return Icons.check_circle_rounded;
    if (k.contains('USER') || k.contains('ENROLL')) return Icons.people_rounded;
    if (k.contains('COURSE') || k.contains('LEARN')) return Icons.menu_book_rounded;
    return Icons.lightbulb_rounded;
  }

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Insights',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _textDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_items.length} insights được phát hiện',
                      style: const TextStyle(fontSize: 13, color: _textMedium),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loadInsights,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Làm mới',
                color: _textMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightList() {
    if (_isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: _error.withValues(alpha: 0.7)),
              const SizedBox(height: 16),
              Text(_errorMessage ?? 'Lỗi', style: const TextStyle(fontSize: 14, color: _textMedium)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadInsights, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 56, color: _textMuted.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              const Text('Không có insight nào', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textDark)),
              const SizedBox(height: 8),
              const Text('Hệ thống chưa phát hiện insight nào tại thời điểm này.', style: TextStyle(fontSize: 13, color: _textMuted)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _items.map((item) => _buildInsightCard(item)).toList(),
    );
  }

  Widget _buildInsightCard(DashboardInsight item) {
    final color = _colorForKey(item.insightKey);
    final icon = _iconForKey(item.insightKey);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/pm/insights/${item.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item.insightKey,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatRelative(item.createdAt),
                            style: const TextStyle(fontSize: 11, color: _textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.content,
                        style: const TextStyle(fontSize: 14, color: _textDark),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (item.actionLabel != null && item.actionLabel!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item.actionLabel!,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white),
                                ],
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _textMuted.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Xem chi tiết',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textMuted),
                              ),
                            ),
                          ],
                          const Spacer(),
                          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatRelative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays} ngày trước';
    if (diff.inHours > 0) return '${diff.inHours} giờ trước';
    if (diff.inMinutes > 0) return '${diff.inMinutes} phút trước';
    return 'Vừa xong';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(),
            const SizedBox(height: 20),
            _buildInsightList(),
          ],
        ),
      ),
    );
  }
}
