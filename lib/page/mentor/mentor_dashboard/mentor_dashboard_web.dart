import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/model/mentor_dashboard_models.dart';
import 'package:smet/service/mentor/mentor_dashboard_service.dart';
import 'package:smet/service/common/auth_service.dart';

/// Mentor Dashboard - Web Layout
/// Backend endpoints:
///   GET /api/mentor/dashboard/summary
///   GET /api/mentor/dashboard/progress
///   GET /api/lms/live-sessions/live-sessions
class MentorDashboardWeb extends StatefulWidget {
  const MentorDashboardWeb({super.key});

  @override
  State<MentorDashboardWeb> createState() => _MentorDashboardWebState();
}

class _MentorDashboardWebState extends State<MentorDashboardWeb> {
  // ============================================
  // COLORS
  // ============================================
  static const _primary = Color(0xFF6366F1);
  static const _bgPage = Color(0xFFF3F6FC);
  static const _bgCard = Color(0xFFFFFFFF);
  static const _border = Color(0xFFE5E7EB);
  static const _textDark = Color(0xFF0F172A);
  static const _textMedium = Color(0xFF64748B);
  static const _textMuted = Color(0xFF94A3B8);
  static const _success = Color(0xFF22C55E);
  static const _warning = Color(0xFFF59E0B);
  static const _colorError = Color(0xFFEF4444);
  static const _info = Color(0xFF3B82F6);

  // ============================================
  // SERVICES
  // ============================================
  final _dashboardService = MentorDashboardService();

  // ============================================
  // STATE
  // ============================================
  bool _isLoading = true;
  String? _errorMessage;
  String _userName = '';
  MentorDashboardSummary? _summary;
  MentorDashboardProgress? _progress;
  List<MentorLiveSession> _liveSessions = [];

  // ============================================
  // LIFECYCLE
  // ============================================
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService.getCurrentUser();
      _userName = user.fullName.trim().isNotEmpty
          ? user.fullName.trim()
          : user.email;

      final results = await _dashboardService.loadDashboardData();

      if (!mounted) return;

      setState(() {
        _summary = results.summary;
        _progress = results.progress;
        _liveSessions = results.liveSessions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể tải dữ liệu dashboard. Vui lòng thử lại.';
        _isLoading = false;
      });
    }
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
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SharedBreadcrumb(
            items: const [
              BreadcrumbItem(label: "Mentor", route: "/mentor/dashboard"),
              BreadcrumbItem(label: "Tổng quan"),
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _textDark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================
  // BUILD: WELCOME SECTION
  // ============================================
  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: _primary.withValues(alpha: 0.25),
          blurRadius: 16,
          offset: const Offset(0, 4),
        )],
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
                  _userName.isNotEmpty ? _userName : 'Mentor',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Đây là tổng quan về hoạt động hướng dẫn của bạn.',
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
                Icon(
                  Icons.school_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 32,
                ),
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
                  'Mentor Portal',
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
  // BUILD: SUMMARY CARDS
  // ============================================
  Widget _buildSummaryCards() {
    final s = _summary ?? _emptySummary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        final cards = [
          _SummaryCardData('Khóa học', s.totalCourses, Icons.menu_book_rounded, _info),
          _SummaryCardData('Học viên', s.totalLearners, Icons.people_rounded, _primary),
          _SummaryCardData('Thông báo chưa đọc', s.unreadNotifications, Icons.notifications_rounded, _warning),
          _SummaryCardData('Deadline gần', s.upcomingDeadlines, Icons.schedule_rounded, _colorError),
        ];

        if (isNarrow) {
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: cards.map((c) => _buildSummaryCard(c)).toList(),
          );
        }

        return Row(
          children: cards.map((c) {
            final idx = cards.indexOf(c);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: idx == 0 ? 0 : 6, right: idx == cards.length - 1 ? 0 : 6),
                child: _buildSummaryCard(c),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSummaryCard(_SummaryCardData data) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            '${data.value}',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: data.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // BUILD: PROGRESS SECTION
  // ============================================
  Widget _buildProgressSection() {
    final p = _progress ?? _emptyProgress;
    final total = p.notStarted + p.inProgress + p.completed;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_rounded, color: _primary, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tiến độ khóa học',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 700) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: _buildPieChart(total, p),
                    ),
                    const SizedBox(width: 32),
                    Expanded(child: _buildProgressLegend(p)),
                  ],
                );
              }
              return Column(
                children: [
                  SizedBox(height: 180, child: _buildPieChart(total, p)),
                  const SizedBox(height: 16),
                  _buildProgressLegend(p),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(int total, MentorDashboardProgress p) {
    if (total == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline, size: 48, color: _textMuted),
            const SizedBox(height: 8),
            const Text(
              'Chưa có dữ liệu',
              style: TextStyle(fontSize: 13, color: _textMuted),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: 200,
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 50,
          sections: [
            PieChartSectionData(
              value: p.completed.toDouble(),
              title: '${(p.completed / total * 100).toStringAsFixed(0)}%',
              color: _success,
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            PieChartSectionData(
              value: p.inProgress.toDouble(),
              title: '${(p.inProgress / total * 100).toStringAsFixed(0)}%',
              color: _warning,
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            PieChartSectionData(
              value: p.notStarted.toDouble(),
              title: '${(p.notStarted / total * 100).toStringAsFixed(0)}%',
              color: _textMuted,
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressLegend(MentorDashboardProgress p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chi tiết tiến độ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 16),
        _buildLegendRow('Hoàn thành', p.completed, _success),
        const SizedBox(height: 10),
        _buildLegendRow('Đang học', p.inProgress, _warning),
        const SizedBox(height: 10),
        _buildLegendRow('Chưa bắt đầu', p.notStarted, _textMuted),
        const SizedBox(height: 16),
        const Divider(color: _border),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tổng học viên',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textDark),
            ),
            Text(
              '${p.notStarted + p.inProgress + p.completed}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendRow(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: _textMedium),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================
  // BUILD: LIVE SESSIONS SECTION
  // ============================================
  Widget _buildLiveSessionsSection() {
    final upcomingSessions = _liveSessions
        .where((s) => s.startTime.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

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
              Icon(Icons.live_tv_rounded, color: _primary, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Phiên học trực tiếp',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (upcomingSessions.isEmpty)
            _buildEmptyLiveSession()
          else
            ...upcomingSessions.take(5).map((s) => _buildLiveSessionItem(s)),
        ],
      ),
    );
  }

  Widget _buildLiveSessionItem(MentorLiveSession session) {
    final now = DateTime.now();
    final diff = session.startTime.difference(now);

    String timeLabel;
    Color badgeColor;
    if (diff.isNegative) {
      timeLabel = 'Đã diễn ra';
      badgeColor = _textMuted;
    } else if (diff.inMinutes < 60) {
      timeLabel = 'Sau ${diff.inMinutes} phút';
      badgeColor = _colorError;
    } else if (diff.inHours < 24) {
      timeLabel = 'Hôm nay, ${_formatTime(session.startTime)}';
      badgeColor = _warning;
    } else {
      timeLabel = '${_formatDate(session.startTime)}, ${_formatTime(session.startTime)}';
      badgeColor = _info;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.live_tv_rounded, color: _primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 12, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      timeLabel,
                      style: TextStyle(fontSize: 12, color: badgeColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (session.joinUrl != null && session.joinUrl!.isNotEmpty && !diff.isNegative)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Bắt đầu',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyLiveSession() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.videocam_off_rounded, size: 40, color: _textMuted),
            const SizedBox(height: 8),
            Text(
              'Không có phiên học sắp tới',
              style: TextStyle(fontSize: 14, color: _textMuted),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
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
                color: _colorError.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: _colorError,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _errorMessage ?? 'Đã xảy ra lỗi',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Thử lại',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
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
              child: CircularProgressIndicator(
                color: _primary,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Đang tải dữ liệu...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textMedium,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // BUILD: FOOTER
  // ============================================
  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school,
                color: _primary.withValues(alpha: 0.6),
                size: 16,
              ),
              const SizedBox(width: 4),
              const Text(
                'SMETS',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: _textMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '© 2025 SMETS. Bảo lưu mọi quyền.',
            style: TextStyle(fontSize: 11, color: _textMuted),
          ),
        ],
      ),
    );
  }

  // ============================================
  // EMPTY PLACEHOLDERS
  // ============================================
  MentorDashboardSummary get _emptySummary => MentorDashboardSummary(
        totalCourses: 0,
        totalLearners: 0,
        unreadNotifications: 0,
        upcomingDeadlines: 0,
      );

  MentorDashboardProgress get _emptyProgress => MentorDashboardProgress(
        notStarted: 0,
        inProgress: 0,
        completed: 0,
      );

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
          _buildWelcomeSection(),
          const SizedBox(height: 20),
          _buildSummaryCards(),
          const SizedBox(height: 20),
          _buildProgressSection(),
          const SizedBox(height: 20),
          _buildLiveSessionsSection(),
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
          _buildWelcomeSection(),
          const SizedBox(height: 16),
          _buildSummaryCards(),
          const SizedBox(height: 16),
          _buildProgressSection(),
          const SizedBox(height: 16),
          _buildLiveSessionsSection(),
          const SizedBox(height: 24),
          _buildFooter(),
        ],
      ),
    );
  }
}

// ============================================
// INTERNAL DATA CLASS
// ============================================
class _SummaryCardData {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  _SummaryCardData(this.label, this.value, this.icon, this.color);
}
