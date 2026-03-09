// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:smet/page/project_manager/dashboard/screen/pm_dashboard_web.dart';
// import 'package:smet/page/project_manager/dashboard/screen/pm_dashboard_mobile.dart';
// import 'package:smet/service/common/current_user_store.dart';

// class AppColors {
//   static const Color primary = Color(0xFF137FEC);
//   static const Color bgLight = Color(0xFFF3F6FC);
//   static const Color textDark = Color(0xFF0F172A);
//   static const Color textMuted = Color(0xFF64748B);
//   static const Color borderLight = Color(0xFFE5E7EB);
// }

// class PmDashboardData {
//   static final Map<String, dynamic> stats = {
//     'totalProjects': 12,
//     'activeProjects': 8,
//     'completedProjects': 4,
//     'totalMembers': 25,
//   };

//   static final List<Map<String, dynamic>> recentProjects = [
//     {'id': '1', 'name': 'Website Redesign', 'status': 'In Progress', 'progress': 65, 'deadline': '2026-03-20'},
//     {'id': '2', 'name': 'Mobile App Development', 'status': 'Planning', 'progress': 30, 'deadline': '2026-04-15'},
//     {'id': '3', 'name': 'API Integration', 'status': 'Completed', 'progress': 100, 'deadline': '2026-02-28'},
//   ];

//   static final List<Map<String, dynamic>> projectStatus = [
//     {'status': 'In Progress', 'count': 8},
//     {'status': 'Planning', 'count': 3},
//     {'status': 'Completed', 'count': 4},
//     {'status': 'On Hold', 'count': 1},
//   ];
// }

// class ProjectManagerDashboardPage extends StatefulWidget {
//   const ProjectManagerDashboardPage({super.key});

//   @override
//   State<ProjectManagerDashboardPage> createState() => _ProjectManagerDashboardPageState();
// }

// class _ProjectManagerDashboardPageState extends State<ProjectManagerDashboardPage> {
//   bool _isLoading = false;

//   // Getters
//   Map<String, dynamic>? get stats => PmDashboardData.stats;
//   List<Map<String, dynamic>> get recentProjects => PmDashboardData.recentProjects;
//   List<Map<String, dynamic>> get projectStatus => PmDashboardData.projectStatus;
//   bool get isLoading => _isLoading;

//   String get greetingMessage {
//     final hour = DateTime.now().hour;
//     if (hour < 12) return 'Chào buổi sáng';
//     if (hour < 18) return 'Chào buổi chiều';
//     return 'Chào buổi tối';
//   }

//   // Build methods - có thể gọi từ web/mobile
//   Widget buildWelcomeSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(greetingMessage, style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
//         const SizedBox(height: 4),
//         const Text('Bảng điều khiển Quản lý dự án', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
//       ],
//     );
//   }

//   Widget buildStatsCards() {
//     return Row(
//       children: [
//         Expanded(child: _buildStatCard('Tổng dự án', '${stats?['totalProjects'] ?? 0}', Icons.folder, AppColors.primary)),
//         const SizedBox(width: 16),
//         Expanded(child: _buildStatCard('Đang hoạt động', '${stats?['activeProjects'] ?? 0}', Icons.play_circle, Colors.green)),
//         const SizedBox(width: 16),
//         Expanded(child: _buildStatCard('Hoàn thành', '${stats?['completedProjects'] ?? 0}', Icons.check_circle, Colors.blue)),
//         const SizedBox(width: 16),
//         Expanded(child: _buildStatCard('Thành viên', '${stats?['totalMembers'] ?? 0}', Icons.people, Colors.orange)),
//       ],
//     );
//   }

//   Widget _buildStatCard(String title, String value, IconData icon, Color color) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: AppColors.borderLight),
//         boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
//             child: Icon(icon, color: color, size: 24),
//           ),
//           const SizedBox(width: 16),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
//               const SizedBox(height: 4),
//               Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark)),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget buildProjectStatusChart() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: AppColors.borderLight),
//         boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text('TRẠNG THÁI DỰ ÁN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
//           const SizedBox(height: 20),
//           Row(
//             children: projectStatus.map((s) => Expanded(child: _buildStatusItem(s['status'], s['count']))).toList(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatusItem(String status, int count) {
//     Color color = status == 'In Progress' ? Colors.green : status == 'Planning' ? Colors.orange : status == 'Completed' ? Colors.blue : Colors.red;
//     return Column(
//       children: [
//         Container(
//           width: 80, height: 80,
//           decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 4)),
//           child: Center(child: Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color))),
//         ),
//         const SizedBox(height: 12),
//         Text(status, style: const TextStyle(fontSize: 12, color: AppColors.textMuted), textAlign: TextAlign.center),
//       ],
//     );
//   }

//   Widget buildRecentProjects() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: AppColors.borderLight),
//         boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text('DỰ ÁN GẦN ĐÂY', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
//           const SizedBox(height: 16),
//           ...recentProjects.map((p) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildProjectItem(p))),
//         ],
//       ),
//     );
//   }

//   Widget _buildProjectItem(Map<String, dynamic> project) {
//     Color color = project['status'] == 'In Progress' ? Colors.green : project['status'] == 'Planning' ? Colors.orange : project['status'] == 'Completed' ? Colors.blue : Colors.grey;
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(border: Border.all(color: AppColors.borderLight), borderRadius: BorderRadius.circular(12)),
//       child: Row(
//         children: [
//           Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(project['name'], style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)), const SizedBox(height: 4), Text('Deadline: ${project['deadline']}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted))])),
//           const SizedBox(width: 16),
//           Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(project['status'], style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500))),
//           const SizedBox(width: 16),
//           SizedBox(width: 120, child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('${project['progress']}%', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)), const SizedBox(height: 6), LinearProgressIndicator(value: project['progress'] / 100, backgroundColor: AppColors.borderLight, valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 6, borderRadius: BorderRadius.circular(3))])),
//         ],
//       ),
//     );
//   }

//   // Mobile stats grid
//   Widget buildStatsGrid() {
//     return GridView.count(
//       crossAxisCount: 2,
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       mainAxisSpacing: 12,
//       crossAxisSpacing: 12,
//       childAspectRatio: 1.5,
//       children: [
//         _buildStatCard('Tổng dự án', '${stats?['totalProjects'] ?? 0}', Icons.folder, AppColors.primary),
//         _buildStatCard('Đang hoạt động', '${stats?['activeProjects'] ?? 0}', Icons.play_circle, Colors.green),
//         _buildStatCard('Hoàn thành', '${stats?['completedProjects'] ?? 0}', Icons.check_circle, Colors.blue),
//         _buildStatCard('Thành viên', '${stats?['totalMembers'] ?? 0}', Icons.people, Colors.orange),
//       ],
//     );
//   }

//   void _handleLogout() {
//     context.go('/login');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.bgLight,
//       body: SafeArea(
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             if (kIsWeb || constraints.maxWidth > 850) {
//               return PmDashboardWeb(
//                 welcomeSection: buildWelcomeSection(),
//                 statsCards: buildStatsCards(),
//                 projectStatusChart: buildProjectStatusChart(),
//                 recentProjects: buildRecentProjects(),
//                 userName: CurrentUserStore.currentUser.fullName,
//                 onLogout: _handleLogout,
//               );
//             } else {
//               return PmDashboardMobile(
//                 welcomeSection: buildWelcomeSection(),
//                 statsGrid: buildStatsGrid(),
//                 recentProjects: buildRecentProjects(),
//                 userName: CurrentUserStore.currentUser.fullName,
//                 onLogout: _handleLogout,
//               );
//             }
//           },
//         ),
//       ),
//     );
//   }
// }
