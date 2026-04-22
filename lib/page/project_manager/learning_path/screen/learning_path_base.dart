import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/project_manager/learning_path/screen/learning_path_web.dart';
import 'package:smet/page/project_manager/learning_path/screen/learning_path_mobile.dart';
import 'package:smet/service/employee/lms_service.dart';
import 'package:smet/service/common/auth_service.dart';

class LearningPathPage extends StatefulWidget {
  const LearningPathPage({super.key});

  @override
  State<LearningPathPage> createState() => _LearningPathPageState();
}

class _LearningPathPageState extends State<LearningPathPage> {
  List<LearningPathInfo> _paths = [];
  bool _isLoading = true;
  String? _error;
  String _nameQuery = '';
  int _currentPage = 1;
  final int _rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadPaths();
  }

  Future<void> _loadPaths() async {
    setState(() => _isLoading = true);
    try {
      final paths = await LmsService.getMyLearningPaths(keyword: _nameQuery.isEmpty ? null : _nameQuery);
      setState(() {
        _paths = paths;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải lộ trình học';
        _isLoading = false;
      });
    }
  }

  List<LearningPathInfo> get filteredPaths => _nameQuery.isEmpty
      ? _paths
      : _paths.where((p) => p.title.toLowerCase().contains(_nameQuery.toLowerCase())).toList();

  List<LearningPathInfo> get paginatedPaths {
    final start = (_currentPage - 1) * _rowsPerPage;
    if (start >= filteredPaths.length) return [];
    return filteredPaths.sublist(start, (start + _rowsPerPage).clamp(0, filteredPaths.length));
  }

  void setNameQuery(String v) => setState(() {
    _nameQuery = v;
    _currentPage = 1;
  });

  void setCurrentPage(int v) => setState(() => _currentPage = v);

  Widget buildPageHeader() => Row(
    children: [
      const Text('QUẢN LÝ LỘ TRÌNH HỌC',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
      const Spacer(),
      ElevatedButton.icon(
        onPressed: () {},
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF137FEC), foregroundColor: Colors.white),
        icon: const Icon(Icons.add),
        label: const Text('Tạo lộ trình'),
      ),
    ],
  );

  Widget buildTableSection() => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: setNameQuery,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm lộ trình...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        if (_isLoading)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
        else if (paginatedPaths.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Chưa có lộ trình nào')))
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Tên lộ trình')),
                DataColumn(label: Text('Mô tả')),
                DataColumn(label: Text('Số khóa')),
                DataColumn(label: Text('Tiến độ')),
                DataColumn(label: Text('Thao tác')),
              ],
              rows: paginatedPaths.map((lp) => DataRow(
                cells: [
                  DataCell(Text(lp.id)),
                  DataCell(Text(lp.title, overflow: TextOverflow.ellipsis)),
                  DataCell(Text(lp.description, overflow: TextOverflow.ellipsis, maxLines: 1)),
                  DataCell(Text('${lp.courseCount} khóa')),
                  DataCell(_buildProgressBar(lp.progressPercent)),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, size: 20),
                        onPressed: () {},
                        tooltip: 'Chi tiết',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () {},
                        tooltip: 'Sửa',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                        onPressed: () {},
                        tooltip: 'Xóa',
                      ),
                    ],
                  )),
                ],
              )).toList(),
            ),
          ),
        if (filteredPaths.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 1 ? () => setCurrentPage(_currentPage - 1) : null,
                ),
                Text('Trang $_currentPage'),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage * _rowsPerPage < filteredPaths.length
                      ? () => setCurrentPage(_currentPage + 1) : null,
                ),
              ],
            ),
          ),
      ],
    ),
  );

  Widget _buildProgressBar(double percent) {
    final color = percent >= 100
        ? Colors.green
        : percent >= 50
            ? Colors.orange
            : Colors.blue;
    return SizedBox(
      width: 80,
      child: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 6),
          Text('${percent.round()}%', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void handleLogout() async {
    await AuthService.logout();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (kIsWeb || constraints.maxWidth > 850) {
              return LearningPathWeb(
                pageHeader: buildPageHeader(),
                tableSection: buildTableSection(),
                userName: 'PM User',
                onLogout: handleLogout,
              );
            } else {
              return LearningPathMobile(
                pageHeader: buildPageHeader(),
                learningPathList: ListView.builder(
                  shrinkWrap: true,
                  itemCount: paginatedPaths.length,
                  itemBuilder: (ctx, i) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF137FEC).withOpacity(0.1),
                        child: const Icon(Icons.route, color: Color(0xFF137FEC)),
                      ),
                      title: Text(paginatedPaths[i].title),
                      subtitle: Text('${paginatedPaths[i].courseCount} khóa học'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {},
                      ),
                      onTap: () {},
                    ),
                  ),
                ),
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
