import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/employee/dashboard/screen/employee_dashboard_web.dart';
import 'package:smet/page/employee/dashboard/screen/employee_dashboard_mobile.dart';

class EmployeeDashboardPage extends StatefulWidget {
  const EmployeeDashboardPage({super.key});

  @override
  State<EmployeeDashboardPage> createState() => _EmployeeDashboardPageState();
}

class _EmployeeDashboardPageState extends State<EmployeeDashboardPage> {
  // Current user info - sẽ được load từ API sau
  String _userName = '';
  String _userRole = '';
  String? _avatarUrl; // TODO: Sử dụng cho avatar image sau

  // Dashboard data - sẽ được load từ API sau
  int _completedCourses = 0;
  int _badgesEarned = 0;
  double _learningHours = 0.0;
  double _avgScore = 0.0;

  // Courses data - sẽ được load từ API sau
  List<Map<String, dynamic>> _inProgressCourses = [];

  // Deadlines data - sẽ được load từ API sau
  List<Map<String, dynamic>> _upcomingDeadlines = [];

  // Live sessions data - sẽ được load từ API sau
  List<Map<String, dynamic>> _liveSessions = [];

  bool _isLoading = true; // TODO: Sử dụng để hiển thị loading indicator

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // Placeholder methods - sẽ gọi API thật sau
  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Gọi API lấy dữ liệu dashboard
      // Ví dụ:
      // final data = await DashboardService.getEmployeeDashboard();
      // setState(() {
      //   _userName = data['userName'];
      //   _completedCourses = data['completedCourses'];
      //   ...
      // });

      // Tạm thời không set dữ liệu - để trống chờ API
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String get greetingMessage {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  // Navigation methods
  void _onNavigateTo(String path) {
    context.go(path);
  }

  void _onLogout() {
    context.go('/login');
  }

  // Welcome section widget
  Widget buildWelcomeSection() {
    final displayName = _userName.isNotEmpty ? _userName : 'Employee';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greetingMessage, $displayName!',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Bạn có khóa học cần hoàn thành và deadline sắp tới.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // Stats cards widget
  Widget buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Khóa học hoàn thành',
            '$_completedCourses',
            Icons.task_alt,
            const Color(0xFF22C55E),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Huy hiệu đạt được',
            '$_badgesEarned'.padLeft(2, '0'),
            Icons.stars,
            const Color(0xFF137FEC),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Giờ học',
            _learningHours > 0 ? '$_learningHours' : '0',
            Icons.schedule,
            const Color(0xFFF97316),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Điểm trung bình',
            _avgScore > 0 ? '${_avgScore.toInt()}%' : '0%',
            Icons.percent,
            const Color(0xFF8B5CF6),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Course list widget
  Widget buildCourseList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'KHÓA HỌC ĐANG HỌC',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF137FEC),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_inProgressCourses.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 48,
                      color: Color(0xFFE5E7EB),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Chưa có khóa học nào',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _inProgressCourses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final course = _inProgressCourses[index];
                return _buildCourseCard(course);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final title = course['title'] ?? '';
    final progress = course['progress'] ?? 0;
    final completedLessons = course['completedLessons'] ?? 0;
    final totalLessons = course['totalLessons'] ?? 0;
    final imageUrl = course['imageUrl'];
    final currentSection = course['currentSection'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          // Course image
          Container(
            width: 120,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              image: imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl == null
                ? const Icon(
                    Icons.laptop_mac,
                    size: 40,
                    color: Color(0xFFCBD5E1),
                  )
                : null,
          ),
          // Course info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentSection,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                                  '$progress% Hoàn thành',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '$completedLessons/$totalLessons Bài học',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: progress / 100,
                              backgroundColor: const Color(0xFFE5E7EB),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF137FEC),
                              ),
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF137FEC),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Tiếp tục',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Deadlines widget
  Widget buildDeadlines() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.event_busy,
                color: Color(0xFFEF4444),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Deadline sắp tới',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_upcomingDeadlines.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Không có deadline nào',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _upcomingDeadlines.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final deadline = _upcomingDeadlines[index];
                return _buildDeadlineItem(deadline);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDeadlineItem(Map<String, dynamic> deadline) {
    final title = deadline['title'] ?? '';
    // final date = deadline['date'] ?? ''; // TODO: Sử dụng cho date formatting sau
    final month = deadline['month'] ?? '';
    final day = deadline['day'] ?? '';
    final isUrgent = deadline['isUrgent'] ?? false;
    final time = deadline['time'] ?? '';
    final isMandatory = deadline['isMandatory'] ?? false;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUrgent
            ? const Color(0xFFFEF2F2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUrgent
              ? const Color(0xFFFEE2E2)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  month.toString().toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEF4444),
                  ),
                ),
                Text(
                  day.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
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
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  isMandatory ? '$time • Bắt buộc' : time,
                  style: TextStyle(
                    fontSize: 12,
                    color: isUrgent
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Live sessions widget
  Widget buildLiveSessions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.videocam,
                color: Color(0xFF137FEC),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Phiên học trực tiếp',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_liveSessions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Không có phiên học nào',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _liveSessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final session = _liveSessions[index];
                return _buildLiveSessionItem(session);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLiveSessionItem(Map<String, dynamic> session) {
    final title = session['title'] ?? '';
    final timeLabel = session['timeLabel'] ?? '';
    final isLive = session['isLive'] ?? false;
    final hostName = session['hostName'] ?? '';
    final attendeeCount = session['attendeeCount'] ?? 0;

    return Container(
      padding: const EdgeInsets.only(left: 12),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Color(0xFF137FEC),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isLive
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF64748B),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isLive ? 'SẮP DIỄN RA' : timeLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          if (hostName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Người hướng dẫn: $hostName',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
          if (isLive) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                // Attendee avatars
                const SizedBox(width: 8),
                Text(
                  '+$attendeeCount người tham gia',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.videocam, size: 16),
                  label: const Text('Tham gia'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4285F4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Stats grid for mobile
  Widget buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Khóa học hoàn thành',
          '$_completedCourses',
          Icons.task_alt,
          const Color(0xFF22C55E),
        ),
        _buildStatCard(
          'Huy hiệu',
          '$_badgesEarned'.padLeft(2, '0'),
          Icons.stars,
          const Color(0xFF137FEC),
        ),
        _buildStatCard(
          'Giờ học',
          _learningHours > 0 ? '$_learningHours' : '0',
          Icons.schedule,
          const Color(0xFFF97316),
        ),
        _buildStatCard(
          'Điểm TB',
          _avgScore > 0 ? '${_avgScore.toInt()}%' : '0%',
          Icons.percent,
          const Color(0xFF8B5CF6),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (kIsWeb || constraints.maxWidth > 850) {
              return EmployeeDashboardWeb(
                welcomeSection: buildWelcomeSection(),
                statsCards: buildStatsCards(),
                courseList: buildCourseList(),
                deadlines: buildDeadlines(),
                liveSessions: buildLiveSessions(),
                userName: _userName.isNotEmpty ? _userName : 'Employee',
                userRole: _userRole,
                onNavigate: _onNavigateTo,
                onLogout: _onLogout,
              );
            } else {
              return EmployeeDashboardMobile(
                welcomeSection: buildWelcomeSection(),
                statsGrid: buildStatsGrid(),
                courseList: buildCourseList(),
                deadlines: buildDeadlines(),
                liveSessions: buildLiveSessions(),
                userName: _userName.isNotEmpty ? _userName : 'Employee',
                userRole: _userRole,
                onNavigate: _onNavigateTo,
                onLogout: _onLogout,
              );
            }
          },
        ),
      ),
    );
  }
}
