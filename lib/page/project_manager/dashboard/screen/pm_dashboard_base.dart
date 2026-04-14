import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smet/model/pm_dashboard_models.dart' hide PageResponse;
import 'package:smet/model/report_model.dart';
import 'package:smet/service/pm/pm_dashboard_service.dart';
import 'package:smet/service/report/report_service.dart';
import 'package:smet/service/common/auth_service.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';

// ============================================================
// PM DASHBOARD SCREEN
// Sections:
//   1. KPI Cards   → GET /api/pm/dashboard
//   2. Line Chart  → GET /api/pm/dashboard/trends
//   3. Quick Panels: At Risk Users, Reports, Insights
// ============================================================
class PmDashboardScreen extends StatefulWidget {
  const PmDashboardScreen({super.key});

  @override
  State<PmDashboardScreen> createState() => _PmDashboardScreenState();
}

class _PmDashboardScreenState extends State<PmDashboardScreen> {
  // ============================================
  // COLORS
  // ============================================
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

  // ============================================
  // SERVICE
  // ============================================
  final _svc = PmDashboardService();

  // ============================================
  // STATE
  // ============================================
  bool _isLoading = true;
  String? _errorMessage;

  String _userName = 'PM';

  // Dashboard data
  PmDashboardSummary? _summary;
  PmTrendData? _trendData;
  List<DashboardInsight> _insights = [];

  // Quick counts
  int _atRiskCount = 0;
  int _pendingReportsCount = 0;

  // ============================================
  // LIFECYCLE
  // ============================================
  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService.getCurrentUser();
      _userName = user.fullName.trim().isNotEmpty ? user.fullName : user.email;
    } catch (e) {
      debugPrint('[PmDashboard] AuthService.getCurrentUser failed: $e');
    }

    // ===== Gọi tuần tự, mỗi API có try-catch riêng =====
    PmDashboardSummary? dashboard;
    try {
      dashboard = await _svc.getDashboard();
    } catch (e) {
      debugPrint('[PmDashboard] getDashboard failed: $e');
    }

    PmTrendData? trends;
    try {
      trends = await _svc.getTrends();
    } catch (e) {
      debugPrint('[PmDashboard] getTrends failed: $e');
    }

    List<DashboardInsight> insights = [];
    try {
      insights = await _svc.getInsights();
    } catch (e) {
      debugPrint('[PmDashboard] getInsights failed: $e');
    }

    int atRiskCount = 0;
    try {
      final risksPage = await _svc.getRisks(page: 0, size: 1);
      atRiskCount = risksPage.totalElements.toInt();
    } catch (e) {
      debugPrint('[PmDashboard] getRisks failed: $e');
    }

    int pendingReportsCount = 0;
    try {
      final reportsPage = await reportService.listReports(
        status: ReportStatus.SUBMITTED,
        page: 0,
        size: 1,
      );
      pendingReportsCount = reportsPage.totalElements.toInt();
    } catch (e) {
      debugPrint('[PmDashboard] listReports failed: $e');
    }

    if (!mounted) return;

    setState(() {
      _summary = dashboard ?? _emptySummary;
      _trendData = trends ?? _emptyTrend;
      _insights = insights;
      _atRiskCount = atRiskCount;
      _pendingReportsCount = pendingReportsCount;
      _isLoading = false;
    });
  }

  // ============================================
  // GREETING
  // ============================================
  String get _greetingMessage {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
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
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SharedBreadcrumb(
            items: const [
              BreadcrumbItem(label: 'PM', route: '/pm/dashboard'),
              BreadcrumbItem(label: 'Tổng quan'),
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
                  color: _primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.dashboard_rounded, color: _primary, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Tổng quan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
              ),
              IconButton(
                onPressed: _loadAllData,
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

  // ============================================
  // BUILD: WELCOME BANNER
  // ============================================
  Widget _buildWelcomeBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF137FEC), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greetingMessage,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userName,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Đây là tổng quan về hoạt động của dự án bạn quản lý.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.school_rounded, color: Colors.white.withValues(alpha: 0.9), size: 32),
                const SizedBox(height: 4),
                Text(
                  'SMETS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                Text(
                  'PM Portal',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // BUILD: KPI CARDS
  // ============================================
  Widget _buildKpiCards() {
    final s = _summary ?? _emptySummary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        final cards = <_KpiCardDef>[
          _KpiCardDef('Tổng học viên', s.totalUsers, Icons.people_rounded, _info),
          _KpiCardDef('Khóa học hoạt động', s.activeCourses, Icons.menu_book_rounded, _primary),
          _KpiCardDef('Tỷ lệ hoàn thành', s.completionRate.toStringAsFixed(1) + '%', Icons.check_circle_rounded, _success),
          _KpiCardDef('Quá hạn', s.overdueCount, Icons.warning_rounded, _error),
          _KpiCardDef('Học viên rủi ro', s.atRiskUsers, Icons.trending_down_rounded, _warning),
        ];

        if (isNarrow) {
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: cards.map((c) => _buildKpiCard(c)).toList(),
          );
        }

        return Row(
          children: cards.asMap().entries.map((e) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: e.key == 0 ? 0 : 6,
                  right: e.key == cards.length - 1 ? 0 : 6,
                ),
                child: _buildKpiCard(e.value),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildKpiCard(_KpiCardDef def) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: def.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(def.icon, color: def.color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            '${def.value}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: def.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            def.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textDark,
            ),
          ),
        ],
      ),
    );
  }

  PmDashboardSummary get _emptySummary => PmDashboardSummary(
        totalUsers: 0,
        activeCourses: 0,
        completionRate: 0,
        overdueCount: 0,
        atRiskUsers: 0,
      );

  PmTrendData get _emptyTrend => PmTrendData(
        enrollments: [],
        completions: [],
      );

  // ============================================
  // BUILD: TREND CHART
  // ============================================
  Widget _buildTrendSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
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
          const Row(
            children: [
              Icon(Icons.show_chart_rounded, color: _primary, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Xu hướng đăng ký & hoàn thành',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _legendDot('Đăng ký', _primary),
              const SizedBox(width: 16),
              _legendDot('Hoàn thành', _success),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: _buildLineChart(),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: _textMedium)),
      ],
    );
  }

  Widget _buildLineChart() {
    final trend = _trendData;

    if (trend == null || (trend.enrollments.isEmpty && trend.completions.isEmpty)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart_rounded, size: 40, color: _textMuted),
            const SizedBox(height: 8),
            const Text('Chưa có dữ liệu xu hướng', style: TextStyle(fontSize: 13, color: _textMuted)),
          ],
        ),
      );
    }

    final allPoints = <DateTime>[
      ...trend.enrollments.map((e) => e.date),
      ...trend.completions.map((c) => c.date),
    ];

    if (allPoints.isEmpty) {
      return const Center(child: Text('Chưa có dữ liệu', style: TextStyle(color: _textMuted)));
    }

    final minDate = allPoints.reduce((a, b) => a.isBefore(b) ? a : b);
    final maxDate = allPoints.reduce((a, b) => a.isAfter(b) ? a : b);
    final daySpan = maxDate.difference(minDate).inDays.toDouble();

    double maxVal = 1;
    for (final e in trend.enrollments) {
      if (e.value > maxVal) maxVal = e.value.toDouble();
    }
    for (final c in trend.completions) {
      if (c.value > maxVal) maxVal = c.value.toDouble();
    }

    List<FlSpot> enrollmentSpots = [];
    for (final e in trend.enrollments) {
      final x = daySpan == 0 ? 0.0 : e.date.difference(minDate).inDays.toDouble();
      enrollmentSpots.add(FlSpot(x, e.value.toDouble()));
    }

    List<FlSpot> completionSpots = [];
    for (final c in trend.completions) {
      final x = daySpan == 0 ? 0.0 : c.date.difference(minDate).inDays.toDouble();
      completionSpots.add(FlSpot(x, c.value.toDouble()));
    }

    enrollmentSpots.sort((a, b) => a.x.compareTo(b.x));
    completionSpots.sort((a, b) => a.x.compareTo(b.x));

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxVal / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: _border,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 11, color: _textMuted),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (daySpan == 0) return const SizedBox.shrink();
                final d = minDate.add(Duration(days: value.toInt()));
                return Text(
                  '${d.month}/${d.day}',
                  style: const TextStyle(fontSize: 10, color: _textMuted),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: maxVal + 1,
        lineBarsData: [
          LineChartBarData(
            spots: enrollmentSpots,
            isCurved: true,
            color: _primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: _primary.withValues(alpha: 0.08),
            ),
          ),
          LineChartBarData(
            spots: completionSpots,
            isCurved: true,
            color: _success,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: _success.withValues(alpha: 0.08),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              return spots.map((s) {
                final isEnrollment = s.barIndex == 0;
                return LineTooltipItem(
                  '${isEnrollment ? "Đăng ký" : "Hoàn thành"}: ${s.y.toInt()}',
                  TextStyle(
                    color: isEnrollment ? _primary : _success,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  // ============================================
  // BUILD: QUICK PANELS
  // ============================================
  Widget _buildQuickPanels() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return Column(
            children: [
              _buildRiskPanel(),
              const SizedBox(height: 12),
              _buildReportsPanel(),
              const SizedBox(height: 12),
              _buildInsightsPanel(),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildRiskPanel()),
            const SizedBox(width: 12),
            Expanded(child: _buildReportsPanel()),
            const SizedBox(width: 12),
            Expanded(child: _buildInsightsPanel()),
          ],
        );
      },
    );
  }

  Widget _buildRiskPanel() {
    return _QuickPanel(
      icon: Icons.warning_amber_rounded,
      iconColor: _warning,
      title: 'Học viên rủi ro',
      count: _atRiskCount,
      onTap: () => context.go('/pm/risks'),
      color: _warning,
    );
  }

  Widget _buildReportsPanel() {
    return _QuickPanel(
      icon: Icons.description_rounded,
      iconColor: _info,
      title: 'Báo cáo chờ duyệt',
      count: _pendingReportsCount,
      onTap: () => context.go('/reports'),
      color: _info,
    );
  }

  Widget _buildInsightsPanel() {
    return _QuickPanel(
      icon: Icons.lightbulb_outline_rounded,
      iconColor: _success,
      title: 'Insights',
      count: _insights.length,
      onTap: () => context.go('/pm/insights'),
      color: _success,
    );
  }

  // ============================================
  // BUILD: ERROR STATE
  // ============================================
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 48, color: _error),
            ),
            const SizedBox(height: 20),
            Text(
              _errorMessage ?? 'Đã xảy ra lỗi',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAllData,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Thử lại', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // BUILD: LOADING STATE
  // ============================================
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(color: _primary, strokeWidth: 3),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Đang tải dữ liệu...',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textMedium),
          ),
        ],
      ),
    );
  }

  // ============================================
  // MAIN BUILD
  // ============================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            color: _bgPage,
            child: _buildPageHeader(),
          ),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _errorMessage != null
                    ? _buildErrorState()
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 1100) {
                            return _buildWebLayout();
                          }
                          return _buildNarrowLayout();
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeBanner(),
          const SizedBox(height: 20),
          _buildKpiCards(),
          const SizedBox(height: 20),
          _buildTrendSection(),
          const SizedBox(height: 20),
          _buildQuickPanels(),
          const SizedBox(height: 32),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeBanner(),
          const SizedBox(height: 16),
          _buildKpiCards(),
          const SizedBox(height: 16),
          _buildTrendSection(),
          const SizedBox(height: 16),
          _buildQuickPanels(),
          const SizedBox(height: 24),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school, color: _primary.withValues(alpha: 0.6), size: 16),
              const SizedBox(width: 4),
              const Text(
                'SMETS',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _textMedium),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('© 2025 SMETS. Bảo lưu mọi quyền.', style: TextStyle(fontSize: 11, color: _textMuted)),
        ],
      ),
    );
  }
}

// ============================================================
// INTERNAL: KPI Card Definition
// ============================================================
class _KpiCardDef {
  final String label;
  final dynamic value;
  final IconData icon;
  final Color color;

  _KpiCardDef(this.label, this.value, this.icon, this.color);
}

// ============================================================
// INTERNAL: Quick Panel Widget
// ============================================================
class _QuickPanel extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final int count;
  final VoidCallback onTap;
  final Color color;

  const _QuickPanel({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.count,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
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
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
