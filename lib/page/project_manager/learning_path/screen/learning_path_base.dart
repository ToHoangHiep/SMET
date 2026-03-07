import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/project_manager/learning_path/screen/learning_path_web.dart';
import 'package:smet/page/project_manager/learning_path/screen/learning_path_mobile.dart';
import 'package:smet/service/common/current_user_store.dart';

class LearningPathData {
  static final List<Map<String, dynamic>> learningPaths = [
    {'id': 'LP001', 'name': 'Flutter Development', 'description': 'Lộ trình học Flutter từ cơ bản đến nâng cao', 'level': 'Beginner', 'duration': '3 tháng', 'courses': 12, 'enrolled': 25, 'status': 'Active'},
    {'id': 'LP002', 'name': 'UI/UX Design', 'description': 'Thiết kế giao diện người dùng chuyên nghiệp', 'level': 'Intermediate', 'duration': '2 tháng', 'courses': 8, 'enrolled': 18, 'status': 'Active'},
    {'id': 'LP003', 'name': 'Backend Development', 'description': 'Phát triển API và cơ sở dữ liệu', 'level': 'Intermediate', 'duration': '4 tháng', 'courses': 15, 'enrolled': 20, 'status': 'Active'},
    {'id': 'LP004', 'name': 'DevOps Fundamentals', 'description': 'Triển khai và vận hành hệ thống', 'level': 'Advanced', 'duration': '3 tháng', 'courses': 10, 'enrolled': 12, 'status': 'Inactive'},
    {'id': 'LP005', 'name': 'Mobile App Security', 'description': 'Bảo mật ứng dụng di động', 'level': 'Advanced', 'duration': '2 tháng', 'courses': 6, 'enrolled': 8, 'status': 'Active'},
  ];
}

class LearningPathPage extends StatefulWidget {
  const LearningPathPage({super.key});
  @override
  State<LearningPathPage> createState() => _LearningPathPageState();
}

class _LearningPathPageState extends State<LearningPathPage> {
  final List<Map<String, dynamic>> _learningPaths = LearningPathData.learningPaths;
  bool _isLoading = false;
  String _nameQuery = '';
  String _levelFilter = 'Tất cả';
  int _currentPage = 1;
  final int _rowsPerPage = 5;

  void handleLogout() => context.go('/login');
  void setNameQuery(String v) => setState(() { _nameQuery = v; _currentPage = 1; });
  void setLevelFilter(String v) => setState(() { _levelFilter = v; _currentPage = 1; });
  void setCurrentPage(int v) => setState(() => _currentPage = v);

  List<Map<String, dynamic>> get learningPaths => _learningPaths;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> get filteredLearningPaths => _learningPaths.where((p) => p['name'].toLowerCase().contains(_nameQuery.toLowerCase()) && (_levelFilter == 'Tất cả' || p['level'] == _levelFilter)).toList();
  List<Map<String, dynamic>> get paginatedLearningPaths { final start = (_currentPage - 1) * _rowsPerPage; if (start >= filteredLearningPaths.length) return []; return filteredLearningPaths.sublist(start, (start + _rowsPerPage).clamp(0, filteredLearningPaths.length)); }

  Widget buildPageHeader() => Row(children: [const Text('DANH SÁCH LỘ TRÌNH HỌC', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))), const Spacer()]);

  Widget buildTableSection() => Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))), child: Column(children: [Padding(padding: const EdgeInsets.all(16), child: Row(children: [Expanded(child: TextField(onChanged: setNameQuery, decoration: InputDecoration(hintText: 'Tìm kiếm...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))))), const SizedBox(width: 16), DropdownButton<String>(value: _levelFilter, items: ['Tất cả', 'Beginner', 'Intermediate', 'Advanced'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(), onChanged: (v) => setLevelFilter(v!))])), SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(columns: const [DataColumn(label: Text('Mã')), DataColumn(label: Text('Tên lộ trình')), DataColumn(label: Text('Mô tả')), DataColumn(label: Text('Cấp độ')), DataColumn(label: Text('Thời lượng')), DataColumn(label: Text('Số khóa')), DataColumn(label: Text('Đã đăng ký')), DataColumn(label: Text('Trạng thái'))], rows: paginatedLearningPaths.map((p) => DataRow(cells: [DataCell(Text(p['id'])), DataCell(Text(p['name'])), DataCell(SizedBox(width: 200, child: Text(p['description'], overflow: TextOverflow.ellipsis))), DataCell(buildLevelBadge(p['level'])), DataCell(Text(p['duration'])), DataCell(Text('${p['courses']}')), DataCell(Text('${p['enrolled']}')), DataCell(buildStatusBadge(p['status']))])).toList())), Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(icon: const Icon(Icons.chevron_left), onPressed: _currentPage > 1 ? () => setCurrentPage(_currentPage - 1) : null), Text('Trang $_currentPage'), IconButton(icon: const Icon(Icons.chevron_right), onPressed: _currentPage * _rowsPerPage < filteredLearningPaths.length ? () => setCurrentPage(_currentPage + 1) : null)]))]));

  Widget buildLevelBadge(String level) { Color c = level == 'Beginner' ? Colors.green : level == 'Intermediate' ? Colors.orange : Colors.red; return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(level, style: TextStyle(color: c, fontWeight: FontWeight.w500, fontSize: 12))); }

  Widget buildStatusBadge(String status) { final color = status == 'Active' ? Colors.green : Colors.red; return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 12))); }

  Widget buildLearningPathList() => ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _learningPaths.length, itemBuilder: (ctx, i) => _buildLearningPathCard(_learningPaths[i]));

  Widget _buildLearningPathCard(Map<String, dynamic> p) {
    Color levelColor = p['level'] == 'Beginner' ? Colors.green : p['level'] == 'Intermediate' ? Colors.orange : Colors.red;
    Color statusColor = p['status'] == 'Active' ? Colors.green : Colors.red;
    return Card(margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(p['status'], style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w500)))]), const SizedBox(height: 8), Text(p['description'], style: TextStyle(color: Colors.grey[600], fontSize: 12)), const SizedBox(height: 12), Row(children: [_buildChip(levelColor, p['level']), const SizedBox(width: 8), _buildChip(Colors.blue, p['duration']), const Spacer(), Icon(Icons.school, size: 16, color: Colors.grey[600]), const SizedBox(width: 4), Text('${p['courses']} khóa', style: TextStyle(fontSize: 12, color: Colors.grey[600])), const SizedBox(width: 12), Icon(Icons.people, size: 16, color: Colors.grey[600]), const SizedBox(width: 4), Text('${p['enrolled']}', style: TextStyle(fontSize: 12, color: Colors.grey[600]))])])));
  }

  Widget _buildChip(Color color, String label) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: const Color(0xFFF3F6FC), body: SafeArea(child: LayoutBuilder(builder: (context, constraints) { if (kIsWeb || constraints.maxWidth > 850) { return LearningPathWeb(pageHeader: buildPageHeader(), tableSection: buildTableSection(), userName: CurrentUserStore.currentUser.fullName, onLogout: handleLogout); } else { return LearningPathMobile(pageHeader: buildPageHeader(), learningPathList: buildLearningPathList(), userName: CurrentUserStore.currentUser.fullName, onLogout: handleLogout); } })));
  }
}
