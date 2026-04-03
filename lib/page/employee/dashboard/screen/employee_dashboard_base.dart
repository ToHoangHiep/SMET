import 'package:flutter/material.dart';
import 'package:smet/service/employee/lms_service.dart';
import 'package:smet/service/common/auth_service.dart';

class EmployeeDashboardStats {
  final int completedCourses;
  final int inProgressCourses;
  final double learningHours;
  final double avgScore;
  final List<EnrolledCourse> recentCourses;
  final List<LiveSessionInfo> liveSessions;

  EmployeeDashboardStats({
    required this.completedCourses,
    required this.inProgressCourses,
    required this.learningHours,
    required this.avgScore,
    required this.recentCourses,
    required this.liveSessions,
  });
}

class EmployeeDashboardPage extends StatefulWidget {
  const EmployeeDashboardPage({super.key});

  @override
  State<EmployeeDashboardPage> createState() => _EmployeeDashboardPageState();
}

class _EmployeeDashboardPageState extends State<EmployeeDashboardPage> {
  EmployeeDashboardStats _stats = EmployeeDashboardStats(
    completedCourses: 0,
    inProgressCourses: 0,
    learningHours: 0,
    avgScore: 0,
    recentCourses: [],
    liveSessions: [],
  );
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      await AuthService.getCurrentUser();
      final myCoursesResult = await LmsService.getMyCourses(page: 0, size: 10);

      int completed = 0;
      int inProgress = 0;
      double totalHours = 0;
      double totalProgress = 0;
      int progressedCount = 0;

      final courses = myCoursesResult.content;

      for (var course in courses) {
        final progress = course.progressPercent;

        if (course.status == EnrollmentStatus.completed) {
          completed++;
          inProgress++;
        } else if (progress > 0) {
          inProgress++;
        }

        totalHours += (progress / 100) * 10;

        if (progress > 0) {
          totalProgress += progress;
          progressedCount++;
        }
      }

      if (progressedCount > 0) {
        totalProgress = totalProgress / progressedCount;
      }

      final List<LiveSessionInfo> allLiveSessions = [];
      final futures = courses.map((c) => LmsService.getLiveSessions(c.id));
      final results = await Future.wait(futures);
      for (var sessions in results) {
        allLiveSessions.addAll(sessions);
      }
      allLiveSessions.sort((a, b) => a.startTime.compareTo(b.startTime));

      final now = DateTime.now();
      final upcomingSessions = allLiveSessions
          .where((s) => s.startTime.isAfter(now))
          .take(5)
          .toList();

      if (!mounted) return;

      setState(() {
        _stats = EmployeeDashboardStats(
          completedCourses: completed,
          inProgressCourses: inProgress,
          learningHours: totalHours,
          avgScore: totalProgress,
          recentCourses: courses.take(3).toList(),
          liveSessions: upcomingSessions,
        );
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

  String get greetingMessage {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  Widget buildWelcomeSection(String userName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              greetingMessage,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            if (userName.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF137FEC),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Tiếp tục hành trình học tập của bạn hôm nay!',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget buildStatsCards() {
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
                'Hoàn thành',
                '${_stats.completedCourses}',
                Icons.check_circle_outline_rounded,
                const Color(0xFF22C55E),
                'Khóa học',
              ),
              _buildStatCard(
                'Đang học',
                '${_stats.inProgressCourses}',
                Icons.play_circle_outline_rounded,
                const Color(0xFF137FEC),
                'Khóa học',
              ),
              _buildStatCard(
                'Giờ học',
                '${_stats.learningHours.toStringAsFixed(1)}',
                Icons.schedule_rounded,
                const Color(0xFFF97316),
                'Giờ',
              ),
              _buildStatCard(
                'Tiến độ TB',
                '${_stats.avgScore.toStringAsFixed(0)}%',
                Icons.trending_up_rounded,
                const Color(0xFF8B5CF6),
                'Hoàn thành',
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Hoàn thành',
                '${_stats.completedCourses}',
                Icons.check_circle_outline_rounded,
                const Color(0xFF22C55E),
                'Khóa học',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Đang học',
                '${_stats.inProgressCourses}',
                Icons.play_circle_outline_rounded,
                const Color(0xFF137FEC),
                'Khóa học',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Giờ học',
                '${_stats.learningHours.toStringAsFixed(1)}',
                Icons.schedule_rounded,
                const Color(0xFFF97316),
                'Giờ',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Tiến độ TB',
                '${_stats.avgScore.toStringAsFixed(0)}%',
                Icons.trending_up_rounded,
                const Color(0xFF8B5CF6),
                'Hoàn thành',
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
    IconData icon,
    Color color,
    String unit,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCourseList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.library_books_rounded, color: Color(0xFF137FEC), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Khóa học của tôi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF137FEC),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_stats.recentCourses.isEmpty)
            _buildEmptyState(
              icon: Icons.school_outlined,
              message: 'Bạn chưa đăng ký khóa học nào',
              subMessage: 'Khám phá danh mục để bắt đầu học ngay!',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _stats.recentCourses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final course = _stats.recentCourses[index];
                return _buildCourseCard(course);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(EnrolledCourse course) {
    final progress = course.progressPercent.toInt();
    final statusColor = _getStatusColor(course.status);
    final statusLabel = _getStatusLabel(course.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Color(0xFF94A3B8),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
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
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
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
                                ),
                              ),
                              if (course.deadline != null)
                                Text(
                                  _formatDeadline(course.deadline!),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: course.deadlineStatus == DeadlineStatus.overdue
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress / 100,
                              backgroundColor: const Color(0xFFE5E7EB),
                              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
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

  Widget buildDeadlines() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
          const Row(
            children: [
              Icon(Icons.calendar_today_rounded, color: Color(0xFFEF4444), size: 18),
              SizedBox(width: 8),
              Text(
                'Deadline sắp tới',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_stats.recentCourses.isEmpty)
            _buildEmptyState(
              icon: Icons.event_available_rounded,
              message: 'Không có deadline',
              subMessage: 'Bạn không có deadline nào trong thời gian tới',
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _stats.recentCourses.length > 3 ? 3 : _stats.recentCourses.length,
              itemBuilder: (context, index) {
                final course = _stats.recentCourses[index];
                return _buildDeadlineItem(course);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDeadlineItem(EnrolledCourse course) {
    if (course.deadline == null) return const SizedBox.shrink();

    final deadline = course.deadline!;
    final isOverdue = course.deadlineStatus == DeadlineStatus.overdue;
    final isDueSoon = course.deadlineStatus == DeadlineStatus.dueSoon;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                  : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  _getMonthName(deadline.month),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isOverdue ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                  ),
                ),
                Text(
                  '${deadline.day}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isOverdue ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
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
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      course.deadlineStatus.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isOverdue
                            ? const Color(0xFFEF4444)
                            : isDueSoon
                                ? const Color(0xFFF97316)
                                : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${course.progressPercent.toInt()}% hoàn thành',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
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

  Widget buildLiveSessions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
          const Row(
            children: [
              Icon(Icons.live_tv_rounded, color: Color(0xFF137FEC), size: 18),
              SizedBox(width: 8),
              Text(
                'Phiên học trực tiếp',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_stats.liveSessions.isEmpty)
            _buildEmptyState(
              icon: Icons.videocam_off_rounded,
              message: 'Không có phiên học',
              subMessage: 'Các buổi học trực tiếp sẽ xuất hiện khi có lịch',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _stats.liveSessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _buildLiveSessionItem(_stats.liveSessions[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLiveSessionItem(LiveSessionInfo session) {
    final now = DateTime.now();
    final diff = session.startTime.difference(now);
    String timeLabel;
    Color badgeColor;

    if (diff.isNegative) {
      timeLabel = 'Đã diễn ra';
      badgeColor = const Color(0xFF64748B);
    } else if (diff.inMinutes < 60) {
      timeLabel = 'Bắt đầu sau ${diff.inMinutes} phút';
      badgeColor = const Color(0xFFEF4444);
    } else if (diff.inHours < 24) {
      timeLabel = 'Hôm nay, ${_formatTime(session.startTime)}';
      badgeColor = const Color(0xFFF97316);
    } else {
      timeLabel = '${_formatDate(session.startTime)}, ${_formatTime(session.startTime)}';
      badgeColor = const Color(0xFF137FEC);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
            child: const Icon(
              Icons.live_tv_rounded,
              color: Color(0xFF137FEC),
              size: 22,
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
                    color: Color(0xFF0F172A),
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
          if (session.meetingUrl.isNotEmpty && !diff.isNegative)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF137FEC),
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

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String subMessage,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: const Color(0xFFCBD5E1),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subMessage,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(EnrollmentStatus status) {
    switch (status) {
      case EnrollmentStatus.completed:
        return const Color(0xFF22C55E);
      case EnrollmentStatus.inProgress:
        return const Color(0xFF137FEC);
      case EnrollmentStatus.notStarted:
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  String _getStatusLabel(EnrollmentStatus status) {
    switch (status) {
      case EnrollmentStatus.completed:
        return 'Hoàn thành';
      case EnrollmentStatus.inProgress:
        return 'Đang học';
      case EnrollmentStatus.notStarted:
        return 'Chưa bắt đầu';
      default:
        return 'Không xác định';
    }
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF137FEC),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboardData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF137FEC),
              ),
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
          buildWelcomeSection(''),
          const SizedBox(height: 24),
          buildStatsCards(),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: buildCourseList(),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    buildDeadlines(),
                    const SizedBox(height: 24),
                    buildLiveSessions(),
                  ],
                ),
              ),
            ],
          ),
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
          buildWelcomeSection(''),
          const SizedBox(height: 20),
          buildStatsCards(),
          const SizedBox(height: 20),
          buildCourseList(),
          const SizedBox(height: 20),
          buildDeadlines(),
          const SizedBox(height: 20),
          buildLiveSessions(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}