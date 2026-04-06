import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/model/mentor_enrollment_model.dart';
import 'package:smet/model/mentor_live_session_model.dart';
import 'package:smet/model/project_model.dart';
import 'package:smet/model/mentor_dashboard_models.dart';
import 'package:smet/service/mentor/mentor_dashboard_service.dart';
import 'package:smet/service/common/auth_service.dart';

/// Mentor Dashboard - Web Layout
/// Hiển thị tổng quan với dữ liệu thực từ API
class MentorDashboardWeb extends StatefulWidget {
  const MentorDashboardWeb({super.key});

  @override
  State<MentorDashboardWeb> createState() => _MentorDashboardWebState();
}

class _MentorDashboardWebState extends State<MentorDashboardWeb> {
  // ============================================
  // COLORS - consistent with mentor theme
  // ============================================
  static const _primary = Color(0xFF6366F1);
  static const _bgPage = Color(0xFFF3F6FC);
  static const _bgCard = Color(0xFFFFFFFF);
  static const _border = Color(0xFFE5E7EB);
  static const _textDark = Color(0xFF0F172A);
  static const _textMedium = Color(0xFF64748B);
  static const _textMuted = Color(0xFF94A3B8);

  // Semantic colors
  static const _success = Color(0xFF22C55E);
  static const _warning = Color(0xFFF59E0B);
  static const _colorError = Color(0xFFEF4444);
  static const _info = Color(0xFF3B82F6);

  // Badge backgrounds
  static const _badgeGreenBg = Color(0xFFDCFCE7);
  static const _badgeRedBg = Color(0xFFFEE2E2);
  static const _badgeYellowBg = Color(0xFFFEF3C7);
  static const _badgeBlueBg = Color(0xFFDBEAFE);
  static const _badgeGrayBg = Color(0xFFF1F5F9);

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
  // COMPUTED DATA
  // ============================================
  MentorDashboardStats get _stats => MentorDashboardStats.fromData(
        courses: _courses,
        enrollments: _allEnrollments,
        sessions: _allSessions,
        projects: _projects,
      );

  List<CourseOverviewItem> get _courseItems => _courses
      .take(5)
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

  List<ProjectOverviewItem> get _projectItems => _projects.take(4).map((p) {
        return ProjectOverviewItem(
          project: p,
          memberCount: p.memberIds?.length ?? 0,
          stageLabel: p.status.label,
        );
      }).toList();

  List<LiveSessionInfo> get _upcomingSessionsList {
    final now = DateTime.now();
    final list = _allSessions
        .where((s) => s.startTime != null && s.startTime!.isAfter(now))
        .toList();
    list.sort((a, b) => a.startTime!.compareTo(b.startTime!));
    return list.take(5).toList();
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
      // Load user info
      final user = await AuthService.getCurrentUser();
      _userName = user.fullName.trim().isNotEmpty
          ? user.fullName.trim()
          : user.email;

      // Load all dashboard data in parallel
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
      log("[MentorDashboard] loadData failed: $e");
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
  // FORMAT HELPERS
  // ============================================
  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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
                child: const Icon(
                  Icons.dashboard_rounded,
                  color: _primary,
                  size: 22,
                ),
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
  // BUILD: STATS CARDS
  // ============================================
  Widget _buildStatsSection() {
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
              _buildStatCard(
                'Khóa học',
                '${_stats.totalCourses}',
                '${_stats.publishedCourses} đã xuất bản',
                Icons.menu_book_rounded,
                _info,
              ),
              _buildStatCard(
                'Học viên',
                '${_stats.totalStudents}',
                '${_stats.activeStudents} đang học',
                Icons.people_rounded,
                _primary,
              ),
              _buildStatCard(
                'Live Sessions',
                '${_stats.upcomingSessions}',
                'buổi sắp tới',
                Icons.live_tv_rounded,
                _warning,
              ),
              _buildStatCard(
                'Dự án',
                '${_stats.totalProjects}',
                '${_stats.pendingReviewProjects} đang hoạt động',
                Icons.work_rounded,
                _success,
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Khóa học',
                '${_stats.totalCourses}',
                '${_stats.publishedCourses} đã xuất bản',
                Icons.menu_book_rounded,
                _info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Học viên',
                '${_stats.totalStudents}',
                '${_stats.activeStudents} đang học',
                Icons.people_rounded,
                _primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Live Sessions',
                '${_stats.upcomingSessions}',
                'buổi sắp tới',
                Icons.live_tv_rounded,
                _warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Dự án',
                '${_stats.totalProjects}',
                '${_stats.pendingReviewProjects} đang hoạt động',
                Icons.work_rounded,
                _success,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
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
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: _textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // BUILD: COURSE OVERVIEW
  // ============================================
  Widget _buildCourseOverviewSection() {
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
                child: Text(
                  'Khóa học của tôi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/mentor/courses'),
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_courseItems.isEmpty)
            _buildEmptyState(
              icon: Icons.menu_book_outlined,
              message: 'Chưa có khóa học nào',
              subMessage: 'Tạo khóa học đầu tiên để bắt đầu',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _courseItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
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
    final progressColor = course.published ? _success : _warning;

    return InkWell(
      onTap: () => context.go('/mentor/courses'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: _primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
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
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: course.published
                              ? _badgeGreenBg
                              : _badgeYellowBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          course.published ? 'Đã xuất bản' : 'Nháp',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color:
                                course.published ? _success : _warning,
                          ),
                        ),
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
                                Text(
                                  '$progress% hoàn thành',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _textDark,
                                  ),
                                ),
                                Text(
                                  '${item.studentCount} học viên',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: _textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress / 100,
                                backgroundColor: _border,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    progressColor),
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
      ),
    );
  }

  // ============================================
  // BUILD: OVERDUE STUDENTS (RIGHT COLUMN)
  // ============================================
  Widget _buildOverdueSection() {
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _colorError.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_rounded,
                    color: _colorError, size: 16),
              ),
              const SizedBox(width: 8),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          const SizedBox(height: 16),
          if (_overdueStudents.isEmpty)
            _buildEmptyState(
              icon: Icons.check_circle_outline_rounded,
              message: 'Không có học viên quá hạn',
              subMessage: 'Tất cả học viên đang tiến độ tốt',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _overdueStudents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _buildOverdueItem(_overdueStudents[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildOverdueItem(OverdueStudentItem item) {
    final enrollment = item.enrollment;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _badgeRedBg.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _colorError.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _colorError.withValues(alpha: 0.1),
            child: Text(
              enrollment.initials,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _colorError,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enrollment.userName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.courseTitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${enrollment.progress}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _colorError,
                ),
              ),
              if (enrollment.deadline != null)
                Text(
                  _formatDeadline(enrollment.deadline!),
                  style: const TextStyle(
                    fontSize: 10,
                    color: _colorError,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================
  // BUILD: LIVE SESSIONS (RIGHT COLUMN)
  // ============================================
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
              const Icon(Icons.live_tv_rounded, color: _info, size: 20),
              const SizedBox(width: 8),
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
              TextButton(
                onPressed: () => context.go('/mentor/live-sessions'),
                child: const Text(
                  'Xem lịch',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_upcomingSessionsList.isEmpty)
            _buildEmptyState(
              icon: Icons.videocam_off_rounded,
              message: 'Không có buổi học',
              subMessage: 'Các buổi học sẽ xuất hiện khi có lịch',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _upcomingSessionsList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
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

    final badgeColor = isSoon
        ? _colorError
        : isToday
            ? _warning
            : _info;
    final badgeBg = isSoon
        ? _badgeRedBg
        : isToday
            ? _badgeYellowBg
            : _badgeBlueBg;

    String timeLabel;
    if (diff.inMinutes < 60) {
      timeLabel = 'Sau ${diff.inMinutes} phút';
    } else if (isToday) {
      timeLabel = 'Hôm nay, ${_formatTime(start)}';
    } else {
      timeLabel = '${_formatDate(start)}, ${_formatTime(start)}';
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.live_tv_rounded,
              color: badgeColor,
              size: 20,
            ),
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
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (session.meetingUrl != null && session.meetingUrl!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _info,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Tham gia',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================
  // BUILD: PROJECTS SECTION
  // ============================================
  Widget _buildProjectsSection() {
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
              const Icon(Icons.work_rounded, color: _success, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Dự án đang hướng dẫn',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/mentor/projects'),
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_projectItems.isEmpty)
            _buildEmptyState(
              icon: Icons.work_outline_rounded,
              message: 'Chưa có dự án nào',
              subMessage: 'Dự án sẽ xuất hiện khi được phân công',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                if (isWide) {
                  return Row(
                    children: _projectItems
                        .map((item) => Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                    right: item != _projectItems.last ? 12 : 0),
                                child: _buildProjectItem(item),
                              ),
                            ))
                        .toList(),
                  );
                }
                return Column(
                  children: _projectItems
                      .map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildProjectItem(item),
                          ))
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildProjectItem(ProjectOverviewItem item) {
    final project = item.project;
    final statusColor = _getProjectStatusColor(project.status);
    final statusBg = _getProjectStatusBg(project.status);

    return InkWell(
      onTap: () => context.go('/mentor/projects'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.folder_rounded,
                    color: statusColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        project.leaderName ?? 'Không xác định',
                        style: const TextStyle(
                          fontSize: 11,
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
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item.stageLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.people_outline_rounded, size: 14, color: _textMuted),
                const SizedBox(width: 4),
                Text(
                  '${item.memberCount} thành viên',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getProjectStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.ACTIVE:
        return _info;
      case ProjectStatus.COMPLETED:
        return _success;
      case ProjectStatus.INACTIVE:
        return _textMuted;
    }
  }

  Color _getProjectStatusBg(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.ACTIVE:
        return _badgeBlueBg;
      case ProjectStatus.COMPLETED:
        return _badgeGreenBg;
      case ProjectStatus.INACTIVE:
        return _badgeGrayBg;
    }
  }

  // ============================================
  // BUILD: EMPTY STATE
  // ============================================
  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String subMessage,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: _textMuted,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textMedium,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subMessage,
              style: const TextStyle(
                fontSize: 11,
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
            const SizedBox(height: 8),
            Text(
              'Vui lòng kiểm tra kết nối và thử lại',
              style: TextStyle(
                fontSize: 13,
                color: _textMedium,
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
  // BUILD: MAIN BODY
  // ============================================
  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) {
          return _buildWebLayout();
        } else {
          return _buildNarrowLayout();
        }
      },
    );
  }

  // Wide layout: 3-column grid
  Widget _buildWebLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: 20),
          _buildStatsSection(),
          const SizedBox(height: 20),
          // 3-column: course list | overdue | sessions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Course overview (wider)
              Expanded(
                flex: 2,
                child: _buildCourseOverviewSection(),
              ),
              const SizedBox(width: 20),
              // Right: Overdue + Sessions
              Expanded(
                child: Column(
                  children: [
                    _buildOverdueSection(),
                    const SizedBox(height: 20),
                    _buildLiveSessionsSection(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Projects section
          _buildProjectsSection(),
          const SizedBox(height: 32),
          // Footer
          _buildFooter(),
        ],
      ),
    );
  }

  // Narrow layout: stacked
  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: 16),
          _buildStatsSection(),
          const SizedBox(height: 16),
          _buildCourseOverviewSection(),
          const SizedBox(height: 16),
          _buildOverdueSection(),
          const SizedBox(height: 16),
          _buildLiveSessionsSection(),
          const SizedBox(height: 16),
          _buildProjectsSection(),
          const SizedBox(height: 24),
          _buildFooter(),
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
              Icon(Icons.school, color: _primary.withValues(alpha: 0.6), size: 16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'Hỗ trợ',
                style: TextStyle(fontSize: 12, color: _textMuted),
              ),
              SizedBox(width: 16),
              Text(
                'Chính sách bảo mật',
                style: TextStyle(fontSize: 12, color: _textMuted),
              ),
              SizedBox(width: 16),
              Text(
                'Điều khoản dịch vụ',
                style: TextStyle(fontSize: 12, color: _textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '© 2025 SMETS. Bảo lưu mọi quyền.',
            style: TextStyle(fontSize: 11, color: _textMuted),
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
          // Fixed page header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            color: _bgPage,
            child: _buildPageHeader(),
          ),
          // Scrollable content
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}
