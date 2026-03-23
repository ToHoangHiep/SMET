import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/project_manager/project_member/screen/project_member_web.dart';
import 'package:smet/page/project_manager/project_member/screen/project_member_mobile.dart';
import 'package:smet/service/project/project_member_service.dart';
import 'package:smet/service/common/auth_service.dart';
import 'package:smet/model/project_member_model.dart';

class ProjectMemberPage extends StatefulWidget {
  const ProjectMemberPage({super.key});

  @override
  State<ProjectMemberPage> createState() => _ProjectMemberPageState();
}

class _ProjectMemberPageState extends State<ProjectMemberPage> {
  List<ProjectMemberModel> _members = [];
  bool _isLoading = false;
  String? _error;
  String _nameQuery = '';
  String _statusFilter = 'Tất cả';
  int _currentPage = 1;
  final int _rowsPerPage = 10;
  bool _isCreateMode = false;
  bool _isUpdateMode = false;
  int? _selectedProjectId;
  String? _editingMemberId;
  final TextEditingController _createNameController = TextEditingController();
  final TextEditingController _createEmailController = TextEditingController();
  final TextEditingController _createRoleController = TextEditingController();
  String _createStatus = 'ACTIVE';

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _createNameController.dispose();
    _createEmailController.dispose();
    _createRoleController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    if (_selectedProjectId == null) return;
    setState(() => _isLoading = true);
    try {
      final members = await ProjectMemberService.getByProject(_selectedProjectId!);
      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải danh sách thành viên';
        _isLoading = false;
      });
    }
  }

  List<ProjectMemberModel> get filteredMembers {
    return _members.where((m) {
      final nameMatch = (m.userName ?? '').toLowerCase().contains(_nameQuery.toLowerCase());
      final roleMatch = _statusFilter == 'Tất cả' ||
          (_statusFilter == 'Active' && m.role == ProjectMemberRole.PROJECT_LEAD) ||
          (_statusFilter == 'Inactive' && m.role == ProjectMemberRole.PROJECT_MEMBER);
      return nameMatch && roleMatch;
    }).toList();
  }

  List<ProjectMemberModel> get paginatedMembers {
    final start = (_currentPage - 1) * _rowsPerPage;
    if (start >= filteredMembers.length) return [];
    return filteredMembers.sublist(
      start,
      (start + _rowsPerPage).clamp(0, filteredMembers.length),
    );
  }

  void setNameQuery(String v) => setState(() {
    _nameQuery = v;
    _currentPage = 1;
  });

  void setStatusFilter(String v) => setState(() {
    _statusFilter = v;
    _currentPage = 1;
  });

  void setCurrentPage(int v) => setState(() => _currentPage = v);

  Widget buildPageHeader() => Row(
    children: [
      const Text('DANH SÁCH THÀNH VIÊN',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
      const Spacer(),
      if (!_isCreateMode && !_isUpdateMode)
        ElevatedButton.icon(
          onPressed: () => setState(() { _isCreateMode = true; _isUpdateMode = false; _editingMemberId = null; _createNameController.clear(); _createEmailController.clear(); _createRoleController.clear(); _createStatus = 'ACTIVE'; }),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF137FEC), foregroundColor: Colors.white),
          icon: const Icon(Icons.person_add),
          label: const Text('Thêm'),
        ),
    ],
  );

  Widget buildFormCard() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_isUpdateMode ? 'Cập nhật thành viên' : 'Thêm thành viên',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        TextField(controller: _createNameController, decoration: InputDecoration(labelText: 'Họ tên', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
        const SizedBox(height: 16),
        TextField(controller: _createEmailController, decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
        const SizedBox(height: 16),
        TextField(controller: _createRoleController, decoration: InputDecoration(labelText: 'Vai trò', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _createStatus,
          decoration: InputDecoration(labelText: 'Trạng thái', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
          items: const [
            DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
            DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
          ],
          onChanged: (v) => setState(() => _createStatus = v!)),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => setState(() { _isCreateMode = false; _isUpdateMode = false; _editingMemberId = null; }),
              child: const Text('Hủy')),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _isUpdateMode ? _submitUpdateMember : _submitCreateMember,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF137FEC), foregroundColor: Colors.white),
              child: Text(_isUpdateMode ? 'Cập nhật' : 'Thêm')),
          ],
        ),
      ],
    ),
  );

  void _submitCreateMember() {
    if (_createNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập họ tên'), backgroundColor: Colors.orange));
      return;
    }
    setState(() { _isCreateMode = false; });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã thêm thành viên (cần kết nối API)'), backgroundColor: Colors.green));
  }

  void _submitUpdateMember() {
    if (_editingMemberId == null) return;
    setState(() { _isUpdateMode = false; _editingMemberId = null; });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã cập nhật'), backgroundColor: Colors.green));
  }

  Widget buildTableSection() => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: setNameQuery,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  )),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _statusFilter,
                items: ['Tất cả', 'Active', 'Inactive'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setStatusFilter(v!)),
            ],
          ),
        ),
        if (_isLoading)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
        else if (_selectedProjectId == null)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Chọn dự án để xem thành viên')))
        else if (paginatedMembers.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Không có thành viên')))
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Mã')),
                DataColumn(label: Text('Họ tên')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Vai trò')),
                DataColumn(label: Text('Trạng thái')),
                DataColumn(label: Text('Thao tác')),
              ],
              rows: paginatedMembers.map((m) => DataRow(
                cells: [
                  DataCell(Text(m.id.toString())),
                  DataCell(Text(m.userName ?? '')),
                  DataCell(Text(m.userEmail ?? '')),
                  DataCell(Text(m.role.label)),
                  DataCell(Text('')),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => setState(() {
                          _isUpdateMode = true; _isCreateMode = false;
                          _editingMemberId = m.id.toString();
                          _createNameController.text = m.userName ?? '';
                          _createEmailController.text = m.userEmail ?? '';
                          _createRoleController.text = m.role.label;
                          _createStatus = 'ACTIVE';
                        })),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                        onPressed: () => _handleDeleteMember(m)),
                    ],
                  )),
                ],
              )).toList(),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 1 ? () => setCurrentPage(_currentPage - 1) : null),
              Text('Trang $_currentPage'),
              IconButton(icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage * _rowsPerPage < filteredMembers.length
                    ? () => setCurrentPage(_currentPage + 1) : null),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildStatusBadge(bool isActive) {
    final color = isActive ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(isActive ? 'Active' : 'Inactive',
        style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 12)));
  }

  Future<void> _handleDeleteMember(ProjectMemberModel member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Xóa thành viên'),
        content: Text('Xóa "${member.userName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Xóa')),
        ],
      ));
    if (confirmed == true) {
      // await ProjectMemberService.deleteMember(member.id!);
      setState(() => _members.removeWhere((m) => m.id == member.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa'), backgroundColor: Colors.green));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (kIsWeb || constraints.maxWidth > 850) {
              return ProjectMemberWeb(
                pageHeader: buildPageHeader(),
                formCard: buildFormCard(),
                tableSection: buildTableSection(),
                showForm: _isCreateMode || _isUpdateMode,
                userName: 'PM User',
                onLogout: () => context.go('/login'),
              );
            } else {
              return ProjectMemberMobile(
                pageHeader: buildPageHeader(),
                formCard: buildFormCard(),
                memberList: ListView.builder(
                  shrinkWrap: true,
                  itemCount: paginatedMembers.length,
                  itemBuilder: (ctx, i) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(paginatedMembers[i].userName ?? ''),
                      subtitle: Text(paginatedMembers[i].userEmail ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _handleDeleteMember(paginatedMembers[i])),
                    ),
                  ),
                ),
                showForm: _isCreateMode || _isUpdateMode,
                userName: 'PM User',
                onLogout: () => context.go('/login'),
              );
            }
          },
        ),
      ),
    );
  }
}
