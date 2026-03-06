import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/department_model.dart';
import 'package:smet/model/user_model.dart';
import 'package:smet/service/department_management/api_department_management.dart';
import 'package:smet/service/user_management/api_user_management.dart';

// --- ĐỊNH NGHĨA MÀU SẮC CHUNG ---
class AppColors {
  static const Color primary = Color(0xFF137FEC);
  static const Color bgLight = Color(0xFFF3F6FC);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFE5E7EB);
}

class DepartmentManagementPage extends StatefulWidget {
  const DepartmentManagementPage({super.key});

  @override
  State<DepartmentManagementPage> createState() =>
      _DepartmentManagementPageState();
}

class _DepartmentManagementPageState extends State<DepartmentManagementPage> {
  final DepartmentService _departmentService = DepartmentService();
  final ApiService _userApiService = ApiService();

  List<DepartmentModel> _departments = [];
  List<UserModel> _users = [];
  bool _isLoading = true;

  String _codeQuery = '';
  String _managerQuery = '';
  String _statusFilter = 'Tất cả';

  int _currentPage = 1;
  int _rowsPerPage = 10;

  final Map<String, bool> _departmentActiveMap = {};

  bool _isCreateMode = false;
  bool _isUpdateMode = false;
  String? _editingDepartmentId;
  final _createFormKey = GlobalKey<FormState>();
  final TextEditingController _createNameController = TextEditingController();
  final TextEditingController _createCodeController = TextEditingController();
  final TextEditingController _createManagerController =
      TextEditingController();
  bool _createIsActive = true;

  List<String> get _managerOptions {
    return _users
        .where(
          (u) => u.role == UserRole.admin || u.role == UserRole.projectManager,
        )
        .map((u) => u.fullName)
        .toSet()
        .toList();
  }

  List<String> get _employeeOptions {
    return _users.map((u) => u.fullName).toSet().toList();
  }

  final List<String> _selectedEmployees = [];

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  @override
  void dispose() {
    _createNameController.dispose();
    _createCodeController.dispose();
    _createManagerController.dispose();
    super.dispose();
  }

  Future<void> _pickManager() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Chọn người quản lý'),
          content: SizedBox(
            width: 360,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _managerOptions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final manager = _managerOptions[index];
                return ListTile(
                  title: Text(manager),
                  trailing:
                      _createManagerController.text == manager
                          ? const Icon(Icons.check, color: AppColors.primary)
                          : null,
                  onTap: () => Navigator.pop(dialogContext, manager),
                );
              },
            ),
          ),
        );
      },
    );

    if (selected == null) return;

    setState(() {
      _createManagerController.text = selected;
    });
  }

  Future<void> _pickEmployees() async {
    final tempSelected = List<String>.from(_selectedEmployees);

    final result = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Thêm nhân viên trực thuộc'),
              content: SizedBox(
                width: 420,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _employeeOptions.length,
                  itemBuilder: (context, index) {
                    final employee = _employeeOptions[index];
                    final checked = tempSelected.contains(employee);

                    return CheckboxListTile(
                      value: checked,
                      title: Text(employee),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (value) {
                        setDialogState(() {
                          if (value == true) {
                            tempSelected.add(employee);
                          } else {
                            tempSelected.remove(employee);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, tempSelected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Xác nhận'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    setState(() {
      _selectedEmployees
        ..clear()
        ..addAll(result);
    });
  }

  Future<void> _fetchDepartments() async {
    try {
      final results = await Future.wait([
        _departmentService.getDepartments(),
        _userApiService.getUsers(),
      ]);

      final departments = results[0] as List<DepartmentModel>;
      final users = results[1] as List<UserModel>;

      setState(() {
        _departments = departments;
        _users = users;
        _departmentActiveMap
          ..clear()
          ..addEntries(departments.map((e) => MapEntry(e.id, true)));
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Xử lý lỗi (show SnackBar...)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Row(
          children: [
            _buildSidebar(),
            Expanded(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child:
                        _isLoading
                            ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            )
                            : SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                20,
                                24,
                                24,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildPageTitleAndActions(),
                                  const SizedBox(height: 20),
                                  (_isCreateMode || _isUpdateMode)
                                      ? _buildCreateDepartmentScreen()
                                      : _buildDepartmentTableSection(),
                                ],
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== WIDGETS THÀNH PHẦN =====================

  Widget _buildSidebar() {
    return Container(
      width: 270,
      margin: const EdgeInsets.fromLTRB(12, 12, 0, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'S',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Quản trị SMETS',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _sidebarItem(Icons.person, 'Quản lý nhân viên', route: '/'),
          _sidebarItem(
            Icons.model_training,
            'Quản lý đào tạo',
            route: '/training_management',
          ),
          _sidebarItem(
            Icons.apartment,
            'Quản lý phòng ban',
            route: '/department_management',
            isActive: true,
          ),
          const Spacer(),
          const Divider(height: 1),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 4,
            ),
            leading: const CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: const Text(
              'Quản trị viên',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('John Doe', style: TextStyle(fontSize: 12)),
            trailing: Tooltip(
              message: 'Đăng xuất',
              child: IconButton(
                icon: const Icon(Icons.logout, color: Colors.grey),
                onPressed: _handleLogout,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _sidebarItem(
    IconData icon,
    String title, {
    bool isActive = false,
    required String route,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFEBF5FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border:
            isActive
                ? Border(right: BorderSide(width: 4, color: AppColors.primary))
                : null,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          icon,
          color: isActive ? AppColors.primary : Colors.grey[600],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? AppColors.primary : Colors.grey[700],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        onTap: () {
          context.go(route);
        },
      ),
    );
  }

  void _handleLogout() {
    context.go('/login');
  }

  void _openCreateDepartmentScreen() {
    setState(() {
      _isCreateMode = true;
      _isUpdateMode = false;
      _editingDepartmentId = null;
      _createNameController.clear();
      _createCodeController.clear();
      _createManagerController.clear();
      _createIsActive = true;
      _selectedEmployees.clear();
    });
  }

  void _openUpdateDepartmentScreen(DepartmentModel department) {
    setState(() {
      _isCreateMode = false;
      _isUpdateMode = true;
      _editingDepartmentId = department.id;
      _createNameController.text = department.name;
      _createCodeController.text = department.id;
      _createManagerController.text = department.leadName;
      _createIsActive = _departmentActiveMap[department.id] ?? true;
      _selectedEmployees
        ..clear()
        ..addAll(
          List.generate(department.teamSize, (i) => 'Nhân viên ${i + 1}'),
        );
    });
  }

  void _closeCreateDepartmentScreen() {
    setState(() {
      _isCreateMode = false;
      _isUpdateMode = false;
      _editingDepartmentId = null;
    });
  }

  Future<void> _submitCreateDepartment() async {
    if (!_createFormKey.currentState!.validate()) {
      return;
    }

    if (_createManagerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn người quản lý'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final created = await _departmentService.createDepartment(
      name: _createNameController.text.trim(),
      description:
          'Bộ phận có ${_selectedEmployees.length} nhân viên trực thuộc.',
      leadName: _createManagerController.text.trim(),
      code: _createCodeController.text.trim(),
      teamSize: _selectedEmployees.length,
    );

    if (!mounted) return;

    setState(() {
      _departments.insert(0, created);
      _departmentActiveMap[created.id] = _createIsActive;
      _isCreateMode = false;
      _currentPage = 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã tạo bộ phận thành công'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _submitUpdateDepartment() async {
    if (!_createFormKey.currentState!.validate()) {
      return;
    }
    if (_editingDepartmentId == null) return;

    if (_createManagerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn người quản lý'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final updated = await _departmentService.updateDepartment(
      id: _editingDepartmentId!,
      name: _createNameController.text.trim(),
      description:
          'Bộ phận có ${_selectedEmployees.length} nhân viên trực thuộc.',
      leadName: _createManagerController.text.trim(),
    );

    if (!mounted || updated == null) return;

    setState(() {
      final index = _departments.indexWhere((d) => d.id == updated.id);
      if (index != -1) {
        _departments[index] = updated;
      }
      _departmentActiveMap[updated.id] = _createIsActive;
      _isUpdateMode = false;
      _editingDepartmentId = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã cập nhật bộ phận thành công'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _showCreateDepartmentDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final leadNameController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text('Tạo phòng ban mới'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên phòng ban',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên phòng ban';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: leadNameController,
                    decoration: const InputDecoration(
                      labelText: 'Trưởng phòng',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên trưởng phòng';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập mô tả';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                final created = await _departmentService.createDepartment(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  leadName: leadNameController.text.trim(),
                );

                if (!mounted) return;

                setState(() {
                  _departments.insert(0, created);
                });

                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã tạo phòng ban thành công'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tạo phòng ban'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();
    leadNameController.dispose();
  }

  Future<void> _showUpdateDepartmentDialog(DepartmentModel department) async {
    final nameController = TextEditingController(text: department.name);
    final descriptionController = TextEditingController(
      text: department.description,
    );
    final leadNameController = TextEditingController(text: department.leadName);

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text('Cập nhật phòng ban'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên phòng ban',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên phòng ban';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: leadNameController,
                    decoration: const InputDecoration(
                      labelText: 'Trưởng phòng',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên trưởng phòng';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập mô tả';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                final updated = await _departmentService.updateDepartment(
                  id: department.id,
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  leadName: leadNameController.text.trim(),
                );

                if (!mounted || updated == null) return;

                setState(() {
                  final index = _departments.indexWhere(
                    (dept) => dept.id == updated.id,
                  );
                  if (index != -1) {
                    _departments[index] = updated;
                  }
                });

                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã cập nhật phòng ban thành công'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Lưu thay đổi'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();
    leadNameController.dispose();
  }

  Future<void> _handleDeleteDepartment(DepartmentModel department) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text('Xóa phòng ban'),
          content: Text(
            'Bạn có chắc muốn xóa phòng ban "${department.name}" không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final isDeleted = await _departmentService.deleteDepartment(department.id);

    if (!mounted || !isDeleted) return;

    setState(() {
      _departments.removeWhere((dept) => dept.id == department.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã xóa phòng ban thành công'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _showDepartmentDetailDialog(DepartmentModel department) async {
    final averageSkillLevel = ((department.activeProjects * 12) +
            (department.teamSize * 2))
        .clamp(0, 100);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Text('Chi tiết phòng ban: ${department.name}'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: department.iconBgColor,
                    child: Icon(department.icon, color: department.iconColor),
                  ),
                  title: Text(
                    department.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(department.description),
                ),
                const Divider(height: 24),
                _buildDetailRow('Department Lead', department.leadName),
                _buildDetailRow(
                  'Roster (Team Size)',
                  '${department.teamSize} thành viên',
                ),
                _buildDetailRow(
                  'Active Projects',
                  '${department.activeProjects} dự án',
                ),
                const SizedBox(height: 14),
                const Text(
                  'Aggregate Skill Level',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    minHeight: 12,
                    value: averageSkillLevel / 100,
                    backgroundColor: const Color(0xFFE5E7EB),
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$averageSkillLevel%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted)),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 76,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Text(
            'Bảng điều khiển quản trị',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none, color: Colors.grey),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageTitleAndActions() {
    return Row(
      children: [
        const Text(
          'DANH SÁCH BỘ PHẬN',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B7280),
          ),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: _openCreateDepartmentScreen,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Tạo bộ phận'),
        ),
      ],
    );
  }

  List<DepartmentModel> get _filteredDepartments {
    return _departments.where((dept) {
      final idLike = dept.id.toLowerCase().contains(_codeQuery.toLowerCase());
      final managerLike = dept.leadName.toLowerCase().contains(
        _managerQuery.toLowerCase(),
      );
      final isActive = _departmentActiveMap[dept.id] ?? true;
      final statusMatch =
          _statusFilter == 'Tất cả' ||
          (_statusFilter == 'Đang hoạt động' ? isActive : !isActive);
      return idLike && managerLike && statusMatch;
    }).toList();
  }

  List<DepartmentModel> get _paginatedDepartments {
    final start = (_currentPage - 1) * _rowsPerPage;
    if (start >= _filteredDepartments.length) return [];
    final end = (start + _rowsPerPage).clamp(0, _filteredDepartments.length);
    return _filteredDepartments.sublist(start, end);
  }

  int get _totalPages {
    if (_filteredDepartments.isEmpty) return 1;
    return (_filteredDepartments.length / _rowsPerPage).ceil();
  }

  Widget _buildCreateDepartmentScreen() {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.borderLight),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Form(
        key: _createFormKey,
        child: Center(
          child: SizedBox(
            width: 560,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14),
                    children: [
                      const TextSpan(
                        text: 'Danh sách bộ phận',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text:
                            _isUpdateMode
                                ? ' / Cập nhật bộ phận'
                                : ' / Tạo bộ phận',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                TextFormField(
                  controller: _createNameController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: '* Tên bộ phận',
                    hintText: 'Tên bộ phận',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: inputBorder,
                    enabledBorder: inputBorder,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên bộ phận';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _createCodeController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: '* Mã bộ phận',
                    hintText: 'Mã bộ phận',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: inputBorder,
                    enabledBorder: inputBorder,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập mã bộ phận';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _createManagerController,
                        readOnly: true,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Người quản lý',
                          hintText: 'Chọn người quản lý',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          border: inputBorder,
                          enabledBorder: inputBorder,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 40,
                      child: OutlinedButton(
                        onPressed: _pickManager,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('CHỌN NGƯỜI QUẢN LÝ'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Trạng thái hoạt động',
                  style: TextStyle(fontSize: 14, color: AppColors.textDark),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: _createIsActive,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _createIsActive = value);
                      },
                    ),
                    const Text('Bật', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Radio<bool>(
                      value: false,
                      groupValue: _createIsActive,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _createIsActive = value);
                      },
                    ),
                    const Text('Tắt', style: TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.borderLight),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _selectedEmployees.isEmpty
                              ? 'Nhân viên trực thuộc'
                              : '${_selectedEmployees.length} nhân viên đã chọn',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                _selectedEmployees.isEmpty
                                    ? AppColors.textMuted
                                    : AppColors.textDark,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 40,
                      child: OutlinedButton(
                        onPressed: _pickEmployees,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('THÊM NHÂN VIÊN'),
                      ),
                    ),
                  ],
                ),
                if (_selectedEmployees.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _selectedEmployees
                            .map(
                              (e) => Chip(
                                label: Text(
                                  e,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                onDeleted: () {
                                  setState(() {
                                    _selectedEmployees.remove(e);
                                  });
                                },
                              ),
                            )
                            .toList(),
                  ),
                ],
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 38,
                      child: OutlinedButton(
                        onPressed: _closeCreateDepartmentScreen,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('HỦY'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 38,
                      child: ElevatedButton(
                        onPressed:
                            _isUpdateMode
                                ? _submitUpdateDepartment
                                : _submitCreateDepartment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: Text(_isUpdateMode ? 'CẬP NHẬT' : 'XÁC NHẬN'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDepartmentTableSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          _buildFiltersRow(),
          const SizedBox(height: 12),
          _buildDepartmentTable(),
          const SizedBox(height: 12),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildFiltersRow() {
    return Row(
      children: [
        SizedBox(
          width: 220,
          child: TextField(
            decoration: _filterInputDecoration('Mã bộ phận'),
            onChanged:
                (value) => setState(() {
                  _codeQuery = value;
                  _currentPage = 1;
                }),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 220,
          child: TextField(
            decoration: _filterInputDecoration('Người quản lý'),
            onChanged:
                (value) => setState(() {
                  _managerQuery = value;
                  _currentPage = 1;
                }),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 210,
          child: DropdownButtonFormField<String>(
            value: _statusFilter,
            decoration: _filterInputDecoration('Trạng thái hoạt động'),
            items: const [
              DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả')),
              DropdownMenuItem(
                value: 'Đang hoạt động',
                child: Text('Đang hoạt động'),
              ),
              DropdownMenuItem(value: 'Tạm dừng', child: Text('Tạm dừng')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _statusFilter = value;
                _currentPage = 1;
              });
            },
          ),
        ),
      ],
    );
  }

  InputDecoration _filterInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      suffixIcon: const Icon(Icons.search, size: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
    );
  }

  Widget _buildDepartmentTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
        columns: const [
          DataColumn(label: Text('MÃ PHÒNG BAN')),
          DataColumn(label: Text('TÊN PHÒNG BAN')),
          DataColumn(label: Text('NGƯỜI QUẢN LÝ')),
          DataColumn(label: Text('HOẠT ĐỘNG')),
          DataColumn(label: Text('NGÀY CẬP NHẬT')),
          DataColumn(label: Text('THAO TÁC')),
        ],
        rows: List.generate(_paginatedDepartments.length, (index) {
          final dept = _paginatedDepartments[index];
          final isActive = _departmentActiveMap[dept.id] ?? true;

          return DataRow(
            cells: [
              DataCell(Text(dept.id)),
              DataCell(
                InkWell(
                  onTap: () => _showDepartmentDetailDialog(dept),
                  child: Text(
                    dept.name,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              DataCell(Text(dept.leadName)),
              DataCell(
                Switch(
                  value: isActive,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() {
                      _departmentActiveMap[dept.id] = value;
                    });
                  },
                ),
              ),
              const DataCell(Text('16/07/2021')),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _openUpdateDepartmentScreen(dept),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                    ),
                    IconButton(
                      onPressed: () => _handleDeleteDepartment(dept),
                      icon: const Icon(Icons.delete_outline, size: 18),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPagination() {
    final total = _filteredDepartments.length;
    final start = total == 0 ? 0 : (_currentPage - 1) * _rowsPerPage + 1;
    final end =
        total == 0
            ? 0
            : (_currentPage * _rowsPerPage > total
                ? total
                : _currentPage * _rowsPerPage);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Hiển thị $start - $end trong số $total kết quả',
          style: TextStyle(color: Colors.grey[700], fontSize: 14),
        ),
        Row(
          children: [
            OutlinedButton(
              onPressed:
                  _currentPage > 1
                      ? () {
                        setState(() {
                          _currentPage--;
                        });
                      }
                      : null,
              child: const Text('Trước'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed:
                  _currentPage * _rowsPerPage < total
                      ? () {
                        setState(() {
                          _currentPage++;
                        });
                      }
                      : null,
              child: const Text('Sau'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDepartmentCard(DepartmentModel dept) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon & Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: dept.iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(dept.icon, color: dept.iconColor),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => _openUpdateDepartmentScreen(dept),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => _handleDeleteDepartment(dept),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Title & Description
          Text(
            dept.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dept.description,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 24),
          const Spacer(), // Đẩy phần dưới xuống cuối
          // Stats
          _buildStatRow(
            "Department Lead",
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundImage: NetworkImage(dept.leadAvatarUrl),
                ),
                const SizedBox(width: 8),
                Text(
                  dept.leadName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            "Team Size",
            child: Text(
              "${dept.teamSize} Members",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            "Active Projects",
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "${dept.activeProjects} Active",
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // View Details Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showDepartmentDetailDialog(dept),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "View Details",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, {required Widget child}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
        child,
      ],
    );
  }

  // Card để tạo Department mới (Dashed Border)
  Widget _buildCreateNewCard() {
    return InkWell(
      onTap: _openCreateDepartmentScreen,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.borderLight,
            width: 2,
          ), // Dùng Solid Border thay vì Dashed để đơn giản hóa Flutter
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            const Text(
              "Create New Department",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.only(top: 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.copyright, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                "2024 SMETS Management Hub. All rights reserved.",
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ],
          ),
          Row(
            children:
                ["Privacy Policy", "Terms of Service", "Contact Hub"]
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: Text(
                          e,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }
}
