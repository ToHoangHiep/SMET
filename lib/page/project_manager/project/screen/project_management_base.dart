import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/project_manager/project/screen/project_management_web.dart';
import 'package:smet/page/project_manager/project/screen/project_management_mobile.dart';
import 'package:smet/service/common/current_user_store.dart';
import 'package:smet/service/admin/user_management/api_user_management.dart';
import 'package:smet/model/user_model.dart';

class ProjectData {
  static final List<Map<String, dynamic>> projects = [
    {
      'id': 'PRJ001',
      'name': 'Website Redesign',
      'description': 'Thiết kế lại website công ty',
      'status': 'In Progress',
      'progress': 65,
      'startDate': '2026-01-15',
      'deadline': '2026-03-20',
      'manager': 'Nguyễn Văn A',
      'members': 5,
    },
    {
      'id': 'PRJ002',
      'name': 'Mobile App Development',
      'description': 'Phát triển ứng dụng di động',
      'status': 'Planning',
      'progress': 30,
      'startDate': '2026-02-01',
      'deadline': '2026-04-15',
      'manager': 'Trần Thị B',
      'members': 8,
    },
    {
      'id': 'PRJ003',
      'name': 'API Integration',
      'description': 'Tích hợp API với hệ thống mới',
      'status': 'Completed',
      'progress': 100,
      'startDate': '2026-01-01',
      'deadline': '2026-02-28',
      'manager': 'Lê Văn C',
      'members': 3,
    },
    {
      'id': 'PRJ004',
      'name': 'Database Migration',
      'description': 'Chuyển đổi cơ sở dữ liệu',
      'status': 'In Progress',
      'progress': 45,
      'startDate': '2026-02-10',
      'deadline': '2026-03-30',
      'manager': 'Phạm Văn D',
      'members': 4,
    },
    {
      'id': 'PRJ005',
      'name': 'Security Audit',
      'description': 'Kiểm tra bảo mật hệ thống',
      'status': 'On Hold',
      'progress': 10,
      'startDate': '2026-03-01',
      'deadline': '2026-05-01',
      'manager': 'Nguyễn Văn E',
      'members': 2,
    },
  ];
}

class ProjectManagementPage extends StatefulWidget {
  const ProjectManagementPage({super.key});

  @override
  State<ProjectManagementPage> createState() => _ProjectManagementPageState();
}

class _ProjectManagementPageState extends State<ProjectManagementPage> {
  final List<Map<String, dynamic>> _projects = ProjectData.projects;
  bool _isLoading = false;
  String _nameQuery = '';
  String _statusFilter = 'Tất cả';
  int _currentPage = 1;
  final int _rowsPerPage = 5;
  bool _isCreateMode = false;
  bool _isUpdateMode = false;
  String? _editingProjectId;
  final TextEditingController _createNameController = TextEditingController();
  final TextEditingController _createDescriptionController =
      TextEditingController();
  final TextEditingController _createManagerController =
      TextEditingController();
  String _createStatus = 'Planning';
  DateTime? _startDate;
  DateTime? _endDate;
  Map<String, dynamic>? _selectedTeamLead;
  Map<String, dynamic>? _selectedMentor;
  List<Map<String, dynamic>> _selectedMembers = [];
  List<UserModel> _employees = [];
  final ApiService _apiService = ApiService();

  final List<Map<String, dynamic>> _mentors = [
    {
      'id': 'm1',
      'name': 'Phạm Văn D',
      'email': 'phamvand@company.com',
      'avatar': 'PD',
      'role': 'mentor',
    },
    {
      'id': 'm2',
      'name': 'Hoàng Thị E',
      'email': 'hoangthie@company.com',
      'avatar': 'HE',
      'role': 'mentor',
    },
    {
      'id': 'm3',
      'name': 'Đỗ Văn F',
      'email': 'dovanaf@company.com',
      'avatar': 'DF',
      'role': 'mentor',
    },
    {
      'id': 'm4',
      'name': 'Vũ Thị G',
      'email': 'vuthig@company.com',
      'avatar': 'VG',
      'role': 'mentor',
    },
  ];

  final List<Map<String, dynamic>> _availableMembers = [
    {
      'id': 'mb1',
      'name': 'Nguyễn Văn H',
      'email': 'nguyenvanh@company.com',
      'avatar': 'NH',
    },
    {
      'id': 'mb2',
      'name': 'Trần Thị I',
      'email': 'tranthii@company.com',
      'avatar': 'TI',
    },
    {
      'id': 'mb3',
      'name': 'Lê Văn J',
      'email': 'levanj@company.com',
      'avatar': 'LJ',
    },
    {
      'id': 'mb4',
      'name': 'Phạm Văn K',
      'email': 'phamvank@company.com',
      'avatar': 'PK',
    },
    {
      'id': 'mb5',
      'name': 'Hoàng Văn L',
      'email': 'hoangvanl@company.com',
      'avatar': 'HL',
    },
    {
      'id': 'mb6',
      'name': 'Đỗ Thị M',
      'email': 'dothim@company.com',
      'avatar': 'DM',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final users = await _apiService.getUsers();
      final employees = users.where((u) => u.role == UserRole.employee).toList();
      setState(() {
        _employees = employees;
      });
    } catch (e) {
      debugPrint('Error loading employees: $e');
    }
  }

  @override
  void dispose() {
    _createNameController.dispose();
    _createDescriptionController.dispose();
    _createManagerController.dispose();
    super.dispose();
  }

  // Getters
  List<Map<String, dynamic>> get projects => _projects;
  bool get isLoading => _isLoading;
  bool get isCreateMode => _isCreateMode;
  bool get isUpdateMode => _isUpdateMode;

  void handleLogout() => context.go('/login');

  void setNameQuery(String v) => setState(() {
    _nameQuery = v;
    _currentPage = 1;
  });
  void setStatusFilter(String v) => setState(() {
    _statusFilter = v;
    _currentPage = 1;
  });
  void setCurrentPage(int v) => setState(() => _currentPage = v);
  void setCreateStatus(String v) => setState(() => _createStatus = v);

  void openCreateProjectScreen() => setState(() {
    _isCreateMode = true;
    _isUpdateMode = false;
    _editingProjectId = null;
    _createNameController.clear();
    _createDescriptionController.clear();
    _createManagerController.clear();
    _selectedTeamLead = null;
    _selectedMentor = null;
    _selectedMembers = [];
  });

  void openUpdateProjectScreen(Map<String, dynamic> project) => setState(() {
    _isCreateMode = false;
    _isUpdateMode = true;
    _editingProjectId = project['id'];
    _createNameController.text = project['name'];
    _createDescriptionController.text = project['description'];
    _createManagerController.text = project['manager'];
    _createStatus = project['status'];
  });

  void closeFormScreen() => setState(() {
    _isCreateMode = false;
    _isUpdateMode = false;
    _editingProjectId = null;
  });

  void submitCreateProject() {
    if (_createNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên dự án'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() {
      _projects.insert(0, {
        'id': 'PRJ${DateTime.now().millisecondsSinceEpoch}',
        'name': _createNameController.text,
        'description': _createDescriptionController.text,
        'status': _createStatus,
        'progress': 0,
        'startDate': DateTime.now().toString().split(' ')[0],
        'deadline': '2026-12-31',
        'manager':
            _createManagerController.text.isNotEmpty
                ? _createManagerController.text
                : 'Chưa có',
        'members': 0,
      });
      _isCreateMode = false;
      _currentPage = 1;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã tạo dự án thành công'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void submitUpdateProject() {
    if (_editingProjectId == null) return;
    setState(() {
      final index = _projects.indexWhere((p) => p['id'] == _editingProjectId);
      if (index != -1)
        _projects[index] = {
          ..._projects[index],
          'name': _createNameController.text,
          'description': _createDescriptionController.text,
          'manager': _createManagerController.text,
          'status': _createStatus,
        };
      _isUpdateMode = false;
      _editingProjectId = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã cập nhật dự án'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> handleDeleteProject(Map<String, dynamic> project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: const Text('Xóa dự án'),
            content: Text(
              'Bạn có chắc muốn xóa dự án "${project['name']}" không?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Xóa'),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      setState(() => _projects.removeWhere((p) => p['id'] == project['id']));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa dự án'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  List<Map<String, dynamic>> get filteredProjects =>
      _projects
          .where(
            (p) =>
                p['name'].toLowerCase().contains(_nameQuery.toLowerCase()) &&
                (_statusFilter == 'Tất cả' || p['status'] == _statusFilter),
          )
          .toList();
  List<Map<String, dynamic>> get paginatedProjects {
    final start = (_currentPage - 1) * _rowsPerPage;
    if (start >= filteredProjects.length) return [];
    return filteredProjects.sublist(
      start,
      (start + _rowsPerPage).clamp(0, filteredProjects.length),
    );
  }

  // Build methods for widgets
  Widget buildPageHeader() => Row(
    children: [
      const Text(
        'DANH SÁCH DỰ ÁN',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF64748B),
        ),
      ),
      const Spacer(),
      if (!_isCreateMode && !_isCreateMode)
        ElevatedButton.icon(
          onPressed: openCreateProjectScreen,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF137FEC),
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.add),
          label: const Text('Tạo dự án'),
        ),
    ],
  );

  Widget buildFormCard() => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button and title
        Row(
          children: [
            IconButton(
              onPressed: closeFormScreen,
              icon: const Icon(Icons.arrow_back, color: Color(0xFF64748B)),
            ),
            Text(
              _isUpdateMode ? 'Cập nhật dự án' : 'Tạo dự án mới',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // General Information Section
        _buildSectionCard(
          icon: Icons.info_outline,
          iconColor: const Color(0xFFEF4444),
          title: 'Thông tin chung',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildFormField(
                      label: 'Tên dự án',
                      child: TextField(
                        controller: _createNameController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Hiện đại hóa cơ sở hạ tầng',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildFormField(
                      label: 'Trạng thái dự án',
                      child: DropdownButtonFormField<String>(
                        value: _createStatus,
                        hint: Text('Chọn trạng thái', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Planning', child: Text('Lập kế hoạch')),
                          DropdownMenuItem(value: 'In Progress', child: Text('Đang thực hiện')),
                          DropdownMenuItem(value: 'Completed', child: Text('Hoàn thành')),
                          DropdownMenuItem(value: 'On Hold', child: Text('Tạm dừng')),
                        ],
                        onChanged: (v) => setCreateStatus(v!),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildFormField(
                label: 'Mô tả',
                child: TextField(
                  controller: _createDescriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                        'Mô tả ngắn gọn về mục tiêu và phạm vi dự án...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Project Timeline Section
        _buildSectionCard(
          icon: Icons.calendar_today_outlined,
          iconColor: const Color(0xFF3B82F6),
          title: 'Thời gian dự án',
          child: Row(
            children: [
              Expanded(
                child: _buildFormField(
                  label: 'Ngày bắt đầu',
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _startDate != null
                                ? '${_startDate!.day.toString().padLeft(2, '0')}/${_startDate!.month.toString().padLeft(2, '0')}/${_startDate!.year}'
                                : 'dd/mm/yyyy',
                            style: TextStyle(
                              color:
                                  _startDate != null
                                      ? Colors.black87
                                      : Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildFormField(
                  label: 'Ngày kết thúc dự kiến',
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _endDate != null
                                ? '${_endDate!.month.toString().padLeft(2, '0')}/${_endDate!.day.toString().padLeft(2, '0')}/${_endDate!.year}'
                                : 'mm/dd/yyyy',
                            style: TextStyle(
                              color:
                                  _endDate != null
                                      ? Colors.black87
                                      : Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Team Lead Section
        _buildSectionCard(
          icon: Icons.person_outline,
          iconColor: const Color(0xFF8B5CF6),
          title: 'Trưởng nhóm',
          subtitle: 'Chọn trưởng nhóm dự án.',
          child:
              _selectedTeamLead != null
                  ? _buildSelectedPersonCard(
                    _selectedTeamLead!,
                    () => _showTeamLeadPicker(),
                  )
                  : _buildSelectButton(
                    'Chọn trưởng nhóm',
                    () => _showTeamLeadPicker(),
                  ),
        ),
        const SizedBox(height: 24),

        // Mentor Section
        _buildSectionCard(
          icon: Icons.school_outlined,
          iconColor: const Color(0xFFF97316),
          title: 'Người hướng dẫn',
          subtitle: 'Chọn người hướng dẫn cho dự án này.',
          child:
              _selectedMentor != null
                  ? _buildSelectedPersonCard(
                    _selectedMentor!,
                    () => _showMentorPicker(),
                  )
                  : _buildSelectButton(
                    'Chọn người hướng dẫn',
                    () => _showMentorPicker(),
                  ),
        ),
        const SizedBox(height: 24),

        // Team Members Section
        _buildSectionCard(
          icon: Icons.people_outline,
          iconColor: const Color(0xFF10B981),
          title: 'Thành viên nhóm',
          subtitle: 'Chọn thành viên cho dự án này.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedMembers.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      _selectedMembers
                          .map(
                            (member) => Chip(
                              avatar: CircleAvatar(
                                backgroundColor: const Color(0xFF10B981),
                                child: Text(
                                  member['avatar'],
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              label: Text(
                                member['name'],
                                style: const TextStyle(fontSize: 13),
                              ),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted:
                                  () => setState(
                                    () => _selectedMembers.remove(member),
                                  ),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 16),
              ],
              _buildSelectButton(
                'Thêm thành viên',
                () => _showMembersPicker(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: closeFormScreen,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed:
                  _isUpdateMode ? submitUpdateProject : submitCreateProject,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF137FEC),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(_isUpdateMode ? 'Cập nhật dự án' : 'Tạo dự án mới'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildFormField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          isStartDate
              ? (_startDate ?? DateTime.now())
              : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Widget _buildSelectButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: Colors.grey[400]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedPersonCard(
    Map<String, dynamic> person,
    VoidCallback onChange,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF8B5CF6),
            radius: 24,
            child: Text(
              person['avatar'],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  person['email'],
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChange,
            child: const Text(
              'Change',
              style: TextStyle(
                color: Color(0xFF8B5CF6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTeamLeadPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (ctx) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chọn trưởng nhóm',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (_employees.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No employees available'),
                    ),
                  )
                else
                  ..._employees.map(
                    (employee) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF8B5CF6),
                        child: Text(
                          employee.firstName.isNotEmpty 
                              ? employee.firstName[0].toUpperCase() 
                              : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(employee.fullName),
                      subtitle: Text(employee.email),
                      onTap: () {
                        setState(() => _selectedTeamLead = {
                          'id': employee.id,
                          'name': employee.fullName,
                          'email': employee.email,
                          'avatar': employee.firstName.isNotEmpty 
                              ? employee.firstName[0].toUpperCase() 
                              : '?',
                        });
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
              ],
            ),
          ),
    );
  }

  void _showMentorPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (ctx) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chọn người hướng dẫn',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ..._mentors.map(
                  (m) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFF97316),
                      child: Text(
                        m['avatar'],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(m['name']),
                    subtitle: Row(
                      children: [
                        Text(m['email']),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFF97316,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            m['role'].toString().toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFFF97316),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      setState(() => _selectedMentor = m);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showMembersPicker() {
    final availableToSelect =
        _availableMembers
            .where((m) => !_selectedMembers.any((s) => s['id'] == m['id']))
            .toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (ctx) => DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.8,
            expand: false,
            builder:
                (_, controller) => Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chọn thành viên',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          controller: controller,
                          itemCount: availableToSelect.length,
                          itemBuilder: (_, i) {
                            final member = availableToSelect[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF10B981),
                                child: Text(
                                  member['avatar'],
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(member['name']),
                              subtitle: Text(member['email']),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  color: Color(0xFF10B981),
                                ),
                                onPressed: () {
                                  setState(() => _selectedMembers.add(member));
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget buildTableSection() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    ),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _statusFilter,
                items:
                    [
                          'Tất cả',
                          'Planning',
                          'In Progress',
                          'Completed',
                          'On Hold',
                        ]
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                onChanged: (v) => setStatusFilter(v!),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Mã')),
              DataColumn(label: Text('Tên dự án')),
              DataColumn(label: Text('Quản lý')),
              DataColumn(label: Text('Trạng thái')),
              DataColumn(label: Text('Tiến độ')),
              DataColumn(label: Text('Deadline')),
              DataColumn(label: Text('Thao tác')),
            ],
            rows:
                paginatedProjects
                    .map(
                      (project) => DataRow(
                        cells: [
                          DataCell(Text(project['id'])),
                          DataCell(Text(project['name'])),
                          DataCell(Text(project['manager'])),
                          DataCell(buildStatusBadge(project['status'])),
                          DataCell(buildProgressBar(project['progress'])),
                          DataCell(Text(project['deadline'])),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed:
                                      () => openUpdateProjectScreen(project),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => handleDeleteProject(project),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed:
                    _currentPage > 1
                        ? () => setCurrentPage(_currentPage - 1)
                        : null,
              ),
              Text('Trang $_currentPage'),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed:
                    _currentPage * _rowsPerPage < filteredProjects.length
                        ? () => setCurrentPage(_currentPage + 1)
                        : null,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget buildStatusBadge(String status) {
    Color c =
        status == 'In Progress'
            ? Colors.green
            : status == 'Planning'
            ? Colors.orange
            : status == 'Completed'
            ? Colors.blue
            : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(color: c, fontWeight: FontWeight.w500, fontSize: 12),
      ),
    );
  }

  Widget buildProgressBar(int progress) {
    Color c =
        progress >= 75
            ? Colors.green
            : progress >= 50
            ? Colors.orange
            : progress >= 25
            ? Colors.red
            : Colors.grey;
    return SizedBox(
      width: 100,
      child: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(c),
            ),
          ),
          const SizedBox(width: 8),
          Text('$progress%'),
        ],
      ),
    );
  }

  Widget buildProjectList() => ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: _projects.length,
    itemBuilder: (context, index) => _buildProjectCard(_projects[index]),
  );

  Widget _buildProjectCard(Map<String, dynamic> project) {
    Color c =
        project['status'] == 'In Progress'
            ? Colors.green
            : project['status'] == 'Planning'
            ? Colors.orange
            : project['status'] == 'Completed'
            ? Colors.blue
            : Colors.red;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    project['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    project['status'],
                    style: TextStyle(
                      color: c,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              project['description'],
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  project['manager'],
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Spacer(),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  project['deadline'],
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: project['progress'] / 100,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation<Color>(c),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${project['progress']}%'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Sửa'),
                  onPressed: () => openUpdateProjectScreen(project),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  label: const Text('Xóa', style: TextStyle(color: Colors.red)),
                  onPressed: () => handleDeleteProject(project),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (kIsWeb || constraints.maxWidth > 850) {
              return ProjectManagementWeb(
                pageHeader: buildPageHeader(),
                formCard: buildFormCard(),
                tableSection: buildTableSection(),
                showForm: _isCreateMode || _isUpdateMode,
                userName: CurrentUserStore.currentUser.fullName,
                onLogout: handleLogout,
              );
            } else {
              return ProjectManagementMobile(
                pageHeader: buildPageHeader(),
                formCard: buildFormCard(),
                projectList: buildProjectList(),
                showForm: _isCreateMode || _isUpdateMode,
                userName: CurrentUserStore.currentUser.fullName,
                onLogout: handleLogout,
              );
            }
          },
        ),
      ),
    );
  }
}
