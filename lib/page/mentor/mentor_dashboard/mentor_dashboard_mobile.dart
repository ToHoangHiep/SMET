import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/model/mentor_enrollment_model.dart';
import 'package:smet/model/mentor_live_session_model.dart';
import 'package:smet/model/project_model.dart';
import 'package:smet/model/mentor_dashboard_models.dart';
import 'package:smet/service/mentor/mentor_dashboard_service.dart';
import 'package:smet/service/common/auth_service.dart';

/// Mentor Dashboard - Mobile Layout
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
  static const _badgeGreenBg = Color(0xFFDCFCE7);
  static const _badgeRedBg = Color(0xFFFEE2E2);
  static const _badgeYellowBg = Color(0xFFFEF3C7);
  static const _badgeBlueBg = Color(0xFFDBEAFE);

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

  List<CourseResponse> _courses = [];
  List<MentorEnrollmentInfo> _allEnrollments = [];
  List<LiveSessionInfo> _allSessions = [];
  List<ProjectModel> _projects = [];

  // ============================================
  // COMPUTED
  // ============================================
  MentorDashboardStats get _stats => MentorDashboardStats.fromData(
        courses: _courses,
        enrollments: _allEnrollments,
        sessions: _allSessions,
        projects: _projects,
      );

  List<CourseOverviewItem> get _courseItems => _courses
      .take(3)
      .map((c) => CourseOverviewItem.from(c, _allEnrollments))
      .toList();

  List<OverdueStudentItem> get _overdueStudents => _allEnrollments
      .where((e) => e.isOverdue)
      .take(5)
      .map((e) {
        final course = _courses.cast<CourseResponse?>().firstWhere(
              (c) => c?.id.value == e.courseId.value,
              orElse: () => null,
            );
        return OverdueStudentItem(
          enrollment: e,
          courseTitle: course?.title ?? '',
        );
      })
      .toList();

  List<LiveSessionInfo> get _upcomingSessionsList {
    final now = DateTime.now();
    final list = _allSessions
        .where((s) => s.startTime != null && s.startTime!.isAfter(now))
        .toList();
    list.sort((a, b) => a.startTime!.compareTo(b.startTime!));
    return list.take(3).toList();
  }

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

      final rawData = await _dashboardService.loadDashboardData();

      if (!mounted) return;

      setState(() {
        _courses = rawData.courses;
        _allEnrollments = rawData.enrollments;
        _allSessions = rawData.sessions;
        _projects = rawData.projects;
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

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greetingMessage,
                        style: const TextStyle(
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
          ],
        ),
      ),
    );
  }

  // ============================================
  // STATS (2x2 grid for mobile)
  // ============================================
  Widget _buildStatsSection() {
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
            '${_stats.totalCourses}',
            Icons.menu_book_rounded,
            _info,
          ),
          _buildStatCard(
            'Học viên',
            '${_stats.totalStudents}',
            Icons.people_rounded,
            _primary,
          ),
          _buildStatCard(
            'Live Sessions',
            '${_stats.upcomingSessions}',
            Icons.live_tv_rounded,
            _warning,
          ),
          _buildStatCard(
            'Dự án',
            '${_stats.totalProjects}',
            Icons.work_rounded,
            _success,
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
  // COURSE OVERVIEW
  // ============================================
  Widget _buildCourseOverviewSection() {
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
          Row(
            children: [
              const Icon(Icons.library_books_rounded, color: _primary, size: 18),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Khóa học của tôi',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/mentor/courses'),
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_courseItems.isEmpty)
            _buildEmptyState(
              Icons.menu_book_outlined,
              'Chưa có khóa học nào',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _courseItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _buildCourseItem(_courseItems[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCourseItem(CourseOverviewItem item) {
    final course = item.course;
    final progress = item.avgProgress;

    return InkWell(
      onTap: () => context.go('/mentor/courses'),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.school_rounded, color: _primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          course.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: course.published ? _badgeGreenBg : _badgeYellowBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          course.published ? 'Đã xuất bản' : 'Nháp',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: course.published ? _success : _warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            backgroundColor: _border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              course.published ? _success : _warning,
                            ),
                            minHeight: 5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$progress%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _textMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // OVERDUE STUDENTS
  // ============================================
  Widget _buildOverdueSection() {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: _colorError.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_rounded, color: _colorError, size: 14),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Học viên quá hạn',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _badgeRedBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_stats.overdueStudents}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _colorError,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_overdueStudents.isEmpty)
            _buildEmptyState(Icons.check_circle_outline_rounded, 'Tất cả học viên đang tiến độ tốt')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _overdueStudents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _buildOverdueItem(_overdueStudents[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildOverdueItem(OverdueStudentItem item) {
    final e = item.enrollment;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _badgeRedBg.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _colorError.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: _colorError.withValues(alpha: 0.1),
            child: Text(
              e.initials,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _colorError,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.userName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.courseTitle,
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
          Text(
            '${e.progress}%',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _colorError,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // LIVE SESSIONS
  // ============================================
  Widget _buildLiveSessionsSection() {
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
          Row(
            children: [
              const Icon(Icons.live_tv_rounded, color: _info, size: 18),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Buổi học sắp tới',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/mentor/live-sessions'),
                child: const Text(
                  'Xem lịch',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_upcomingSessionsList.isEmpty)
            _buildEmptyState(Icons.videocam_off_rounded, 'Không có buổi học sắp tới')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _upcomingSessionsList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _buildSessionItem(_upcomingSessionsList[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSessionItem(LiveSessionInfo session) {
    final now = DateTime.now();
    final DateTime? nullableStart = session.startTime;
    if (nullableStart == null) return const SizedBox.shrink();
    final start = nullableStart;

    final diff = start.difference(now);
    final isToday = start.year == now.year &&
        start.month == now.month &&
        start.day == now.day;
    final isSoon = diff.inMinutes <= 60 && diff.inMinutes > 0;

    final badgeColor = isSoon ? _colorError : isToday ? _warning : _info;
    final badgeBg = isSoon ? _badgeRedBg : isToday ? _badgeYellowBg : _badgeBlueBg;

    String timeLabel;
    if (diff.inMinutes < 60) {
      timeLabel = 'Sau ${diff.inMinutes} phút';
    } else if (isToday) {
      timeLabel = 'Hôm nay, ${_formatTime(start)}';
    } else {
      timeLabel = '${_formatDate(start)}, ${_formatTime(start)}';
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.live_tv_rounded, color: badgeColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 11, color: badgeColor),
                    const SizedBox(width: 3),
                    Text(
                      timeLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: badgeColor,
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

  // ============================================
  // EMPTY STATE
  // ============================================
  Widget _buildEmptyState(IconData icon, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 28, color: _textMuted),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: _textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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
                            _buildCourseOverviewSection(),
                            const SizedBox(height: 12),
                            _buildOverdueSection(),
                            const SizedBox(height: 12),
                            _buildLiveSessionsSection(),
                            const SizedBox(height: 24),
                            // Footer
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
                                  const SizedBox(height: 16),
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
}
