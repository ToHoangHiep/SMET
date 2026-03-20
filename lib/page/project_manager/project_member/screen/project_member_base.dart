// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:smet/page/project_manager/project_member/screen/project_member_web.dart';
// import 'package:smet/page/project_manager/project_member/screen/project_member_mobile.dart';
// import 'package:smet/service/common/current_user_store.dart';

// class ProjectMemberData {
//   static final List<Map<String, dynamic>> members = [
//     {'id': 'MB001', 'name': 'Nguyễn Văn A', 'email': 'nguyenvana@example.com', 'role': 'Project Manager', 'project': 'Website Redesign', 'status': 'Active', 'joinDate': '2026-01-15'},
//     {'id': 'MB002', 'name': 'Trần Thị B', 'email': 'tranthib@example.com', 'role': 'Developer', 'project': 'Mobile App', 'status': 'Active', 'joinDate': '2026-01-20'},
//     {'id': 'MB003', 'name': 'Lê Văn C', 'email': 'levanc@example.com', 'role': 'Designer', 'project': 'Website Redesign', 'status': 'Active', 'joinDate': '2026-02-01'},
//     {'id': 'MB004', 'name': 'Phạm Văn D', 'email': 'phamvand@example.com', 'role': 'Developer', 'project': 'API Integration', 'status': 'Inactive', 'joinDate': '2026-01-10'},
//     {'id': 'MB005', 'name': 'Nguyễn Thị E', 'email': 'nguyenthie@example.com', 'role': 'Tester', 'project': 'Mobile App', 'status': 'Active', 'joinDate': '2026-02-15'},
//   ];
// }

// class ProjectMemberPage extends StatefulWidget {
//   const ProjectMemberPage({super.key});

//   @override
//   State<ProjectMemberPage> createState() => _ProjectMemberPageState();
// }

// class _ProjectMemberPageState extends State<ProjectMemberPage> {
//   final List<Map<String, dynamic>> _members = ProjectMemberData.members;
//   bool _isLoading = false;
//   String _nameQuery = '';
//   String _statusFilter = 'Tất cả';
//   int _currentPage = 1;
//   final int _rowsPerPage = 5;
//   bool _isCreateMode = false;
//   bool _isUpdateMode = false;
//   String? _editingMemberId;
//   final TextEditingController _createNameController = TextEditingController();
//   final TextEditingController _createEmailController = TextEditingController();
//   final TextEditingController _createRoleController = TextEditingController();
//   final TextEditingController _createProjectController = TextEditingController();
//   String _createStatus = 'Active';

//   @override
//   void dispose() {
//     _createNameController.dispose();
//     _createEmailController.dispose();
//     _createRoleController.dispose();
//     _createProjectController.dispose();
//     super.dispose();
//   }

//   List<Map<String, dynamic>> get members => _members;
//   bool get isLoading => _isLoading;
//   bool get isCreateMode => _isCreateMode;
//   bool get isUpdateMode => _isUpdateMode;

//   void handleLogout() => context.go('/login');
//   void setNameQuery(String v) => setState(() { _nameQuery = v; _currentPage = 1; });
//   void setStatusFilter(String v) => setState(() { _statusFilter = v; _currentPage = 1; });
//   void setCurrentPage(int v) => setState(() => _currentPage = v);
//   void setCreateStatus(String v) => setState(() => _createStatus = v);

//   void openCreateMemberScreen() => setState(() {
//     _isCreateMode = true; _isUpdateMode = false; _editingMemberId = null;
//     _createNameController.clear(); _createEmailController.clear(); _createRoleController.clear(); _createProjectController.clear(); _createStatus = 'Active';
//   });

//   void openUpdateMemberScreen(Map<String, dynamic> member) => setState(() {
//     _isCreateMode = false; _isUpdateMode = true; _editingMemberId = member['id'];
//     _createNameController.text = member['name']; _createEmailController.text = member['email'];
//     _createRoleController.text = member['role']; _createProjectController.text = member['project']; _createStatus = member['status'];
//   });

//   void closeFormScreen() => setState(() { _isCreateMode = false; _isUpdateMode = false; _editingMemberId = null; });

//   void submitCreateMember() {
//     if (_createNameController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập họ tên'), backgroundColor: Colors.orange));
//       return;
//     }
//     setState(() {
//       _members.insert(0, {'id': 'MB${DateTime.now().millisecondsSinceEpoch}', 'name': _createNameController.text, 'email': _createEmailController.text, 'role': _createRoleController.text.isNotEmpty ? _createRoleController.text : 'Developer', 'project': _createProjectController.text.isNotEmpty ? _createProjectController.text : 'Chưa có', 'status': _createStatus, 'joinDate': DateTime.now().toString().split(' ')[0]});
//       _isCreateMode = false; _currentPage = 1;
//     });
//     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm thành viên'), backgroundColor: Colors.green));
//   }

//   void submitUpdateMember() {
//     if (_editingMemberId == null) return;
//     setState(() {
//       final index = _members.indexWhere((m) => m['id'] == _editingMemberId);
//       if (index != -1) _members[index] = {..._members[index], 'name': _createNameController.text, 'email': _createEmailController.text, 'role': _createRoleController.text, 'project': _createProjectController.text, 'status': _createStatus};
//       _isUpdateMode = false; _editingMemberId = null;
//     });
//     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật'), backgroundColor: Colors.green));
//   }

//   Future<void> handleDeleteMember(Map<String, dynamic> member) async {
//     final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), title: const Text('Xóa thành viên'), content: Text('Xóa "${member['name']}"?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text('Xóa'))]));
//     if (confirmed == true) { setState(() => _members.removeWhere((m) => m['id'] == member['id'])); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa'), backgroundColor: Colors.green)); }
//   }

//   List<Map<String, dynamic>> get filteredMembers => _members.where((m) => m['name'].toLowerCase().contains(_nameQuery.toLowerCase()) && (_statusFilter == 'Tất cả' || m['status'] == _statusFilter)).toList();
//   List<Map<String, dynamic>> get paginatedMembers { final start = (_currentPage - 1) * _rowsPerPage; if (start >= filteredMembers.length) return []; return filteredMembers.sublist(start, (start + _rowsPerPage).clamp(0, filteredMembers.length)); }

//   Widget buildPageHeader() => Row(children: [const Text('DANH SÁCH THÀNH VIÊN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF64748B))), const Spacer(), if (!_isCreateMode && !_isUpdateMode) ElevatedButton.icon(onPressed: openCreateMemberScreen, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF137FEC), foregroundColor: Colors.white), icon: const Icon(Icons.person_add), label: const Text('Thêm'))]);

//   Widget buildFormCard() => Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_isUpdateMode ? 'Cập nhật' : 'Thêm thành viên', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 20), TextField(controller: _createNameController, decoration: InputDecoration(labelText: 'Họ tên', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))), const SizedBox(height: 16), TextField(controller: _createEmailController, decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))), const SizedBox(height: 16), TextField(controller: _createRoleController, decoration: InputDecoration(labelText: 'Vai trò', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))), const SizedBox(height: 16), TextField(controller: _createProjectController, decoration: InputDecoration(labelText: 'Dự án', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))), const SizedBox(height: 16), DropdownButtonFormField<String>(value: _createStatus, decoration: InputDecoration(labelText: 'Trạng thái', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))), items: ['Active', 'Inactive'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setCreateStatus(v!)), const SizedBox(height: 24), Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: closeFormScreen, child: const Text('Hủy')), const SizedBox(width: 12), ElevatedButton(onPressed: _isUpdateMode ? submitUpdateMember : submitCreateMember, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF137FEC), foregroundColor: Colors.white), child: Text(_isUpdateMode ? 'Cập nhật' : 'Thêm'))])]));

//   Widget buildTableSection() => Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))), child: Column(children: [Padding(padding: const EdgeInsets.all(16), child: Row(children: [Expanded(child: TextField(onChanged: setNameQuery, decoration: InputDecoration(hintText: 'Tìm kiếm...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))))), const SizedBox(width: 16), DropdownButton<String>(value: _statusFilter, items: ['Tất cả', 'Active', 'Inactive'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setStatusFilter(v!))])), SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(columns: const [DataColumn(label: Text('Mã')), DataColumn(label: Text('Họ tên')), DataColumn(label: Text('Email')), DataColumn(label: Text('Vai trò')), DataColumn(label: Text('Dự án')), DataColumn(label: Text('Trạng thái')), DataColumn(label: Text('Thao tác'))], rows: paginatedMembers.map((m) => DataRow(cells: [DataCell(Text(m['id'])), DataCell(Text(m['name'])), DataCell(Text(m['email'])), DataCell(Text(m['role'])), DataCell(Text(m['project'])), DataCell(buildStatusBadge(m['status'])), DataCell(Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => openUpdateMemberScreen(m)), IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => handleDeleteMember(m))]))])).toList())), Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(icon: const Icon(Icons.chevron_left), onPressed: _currentPage > 1 ? () => setCurrentPage(_currentPage - 1) : null), Text('Trang $_currentPage'), IconButton(icon: const Icon(Icons.chevron_right), onPressed: _currentPage * _rowsPerPage < filteredMembers.length ? () => setCurrentPage(_currentPage + 1) : null)]))]));

//   Widget buildStatusBadge(String status) {
//     final color = status == 'Active' ? Colors.green : Colors.red;
//     return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 12)));
//   }

//   Widget buildMemberList() => ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _members.length, itemBuilder: (ctx, i) => _buildMemberCard(_members[i]));

//   Widget _buildMemberCard(Map<String, dynamic> m) {
//     final isActive = m['status'] == 'Active';
//     return Card(margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [Row(children: [CircleAvatar(backgroundColor: const Color(0xFF137FEC).withValues(alpha: 0.1), child: Text(m['name'][0], style: const TextStyle(color: Color(0xFF137FEC), fontWeight: FontWeight.bold))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(m['name'], style: const TextStyle(fontWeight: FontWeight.bold)), Text(m['email'], style: TextStyle(color: Colors.grey[600], fontSize: 12))])), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: (isActive ? Colors.green : Colors.red).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(m['status'], style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.w500)))]), const SizedBox(height: 12), Row(children: [_buildChip(Icons.work, m['role']), const SizedBox(width: 8), _buildChip(Icons.folder, m['project'])]), const SizedBox(height: 12), Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton.icon(icon: const Icon(Icons.edit, size: 18), label: const Text('Sửa'), onPressed: () => openUpdateMemberScreen(m)), TextButton.icon(icon: const Icon(Icons.delete, size: 18, color: Colors.red), label: const Text('Xóa', style: TextStyle(color: Colors.red)), onPressed: () => handleDeleteMember(m))])])));
//   }

//   Widget _buildChip(IconData icon, String label) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: Colors.grey[600]), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600]))]));

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF3F6FC),
//       body: SafeArea(
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             if (kIsWeb || constraints.maxWidth > 850) {
//               return ProjectMemberWeb(pageHeader: buildPageHeader(), formCard: buildFormCard(), tableSection: buildTableSection(), showForm: _isCreateMode || _isUpdateMode, userName: CurrentUserStore.currentUser.fullName, onLogout: handleLogout);
//             } else {
//               return ProjectMemberMobile(pageHeader: buildPageHeader(), formCard: buildFormCard(), memberList: buildMemberList(), showForm: _isCreateMode || _isUpdateMode, userName: CurrentUserStore.currentUser.fullName, onLogout: handleLogout);
//             }
//           },
//         ),
//       ),
//     );
//   }
// }
