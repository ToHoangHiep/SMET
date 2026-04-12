import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:smet/model/mentor_dashboard_models.dart';
import 'package:smet/service/mentor/mentor_dashboard_service.dart';
import 'package:smet/service/common/auth_service.dart';

/// Mentor Dashboard - Mobile Layout
/// Backend endpoints:
///   GET /api/mentor/dashboard/summary
///   GET /api/mentor/dashboard/progress
///   GET /api/lms/courses?isMine=true
///   GET /api/lms/live-sessions/course/{courseId}
class MentorDashboardMobile extends StatefulWidget {
  const MentorDashboardMobile({super.key});

  @override
  State<MentorDashboardMobile> createState() => _MentorDashboardMobileState();
}

class _MentorDashboardMobileState extends State<MentorDashboardMobile> {
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
      log("[MentorDashboardMobile] loadData failed: $e");
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể tải dữ liệu';
        _isLoading = false;
      });
    }
  }

  String get _greetingMessage {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  // ============================================
  // HEADER
  // ============================================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chào buổi sáng', // placeholder, will be replaced
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _userName.isNotEmpty ? _userName : 'Mentor',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // STATS (2x2 grid for mobile)
  // ============================================
  Widget _buildStatsSection() {
    final s = _summary ?? _emptySummary;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: [
          _buildStatCard(
            'Khóa học',
            '${s.totalCourses}',
            Icons.menu_book_rounded,
            _info,
          ),
          _buildStatCard(
            'Học viên',
            '${s.totalLearners}',
            Icons.people_rounded,
            _primary,
          ),
          _buildStatCard(
            'Thông báo chưa đọc',
            '${s.unreadNotifications}',
            Icons.notifications_rounded,
            _warning,
          ),
          _buildStatCard(
            'Deadline gần',
            '${s.upcomingDeadlines}',
            Icons.schedule_rounded,
            _colorError,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _textMedium,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // PROGRESS SECTION
  // ============================================
  Widget _buildProgressSection() {
    final p = _progress ?? _emptyProgress;
    final total = p.notStarted + p.inProgress + p.completed;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: _primary, size: 18),
              SizedBox(width: 6),
              Text(
                'Tiến độ học viên',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressBar(total, p.notStarted, p.inProgress, p.completed),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildProgressLegend('Chưa bắt đầu', p.notStarted, _textMuted),
              _buildProgressLegend('Đang học', p.inProgress, _warning),
              _buildProgressLegend('Hoàn thành', p.completed, _success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int total, int notStarted, int inProgress, int completed) {
    if (total == 0) {
      return Container(
        height: 12,
        decoration: BoxDecoration(
          color: _border,
          borderRadius: BorderRadius.circular(6),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Row(
        children: [
          if (completed > 0)
            Expanded(
              flex: completed,
              child: Container(height: 12, color: _success),
            ),
          if (inProgress > 0)
            Expanded(
              flex: inProgress,
              child: Container(height: 12, color: _warning),
            ),
          if (notStarted > 0)
            Expanded(
              flex: notStarted,
              child: Container(height: 12, color: _textMuted),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressLegend(String label, int count, Color color) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '$label\n$count',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _textMedium,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // LIVE SESSIONS SECTION
  // ============================================
  Widget _buildLiveSessionsSection() {
    final upcomingSessions = _liveSessions
        .where((s) => s.startTime.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.live_tv_rounded, color: _primary, size: 18),
              SizedBox(width: 6),
              Text(
                'Phiên học trực tiếp',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (upcomingSessions.isEmpty)
            _buildEmptyLiveSession()
          else
            ...upcomingSessions.take(3).map((s) => _buildLiveSessionItem(s)),
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
                    fontSize: 13,
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
                      style: TextStyle(fontSize: 11, color: badgeColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLiveSession() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.videocam_off_rounded, size: 32, color: _textMuted),
            const SizedBox(height: 8),
            Text(
              'Không có phiên học sắp tới',
              style: TextStyle(fontSize: 13, color: _textMuted),
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
  // LOADING
  // ============================================
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _primary, strokeWidth: 3),
          SizedBox(height: 16),
          Text(
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
  // ERROR
  // ============================================
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _colorError.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 40, color: _colorError),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Đã xảy ra lỗi',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Thử lại'),
            ),
          ],
        ),
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
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _errorMessage != null
                    ? _buildErrorState()
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 4),
                            _buildStatsSection(),
                            const SizedBox(height: 4),
                            _buildProgressSection(),
                            const SizedBox(height: 8),
                            _buildLiveSessionsSection(),
                            const SizedBox(height: 24),
                            Center(
                              child: Column(
                                children: [
                                  const Text(
                                    '© 2025 SMETS',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _greetingMessage,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: _textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
