import 'package:flutter/material.dart';
import 'package:smet/service/employee/employee_dashboard_service.dart';
import 'package:smet/service/common/auth_service.dart';
import 'package:smet/model/employee_dashboard_models.dart';

// ============================================================
// EMPLOYEE DASHBOARD - Full UI
// Backend endpoints:
//   GET /api/user/dashboard/overview
//   GET /api/lms/enrollments/my-courses
//   GET /api/lms/live-sessions/live-sessions
//   GET /api/leaderboard
// ============================================================
class EmployeeDashboardPage extends StatefulWidget {
  const EmployeeDashboardPage({super.key});

  @override
  State<EmployeeDashboardPage> createState() => _EmployeeDashboardPageState();
}

class _EmployeeDashboardPageState extends State<EmployeeDashboardPage> {
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
  static const _colorError = Color(0xFFEF4444);
  static const _info = Color(0xFF3B82F6);
  static const _purple = Color(0xFF8B5CF6);

  // ============================================
  // SERVICE
  // ============================================
  final _dashboardService = EmployeeDashboardService();

  // ============================================
  // STATE
  // ============================================
  bool _isLoading = true;
  String? _error;
  String _userName = '';

  UserDashboardOverview _overview = UserDashboardOverview.empty();
  List<MyCourse> _courses = [];
  List<LiveSession> _liveSessions = [];
  List<LeaderboardItem> _leaderboard = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final user = await AuthService.getCurrentUser();
      _userName = user.fullName.trim().isNotEmpty
          ? user.fullName.trim()
          : user.email;

      final data = await _dashboardService.loadDashboardData();

      if (!mounted) return;

      setState(() {
        _overview = data.overview;
        _courses = data.courses;
        _liveSessions = data.liveSessions;
        _leaderboard = data.leaderboard;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Không thể tải dữ liệu dashboard';
      });
    }
  }

  // ============================================
  // COMPUTED
  // ============================================
  int get _completedCourses =>
      _courses.where((c) => c.status == EnrollmentStatus.completed).length;
  int get _inProgressCourses =>
      _courses.where((c) => c.status == EnrollmentStatus.inProgress).length;
  double get _avgProgress {
    if (_courses.isEmpty) return 0;
    final total = _courses.fold<double>(0, (sum, c) => sum + c.progress);
    return total / _courses.length;
  }

  List<MyCourse> get _upcomingDeadlines {
    final now = DateTime.now();
    return _courses
        .where((c) => c.deadline != null && c.deadline!.isAfter(now))
        .toList()
      ..sort((a, b) => a.deadline!.compareTo(b.deadline!));
  }

  List<LiveSession> get _upcomingSessions {
    final now = DateTime.now();
    return _liveSessions
        .where((s) => s.startTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
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
  // BUILD: WELCOME
  // ============================================
  Widget _buildWelcomeSection() {
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
            color: _primary.withValues(alpha: 0.25),
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
                  _userName.isNotEmpty ? _userName : 'Người dùng',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tiếp tục hành trình học tập của bạn hôm nay!',
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
                Icon(Icons.school_rounded,
                    color: Colors.white.withValues(alpha: 0.9), size: 32),
                const SizedBox(height: 4),
                Text('SMETS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.9),
                    )),
                Text('Learning Portal',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.7),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // BUILD: CURRENT COURSE
  // ============================================
  Widget _buildCurrentCourseSection() {
    final hasCourse = _overview.hasCourse;

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
          Row(
            children: [
              const Icon(Icons.play_circle_filled_rounded,
                  color: _primary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Khóa học hiện tại',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textDark)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasCourse)
            _buildEmptyState(
              icon: Icons.school_outlined,
              message: 'Bạn chưa đăng ký khóa học nào',
              subMessage: 'Khám phá danh mục để bắt đầu học ngay!',
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _primary.withValues(alpha: 0.05),
                    _info.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primary.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.school_rounded,
                            color: _primary, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _overview.courseTitle,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _textDark),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_overview.progress.toStringAsFixed(0)}% hoàn thành',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _primary),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (_overview.resumeLessonId != 0) {
                            debugPrint(
                                'Resume lesson: ${_overview.resumeLessonId}');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: const Text('Tiếp tục',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (_overview.progress / 100).clamp(0.0, 1.0),
                      backgroundColor: _border,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(_primary),
                      minHeight: 10,
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
  // BUILD: STATS CARDS
  // ============================================
  Widget _buildStatsCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        if (isNarrow) {
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _buildStatCard('Hoàn thành', '$_completedCourses',
                  Icons.check_circle_outline_rounded, _success, 'Khóa học'),
              _buildStatCard('Đang học', '$_inProgressCourses',
                  Icons.play_circle_outline_rounded, _primary, 'Khóa học'),
              _buildStatCard(
                  'Tiến độ TB',
                  '${_avgProgress.toStringAsFixed(0)}%',
                  Icons.trending_up_rounded,
                  _purple,
                  'Hoàn thành'),
              _buildStatCard('Tổng khóa', '${_courses.length}',
                  Icons.library_books_rounded, _info, 'Khóa học'),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
                child: _buildStatCard(
                    'Hoàn thành',
                    '$_completedCourses',
                    Icons.check_circle_outline_rounded,
                    _success,
                    'Khóa học')),
            const SizedBox(width: 12),
            Expanded(
                child: _buildStatCard('Đang học', '$_inProgressCourses',
                    Icons.play_circle_outline_rounded, _primary, 'Khóa học')),
            const SizedBox(width: 12),
            Expanded(
                child: _buildStatCard(
                    'Tiến độ TB',
                    '${_avgProgress.toStringAsFixed(0)}%',
                    Icons.trending_up_rounded,
                    _purple,
                    'Hoàn thành')),
            const SizedBox(width: 12),
            Expanded(
                child: _buildStatCard('Tổng khóa', '${_courses.length}',
                    Icons.library_books_rounded, _info, 'Khóa học')),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon,
      Color color, String unit) {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(unit,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(value,
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: _textDark)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ============================================
  // BUILD: DEADLINES & LIVE SESSIONS
  // ============================================
  Widget _buildDeadlinesAndSessions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildDeadlinesSection()),
              const SizedBox(width: 20),
              Expanded(child: _buildLiveSessionsSection()),
            ],
          );
        }
        return Column(
          children: [
            _buildDeadlinesSection(),
            const SizedBox(height: 16),
            _buildLiveSessionsSection(),
          ],
        );
      },
    );
  }

  Widget _buildDeadlinesSection() {
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
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  color: _colorError, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Deadline sắp tới',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textDark)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_upcomingDeadlines.isEmpty)
            _buildEmptyState(
              icon: Icons.event_available_rounded,
              message: 'Không có deadline',
              subMessage: 'Bạn không có deadline nào trong thời gian tới',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _upcomingDeadlines.take(3).length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _buildDeadlineItem(_upcomingDeadlines[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildDeadlineItem(MyCourse course) {
    final isOverdue = course.overdue;
    final daysLeft = course.deadline != null
        ? course.deadline!.difference(DateTime.now()).inDays
        : 0;
    final isDueSoon = daysLeft <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOverdue
            ? const Color(0xFFFEF2F2)
            : isDueSoon
                ? const Color(0xFFFFF7ED)
                : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOverdue
              ? const Color(0xFFFEE2E2)
              : isDueSoon
                  ? const Color(0xFFFED7AA)
                  : _border,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                Text(
                  _getMonthName(course.deadline!.month),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isOverdue ? _colorError : _textMedium,
                  ),
                ),
                Text(
                  '${course.deadline!.day}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isOverdue ? _colorError : _textDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      daysLeft == 0
                          ? 'Hôm nay'
                          : daysLeft == 1
                              ? 'Ngày mai'
                              : 'Còn $daysLeft ngày',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isOverdue
                            ? _colorError
                            : isDueSoon
                                ? _warning
                                : _textMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${course.progress.toStringAsFixed(0)}%',
                        style: const TextStyle(
                            fontSize: 11, color: _textMuted)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveSessionsSection() {
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
          Row(
            children: [
              const Icon(Icons.live_tv_rounded, color: _primary, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Phiên học trực tiếp',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textDark)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_upcomingSessions.isEmpty)
            _buildEmptyState(
              icon: Icons.videocam_off_rounded,
              message: 'Không có phiên học',
              subMessage: 'Các buổi học trực tiếp sẽ xuất hiện khi có lịch',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _upcomingSessions.take(3).length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _buildLiveSessionItem(_upcomingSessions[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildLiveSessionItem(LiveSession session) {
    final now = DateTime.now();
    final diff = session.startTime.difference(now);

    String timeLabel;
    Color badgeColor;
    if (diff.isNegative) {
      timeLabel = 'Đã diễn ra';
      badgeColor = _textMuted;
    } else if (diff.inMinutes < 60) {
      timeLabel = 'Bắt đầu sau ${diff.inMinutes} phút';
      badgeColor = _colorError;
    } else if (diff.inHours < 24) {
      timeLabel = 'Hôm nay, ${_formatTime(session.startTime)}';
      badgeColor = _warning;
    } else {
      timeLabel =
          '${_formatDate(session.startTime)}, ${_formatTime(session.startTime)}';
      badgeColor = _primary;
    }

    return Container(
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
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.live_tv_rounded,
                color: _primary, size: 22),
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
                      color: _textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 12, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(timeLabel,
                        style:
                            TextStyle(fontSize: 11, color: badgeColor)),
                  ],
                ),
              ],
            ),
          ),
          if (session.joinUrl != null &&
              session.joinUrl!.isNotEmpty &&
              !diff.isNegative)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: _primary, borderRadius: BorderRadius.circular(6)),
              child: const Text('Tham gia',
                  style:
                      TextStyle(fontSize: 11, color: Colors.white)),
            ),
        ],
      ),
    );
  }

  // ============================================
  // BUILD: LEADERBOARD
  // ============================================
  Widget _buildLeaderboardSection() {
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
          Row(
            children: [
              const Icon(Icons.leaderboard_rounded, color: _purple, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Bảng xếp hạng',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textDark)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_rounded, size: 14, color: _purple),
                    const SizedBox(width: 4),
                    Text(
                      '${_leaderboard.length} người',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _purple,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_leaderboard.isEmpty)
            _buildEmptyState(
              icon: Icons.emoji_events_outlined,
              message: 'Chưa có dữ liệu',
              subMessage: 'Hoàn thành khóa học để xếp hạng',
            )
          else ...[
            _buildLeaderboardPodium(),
            const SizedBox(height: 20),
            _buildLeaderboardStats(),
            const SizedBox(height: 20),
            _buildLeaderboardTable(),
          ],
        ],
      ),
    );
  }

  // ============================================
  // BUILD: PODIUM TOP 3
  // ============================================
  Widget _buildLeaderboardPodium() {
    final top3 = _leaderboard.take(3).toList();
    if (top3.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (top3.length >= 2)
          _buildPodiumItem(top3[1], 2, 80),
        const SizedBox(width: 8),
        if (top3.isNotEmpty)
          _buildPodiumItem(top3[0], 1, 100),
        const SizedBox(width: 8),
        if (top3.length >= 3)
          _buildPodiumItem(top3[2], 3, 60),
      ],
    );
  }

  Widget _buildPodiumItem(LeaderboardItem item, int rank, double height) {
    Color bgColor;
    Color textColor;
    Color rankColor;

    switch (rank) {
      case 1:
        bgColor = const Color(0xFFFFD700).withValues(alpha: 0.15);
        textColor = const Color(0xFFB8860B);
        rankColor = const Color(0xFFFFD700);
        break;
      case 2:
        bgColor = const Color(0xFFC0C0C0).withValues(alpha: 0.15);
        textColor = const Color(0xFF71717A);
        rankColor = const Color(0xFFC0C0C0);
        break;
      default:
        bgColor = const Color(0xFFCD7F32).withValues(alpha: 0.15);
        textColor = const Color(0xFF92400E);
        rankColor = const Color(0xFFCD7F32);
    }

    final nameParts = item.userName.split(' ');
    final displayName = nameParts.length > 1 ? nameParts.last : item.userName;
    final initials = nameParts.map((p) => p.isNotEmpty ? p[0] : '').take(2).join();

    return Expanded(
      child: Column(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: rankColor, width: 2),
            ),
            child: Center(
              child: Text(
                initials.toUpperCase(),
                style: TextStyle(
                  fontSize: rank == 1 ? 16 : 14,
                  fontWeight: FontWeight.bold,
                  color: rankColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Name
          Text(
            displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // Score
          Text(
            '${item.finalScore.toStringAsFixed(0)} điểm',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: textColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          // Podium block
          Container(
            height: height,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(
                top: BorderSide(color: rankColor, width: 2),
                left: BorderSide(color: rankColor.withValues(alpha: 0.3)),
                right: BorderSide(color: rankColor.withValues(alpha: 0.3)),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    rank == 1
                        ? Icons.emoji_events_rounded
                        : Icons.military_tech_rounded,
                    color: rankColor,
                    size: rank == 1 ? 28 : 22,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: rankColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '#$rank',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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

  // ============================================
  // BUILD: STATS ROW
  // ============================================
  Widget _buildLeaderboardStats() {
    if (_leaderboard.isEmpty) return const SizedBox.shrink();

    final topScore = _leaderboard.isNotEmpty
        ? _leaderboard.first.finalScore
        : 0.0;
    final avgAll = _leaderboard.fold<double>(0, (sum, e) => sum + e.finalScore) /
        _leaderboard.length;

    final myRankItem = _leaderboard.isNotEmpty ? _leaderboard.first : null;
    final myRank = myRankItem?.rank ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatMini(
            'Điểm cao nhất',
            '${topScore.toStringAsFixed(0)}',
            Icons.star_rounded,
            const Color(0xFFFFD700),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatMini(
            'Điểm trung bình',
            '${avgAll.toStringAsFixed(0)}',
            Icons.analytics_rounded,
            _info,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatMini(
            'Top cao nhất',
            '#$myRank',
            Icons.emoji_events_rounded,
            _purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatMini(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: _textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // BUILD: FULL TABLE (4-10)
  // ============================================
  Widget _buildLeaderboardTable() {
    final rest = _leaderboard.skip(3).take(7).toList();
    if (rest.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bảng xếp hạng đầy đủ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _textMedium,
          ),
        ),
        const SizedBox(height: 12),
        ...rest.map((item) => _buildLeaderboardRow(item)),
      ],
    );
  }

  Widget _buildLeaderboardRow(LeaderboardItem item) {
    Color rankColor;
    IconData? rankIcon;

    if (item.rank <= 3) {
      rankColor = const Color(0xFFFFD700);
      rankIcon = Icons.emoji_events_rounded;
    } else if (item.rank <= 10) {
      rankColor = _purple;
      rankIcon = Icons.star_rounded;
    } else {
      rankColor = _textMuted;
      rankIcon = null;
    }

    final nameParts = item.userName.split(' ');
    final initials = nameParts.map((p) => p.isNotEmpty ? p[0] : '').take(2).join();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 32,
            child: rankIcon != null
                ? Icon(rankIcon, color: rankColor, size: 18)
                : Text(
                    '#${item.rank}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: rankColor,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Name
          Expanded(
            child: Text(
              item.userName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Courses
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${item.completedCourses} khóa',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _success,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Score
          Text(
            '${item.finalScore.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // BUILD: COURSE LIST
  // ============================================
  Widget _buildCourseListSection() {
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
          Row(
            children: [
              const Icon(Icons.library_books_rounded,
                  color: _primary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Khóa học của tôi',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textDark)),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Xem tất cả',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _primary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_courses.isEmpty)
            _buildEmptyState(
              icon: Icons.school_outlined,
              message: 'Bạn chưa đăng ký khóa học nào',
              subMessage: 'Khám phá danh mục để bắt đầu học ngay!',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _courses.take(3).length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _buildCourseCard(_courses[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(MyCourse course) {
    final progress = course.progress.toInt();
    final statusColor = _getStatusColor(course.status);
    final statusLabel = course.status.label;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12)),
            child:
                const Icon(Icons.school_rounded, color: Color(0xFF94A3B8), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(course.title,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(statusLabel,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('$progress% hoàn thành',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                              if (course.deadline != null)
                                Text(_formatDeadline(course.deadline!),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: course.overdue
                                          ? _colorError
                                          : _textMuted,
                                    )),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress / 100,
                              backgroundColor: _border,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(statusColor),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
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

  Color _getStatusColor(EnrollmentStatus status) {
    switch (status) {
      case EnrollmentStatus.completed:
        return _success;
      case EnrollmentStatus.inProgress:
        return _primary;
      case EnrollmentStatus.notStarted:
        return _textMuted;
      default:
        return _textMuted;
    }
  }

  // ============================================
  // HELPERS
  // ============================================
  Widget _buildEmptyState(
      {required IconData icon,
      required String message,
      required String subMessage}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9), shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: const Color(0xFFCBD5E1)),
            ),
            const SizedBox(height: 12),
            Text(message,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textMedium)),
            const SizedBox(height: 4),
            Text(subMessage,
                style: const TextStyle(fontSize: 12, color: _textMuted),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    if (difference.isNegative) {
      return 'Đã quá hạn';
    } else if (difference.inDays == 0) {
      return 'Hôm nay';
    } else if (difference.inDays == 1) {
      return 'Ngày mai';
    } else if (difference.inDays < 7) {
      return 'Còn ${difference.inDays} ngày';
    } else {
      return 'Còn ${(difference.inDays / 7).ceil()} tuần';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  // ============================================
  // BODY
  // ============================================
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 64, color: _colorError),
            const SizedBox(height: 16),
            Text(_error!,
                style: const TextStyle(fontSize: 16, color: _textMedium)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboardData,
              style: ElevatedButton.styleFrom(backgroundColor: _primary),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return _buildWebLayout();
        } else {
          return _buildMobileLayout();
        }
      },
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
          _buildCurrentCourseSection(),
          const SizedBox(height: 20),
          _buildStatsCards(),
          const SizedBox(height: 20),
          _buildDeadlinesAndSessions(),
          const SizedBox(height: 20),
          _buildLeaderboardSection(),
          const SizedBox(height: 20),
          _buildCourseListSection(),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: 16),
          _buildCurrentCourseSection(),
          const SizedBox(height: 16),
          _buildStatsCards(),
          const SizedBox(height: 16),
          _buildDeadlinesAndSessions(),
          const SizedBox(height: 16),
          _buildLeaderboardSection(),
          const SizedBox(height: 16),
          _buildCourseListSection(),
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
      body: _buildBody(),
    );
  }
}
