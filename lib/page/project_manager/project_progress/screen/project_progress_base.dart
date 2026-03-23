import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/project_manager/project_progress/screen/project_progress_web.dart';
import 'package:smet/page/project_manager/project_progress/screen/project_progress_mobile.dart';

class ProjectProgressPage extends StatefulWidget {
  const ProjectProgressPage({super.key});

  @override
  State<ProjectProgressPage> createState() => _ProjectProgressPageState();
}

class _ProjectProgressPageState extends State<ProjectProgressPage> {
  String _projectFilter = 'Tất cả';
  String _statusFilter = 'Tất cả';
  int _currentPage = 1;
  final int _rowsPerPage = 10;

  // Stats (sẽ load từ API)
  int get totalTasks => 0;
  int get completedTasks => 0;
  int get inProgressTasks => 0;
  int get delayedTasks => 0;

  Widget buildStatsCards() => Row(children: [
    Expanded(child: _buildStatCard('Tổng công việc', '$totalTasks', Icons.assignment, const Color(0xFF137FEC))),
    const SizedBox(width: 16),
    Expanded(child: _buildStatCard('Hoàn thành', '$completedTasks', Icons.check_circle, Colors.green)),
    const SizedBox(width: 16),
    Expanded(child: _buildStatCard('Đang thực hiện', '$inProgressTasks', Icons.pending, Colors.orange)),
    const SizedBox(width: 16),
    Expanded(child: _buildStatCard('Trễ hạn', '$delayedTasks', Icons.warning, Colors.red)),
  ]);

  Widget _buildStatCard(String title, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 24)),
      const SizedBox(width: 16),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      ]),
    ]),
  );

  Widget buildStatsGrid() => GridView.count(
    crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5,
    children: [
      _buildStatCard('Tổng', '$totalTasks', Icons.assignment, const Color(0xFF137FEC)),
      _buildStatCard('Hoàn thành', '$completedTasks', Icons.check_circle, Colors.green),
      _buildStatCard('Đang làm', '$inProgressTasks', Icons.pending, Colors.orange),
      _buildStatCard('Trễ', '$delayedTasks', Icons.warning, Colors.red),
    ],
  );

  Widget buildProgressTable() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
    child: const Center(
      child: Column(
        children: [
          Icon(Icons.table_chart_outlined, size: 48, color: Color(0xFF64748B)),
          SizedBox(height: 12),
          Text('Tiến độ dự án sẽ được tải từ API', style: TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    ),
  );

  void handleLogout() => context.go('/login');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (kIsWeb || constraints.maxWidth > 850) {
              return ProjectProgressWeb(
                statsCards: buildStatsCards(),
                tableSection: buildProgressTable(),
                userName: 'PM User',
                onLogout: handleLogout,
              );
            } else {
              return ProjectProgressMobile(
                statsGrid: buildStatsGrid(),
                progressList: buildProgressTable(),
                userName: 'PM User',
                onLogout: handleLogout,
              );
            }
          },
        ),
      ),
    );
  }
}
