import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/project_manager/project_progress/screen/project_progress_web.dart';
import 'package:smet/page/project_manager/project_progress/screen/project_progress_mobile.dart';
import 'package:smet/service/common/current_user_store.dart';

class ProjectProgressData {
  static final List<Map<String, dynamic>> progressList = [
    {'id': 'PG001', 'project': 'Website Redesign', 'task': 'Thiết kế UI/UX', 'assignee': 'Nguyễn Văn A', 'progress': 100, 'status': 'Completed', 'dueDate': '2026-02-15'},
    {'id': 'PG002', 'project': 'Website Redesign', 'task': 'Phát triển Frontend', 'assignee': 'Trần Thị B', 'progress': 65, 'status': 'In Progress', 'dueDate': '2026-03-10'},
    {'id': 'PG003', 'project': 'Mobile App', 'task': 'Thiết kế giao diện', 'assignee': 'Lê Văn C', 'progress': 45, 'status': 'In Progress', 'dueDate': '2026-03-20'},
    {'id': 'PG004', 'project': 'API Integration', 'task': 'Tích hợp API', 'assignee': 'Phạm Văn D', 'progress': 100, 'status': 'Completed', 'dueDate': '2026-02-28'},
    {'id': 'PG005', 'project': 'Database Migration', 'task': 'Chuyển đổi dữ liệu', 'assignee': 'Nguyễn Thị E', 'progress': 30, 'status': 'In Progress', 'dueDate': '2026-03-30'},
  ];
}

class ProjectProgressPage extends StatefulWidget {
  const ProjectProgressPage({super.key});
  @override
  State<ProjectProgressPage> createState() => _ProjectProgressPageState();
}

class _ProjectProgressPageState extends State<ProjectProgressPage> {
  final List<Map<String, dynamic>> _progressList = ProjectProgressData.progressList;
  bool _isLoading = false;
  String _projectFilter = 'Tất cả';
  String _statusFilter = 'Tất cả';
  int _currentPage = 1;
  final int _rowsPerPage = 5;

  void handleLogout() => context.go('/login');
  void setProjectFilter(String v) => setState(() { _projectFilter = v; _currentPage = 1; });
  void setStatusFilter(String v) => setState(() { _statusFilter = v; _currentPage = 1; });
  void setCurrentPage(int v) => setState(() => _currentPage = v);

  List<Map<String, dynamic>> get progressList => _progressList;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> get filteredProgress => _progressList.where((p) => (_projectFilter == 'Tất cả' || p['project'] == _projectFilter) && (_statusFilter == 'Tất cả' || p['status'] == _statusFilter)).toList();
  List<Map<String, dynamic>> get paginatedProgress { final start = (_currentPage - 1) * _rowsPerPage; if (start >= filteredProgress.length) return []; return filteredProgress.sublist(start, (start + _rowsPerPage).clamp(0, filteredProgress.length)); }

  int get totalTasks => _progressList.length;
  int get completedTasks => _progressList.where((p) => p['status'] == 'Completed').length;
  int get inProgressTasks => _progressList.where((p) => p['status'] == 'In Progress').length;
  int get delayedTasks => _progressList.where((p) => p['status'] == 'Delayed').length;

  Widget buildStatsCards() => Row(children: [Expanded(child: _buildStatCard('Tổng công việc', '$totalTasks', Icons.assignment, const Color(0xFF137FEC))), const SizedBox(width: 16), Expanded(child: _buildStatCard('Hoàn thành', '$completedTasks', Icons.check_circle, Colors.green)), const SizedBox(width: 16), Expanded(child: _buildStatCard('Đang thực hiện', '$inProgressTasks', Icons.pending, Colors.orange)), const SizedBox(width: 16), Expanded(child: _buildStatCard('Trễ hạn', '$delayedTasks', Icons.warning, Colors.red))]);

  Widget _buildStatCard(String title, String value, IconData icon, Color color) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))), child: Row(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 24)), const SizedBox(width: 16), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold))])]));

  Widget buildStatsGrid() => GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5, children: [_buildStatCard('Tổng', '$totalTasks', Icons.assignment, const Color(0xFF137FEC)), _buildStatCard('Hoàn thành', '$completedTasks', Icons.check_circle, Colors.green), _buildStatCard('Đang làm', '$inProgressTasks', Icons.pending, Colors.orange), _buildStatCard('Trễ', '$delayedTasks', Icons.warning, Colors.red)]);

  Widget buildTableSection() => Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))), child: Column(children: [Padding(padding: const EdgeInsets.all(16), child: Row(children: [const Text('DANH SÁCH TIẾN ĐỘ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF64748B))), const Spacer(), DropdownButton<String>(value: _projectFilter, items: ['Tất cả', 'Website Redesign', 'Mobile App', 'API Integration', 'Database Migration'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(), onChanged: (v) => setProjectFilter(v!)), const SizedBox(width: 16), DropdownButton<String>(value: _statusFilter, items: ['Tất cả', 'In Progress', 'Completed', 'Delayed'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setStatusFilter(v!))])), SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(columns: const [DataColumn(label: Text('Mã')), DataColumn(label: Text('Dự án')), DataColumn(label: Text('Công việc')), DataColumn(label: Text('Người thực hiện')), DataColumn(label: Text('Tiến độ')), DataColumn(label: Text('Trạng thái')), DataColumn(label: Text('Hạn'))], rows: paginatedProgress.map((p) => DataRow(cells: [DataCell(Text(p['id'])), DataCell(Text(p['project'])), DataCell(Text(p['task'])), DataCell(Text(p['assignee'])), DataCell(buildProgressBar(p['progress'], p['status'])), DataCell(buildStatusBadge(p['status'])), DataCell(Text(p['dueDate']))])).toList())), Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(icon: const Icon(Icons.chevron_left), onPressed: _currentPage > 1 ? () => setCurrentPage(_currentPage - 1) : null), Text('Trang $_currentPage'), IconButton(icon: const Icon(Icons.chevron_right), onPressed: _currentPage * _rowsPerPage < filteredProgress.length ? () => setCurrentPage(_currentPage + 1) : null)]))]));

  Widget buildProgressBar(int progress, String status) {
    Color c = status == 'Completed' ? Colors.green : progress >= 75 ? Colors.green : progress >= 50 ? Colors.orange : progress >= 25 ? Colors.red : Colors.grey;
    return SizedBox(width: 100, child: Row(children: [Expanded(child: LinearProgressIndicator(value: progress / 100, backgroundColor: const Color(0xFFE5E7EB), valueColor: AlwaysStoppedAnimation<Color>(c))), const SizedBox(width: 8), Text('$progress%')]));
  }

  Widget buildStatusBadge(String status) {
    Color c = status == 'In Progress' ? Colors.orange : status == 'Completed' ? Colors.green : status == 'Delayed' ? Colors.red : Colors.grey;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(status, style: TextStyle(color: c, fontWeight: FontWeight.w500, fontSize: 12)));
  }

  Widget buildProgressList() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('DANH SÁCH TIẾN ĐỘ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF64748B))), const SizedBox(height: 12), ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _progressList.length, itemBuilder: (ctx, i) => _buildProgressCard(_progressList[i]))]);

  Widget _buildProgressCard(Map<String, dynamic> p) {
    Color c = p['status'] == 'Completed' ? Colors.green : p['status'] == 'In Progress' ? Colors.orange : Colors.red;
    return Card(margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(p['task'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(p['status'], style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w500)))]), const SizedBox(height: 8), Text(p['project'], style: TextStyle(color: Colors.grey[600], fontSize: 12)), const SizedBox(height: 8), Row(children: [Icon(Icons.person, size: 16, color: Colors.grey[600]), const SizedBox(width: 4), Text(p['assignee'], style: TextStyle(fontSize: 12, color: Colors.grey[600])), const Spacer(), Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]), const SizedBox(width: 4), Text(p['dueDate'], style: TextStyle(fontSize: 12, color: Colors.grey[600]))]), const SizedBox(height: 12), Row(children: [Expanded(child: LinearProgressIndicator(value: p['progress'] / 100, backgroundColor: const Color(0xFFE5E7EB), valueColor: AlwaysStoppedAnimation<Color>(c))), const SizedBox(width: 8), Text('${p['progress']}%')])])));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: const Color(0xFFF3F6FC), body: SafeArea(child: LayoutBuilder(builder: (context, constraints) { if (kIsWeb || constraints.maxWidth > 850) { return ProjectProgressWeb(statsCards: buildStatsCards(), tableSection: buildTableSection(), userName: CurrentUserStore.currentUser.fullName, onLogout: handleLogout); } else { return ProjectProgressMobile(statsGrid: buildStatsGrid(), progressList: buildProgressList(), userName: CurrentUserStore.currentUser.fullName, onLogout: handleLogout); } })));
  }
}
