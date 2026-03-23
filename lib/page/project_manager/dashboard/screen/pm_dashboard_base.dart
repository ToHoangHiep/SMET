import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/project_manager/dashboard/screen/pm_dashboard_web.dart';
import 'package:smet/page/project_manager/dashboard/screen/pm_dashboard_mobile.dart';
import 'package:smet/service/common/auth_service.dart';

class AppColors {
  static const Color primary = Color(0xFF137FEC);
  static const Color bgLight = Color(0xFFF3F6FC);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFE5E7EB);
}

class ProjectManagerDashboardPage extends StatefulWidget {
  const ProjectManagerDashboardPage({super.key});

  @override
  State<ProjectManagerDashboardPage> createState() =>
      _ProjectManagerDashboardPageState();
}

class _ProjectManagerDashboardPageState
    extends State<ProjectManagerDashboardPage> {
  String _currentUserName = 'Project Manager';
  bool _isLoading = true;

  // Dashboard data - will be loaded from API
  int _totalProjects = 0;
  int _activeProjects = 0;
  int _completedProjects = 0;
  int _totalMembers = 0;
  List<Map<String, dynamic>> _recentProjects = [];
  List<Map<String, dynamic>> _projectStatus = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadDashboardData();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userData = await AuthService.getMe();
      setState(() {
        _currentUserName =
            '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'
                .trim();
        if (_currentUserName.isEmpty) {
          _currentUserName = userData['userName'] ?? 'Project Manager';
        }
      });
    } catch (e) {
      debugPrint('Error loading current user: $e');
      setState(() {
        _currentUserName = 'Project Manager';
      });
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Gọi API lấy dữ liệu dashboard
      // final data = await DashboardService.getPMDashboard();
      // setState(() {
      //   _totalProjects = data['totalProjects'];
      //   ...
      // });
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

  Widget buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greetingMessage,
          style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
        const SizedBox(height: 4),
        const Text(
          'Bảng điều khiển Quản lý dự án',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Tổng dự án',
            '$_totalProjects',
            Icons.folder,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Đang hoạt động',
            '$_activeProjects',
            Icons.play_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Hoàn thành',
            '$_completedProjects',
            Icons.check_circle,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Thành viên',
            '$_totalMembers',
            Icons.people,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildProjectStatusChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
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
          const Text(
            'TRẠNG THÁI DỰ ÁN',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          if (_projectStatus.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.pie_chart_outline,
                      size: 48,
                      color: Color(0xFFE5E7EB),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Chưa có dự án',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            )
          else
            Row(
              children:
                  _projectStatus
                      .map(
                        (s) => Expanded(
                          child: _buildStatusItem(
                            s['status'] ?? 'Unknown',
                            s['count'] ?? 0,
                          ),
                        ),
                      )
                      .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String status, int count) {
    Color color =
        status == 'IN_PROGRESS'
            ? Colors.green
            : status == 'COMPLETED'
            ? Colors.blue
            : status == 'CANCELLED'
            ? Colors.red
            : Colors.grey;
    String displayStatus =
        status == 'IN_PROGRESS'
            ? 'Đang thực hiện'
            : status == 'COMPLETED'
            ? 'Hoàn thành'
            : status == 'CANCELLED'
            ? 'Đã hủy'
            : status == 'DRAFT'
            ? 'Nháp'
            : status;
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 4),
          ),
          child: Center(
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          displayStatus,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget buildRecentProjects() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
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
          const Text(
            'DỰ ÁN GẦN ĐÂY',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          if (_recentProjects.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.folder_open, size: 48, color: Color(0xFFE5E7EB)),
                    SizedBox(height: 16),
                    Text(
                      'Chưa có dự án gần đây',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._recentProjects.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildProjectItem(p),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProjectItem(Map<String, dynamic> project) {
    String status = project['status'] ?? 'DRAFT';
    int progress = project['progress'] ?? 0;
    Color color =
        status == 'IN_PROGRESS'
            ? Colors.green
            : status == 'COMPLETED'
            ? Colors.blue
            : status == 'CANCELLED'
            ? Colors.red
            : Colors.grey;
    String displayStatus =
        status == 'IN_PROGRESS'
            ? 'Đang thực hiện'
            : status == 'COMPLETED'
            ? 'Hoàn thành'
            : status == 'CANCELLED'
            ? 'Đã hủy'
            : status == 'DRAFT'
            ? 'Nháp'
            : status;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Deadline: ${project['deadline'] ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              displayStatus,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$progress%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: AppColors.borderLight,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
          'Tổng dự án',
          '$_totalProjects',
          Icons.folder,
          AppColors.primary,
        ),
        _buildStatCard(
          'Đang hoạt động',
          '$_activeProjects',
          Icons.play_circle,
          Colors.green,
        ),
        _buildStatCard(
          'Hoàn thành',
          '$_completedProjects',
          Icons.check_circle,
          Colors.blue,
        ),
        _buildStatCard(
          'Thành viên',
          '$_totalMembers',
          Icons.people,
          Colors.orange,
        ),
      ],
    );
  }

  void _handleLogout() {
    context.go('/login');
  }

  void _handleProfileTap() {
    context.go('/profile');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (kIsWeb || constraints.maxWidth > 850) {
              return PmDashboardWeb(
                welcomeSection: buildWelcomeSection(),
                statsCards: buildStatsCards(),
                projectStatusChart: buildProjectStatusChart(),
                recentProjects: buildRecentProjects(),
                userName: _currentUserName,
                onLogout: _handleLogout,
                onProfileTap: _handleProfileTap,
              );
            } else {
              return PmDashboardMobile(
                welcomeSection: buildWelcomeSection(),
                statsGrid: buildStatsGrid(),
                recentProjects: buildRecentProjects(),
                userName: _currentUserName,
                onLogout: _handleLogout,
              );
            }
          },
        ),
      ),
    );
  }
}
