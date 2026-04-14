import 'package:flutter/material.dart';
import 'package:smet/model/pm_dashboard_models.dart';
import 'package:smet/service/pm/pm_dashboard_service.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';

// ============================================================
// RISK SCREEN
// GET /api/pm/dashboard/risks?page=&size=
// ============================================================
class RiskScreen extends StatefulWidget {
  const RiskScreen({super.key});

  @override
  State<RiskScreen> createState() => _RiskScreenState();
}

class _RiskScreenState extends State<RiskScreen> {
  static const _primary = Color(0xFF137FEC);
  static const _bgPage = Color(0xFFF3F6FC);
  static const _bgCard = Color(0xFFFFFFFF);
  static const _border = Color(0xFFE5E7EB);
  static const _textDark = Color(0xFF0F172A);
  static const _textMedium = Color(0xFF64748B);
  static const _textMuted = Color(0xFF94A3B8);
  static const _warning = Color(0xFFF59E0B);
  static const _error = Color(0xFFEF4444);
  static const _info = Color(0xFF3B82F6);
  static const _success = Color(0xFF22C55E);

  final _svc = PmDashboardService();

  int _page = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  final _size = 10;

  List<PmRiskItem> _items = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRisks();
  }

  Future<void> _loadRisks({int page = 0}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _page = page;
    });

    try {
      final result = await _svc.getRisks(page: page, size: _size);
      if (!mounted) return;
      setState(() {
        _items = result.data;
        _totalPages = result.totalPages;
        _totalElements = result.totalElements;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể tải danh sách rủi ro.';
        _isLoading = false;
      });
    }
  }

  Color _colorForRiskType(String type) {
    switch (type) {
      case 'LOW_SCORE':
        return _error;
      case 'NO_ATTEMPT':
        return _warning;
      case 'DEADLINE_WARNING':
        return const Color(0xFFF97316);
      case 'INACTIVE':
        return _info;
      default:
        return _textMuted;
    }
  }

  IconData _iconForRiskType(String type) {
    switch (type) {
      case 'LOW_SCORE':
        return Icons.score_rounded;
      case 'NO_ATTEMPT':
        return Icons.assignment_rounded;
      case 'DEADLINE_WARNING':
        return Icons.schedule_rounded;
      case 'INACTIVE':
        return Icons.person_off_rounded;
      default:
        return Icons.warning_rounded;
    }
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
              BreadcrumbItem(label: 'Rủi ro', route: '/pm/risks'),
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
                  color: _warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.warning_rounded, color: _warning, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Học viên rủi ro',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _textDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tổng: $_totalElements học viên',
                      style: const TextStyle(fontSize: 13, color: _textMedium),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _loadRisks(),
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

  Widget _buildRiskList() {
    if (_isLoading) {
      return const Center(
        child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 56, color: _success.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              const Text(
                'Không có học viên rủi ro',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textDark),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tất cả học viên đều đang hoạt động tốt.',
                style: TextStyle(fontSize: 13, color: _textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                ),
                child: const Row(
                  children: [
                    Expanded(flex: 2, child: Text('Học viên', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textMedium))),
                    Expanded(flex: 1, child: Text('Loại rủi ro', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textMedium))),
                    Expanded(flex: 2, child: Text('Thông điệp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textMedium))),
                    Expanded(flex: 1, child: Text('Thời gian', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textMedium), textAlign: TextAlign.center)),
                  ],
                ),
              ),
              ..._items.asMap().entries.map((e) => _buildRiskRow(e.value, e.key.isEven)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildPagination(),
      ],
    );
  }

  Widget _buildRiskRow(PmRiskItem item, bool even) {
    final color = _colorForRiskType(item.riskType);
    final icon = _iconForRiskType(item.riskType);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: even ? const Color(0xFFF8FAFC) : _bgCard,
        border: const Border(top: BorderSide(color: _border, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Icon(Icons.person_rounded, size: 16, color: color),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.userName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textDark),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'ID: ${item.userId}',
                        style: const TextStyle(fontSize: 11, color: _textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 12, color: color),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      item.riskTypeLabel,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.message.isNotEmpty ? item.message : item.title,
              style: const TextStyle(fontSize: 12, color: _textMedium),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              _formatTime(item.createdAt),
              style: const TextStyle(fontSize: 11, color: _textMuted),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays > 0) return '${diff.inDays} ngày trước';
    if (diff.inHours > 0) return '${diff.inHours} giờ trước';
    if (diff.inMinutes > 0) return '${diff.inMinutes} phút trước';
    return 'Vừa xong';
  }

  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: _page > 0 ? () => _loadRisks(page: _page - 1) : null,
          color: _primary,
        ),
        Text(
          'Trang ${_page + 1} / $_totalPages',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textMedium),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: _page < _totalPages - 1 ? () => _loadRisks(page: _page + 1) : null,
          color: _primary,
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: _error.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text(_errorMessage ?? 'Đã xảy ra lỗi', style: const TextStyle(fontSize: 14, color: _textMedium)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadRisks(),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
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
            _buildRiskList(),
          ],
        ),
      ),
    );
  }
}
