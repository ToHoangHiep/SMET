import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/department_model.dart';
import 'package:smet/model/user_model.dart';
import 'package:smet/service/department_management/api_department_management.dart';
import 'package:smet/service/user_management/api_user_management.dart';
import '../widgets/form/department_management_form_card.dart';
import '../widgets/shell/department_management_page_header.dart';
import '../widgets/shell/department_management_sidebar.dart';
import '../widgets/shell/department_management_top_header.dart';
import '../widgets/table/department_management_table_section.dart';

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
  final int _rowsPerPage = 5;

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
            DepartmentManagementSidebar(onLogout: _handleLogout),
            Expanded(
              child: Column(
                children: [
                  const DepartmentManagementTopHeader(),
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
                                  DepartmentManagementPageHeader(
                                    onCreateDepartment:
                                        _openCreateDepartmentScreen,
                                  ),
                                  const SizedBox(height: 20),
                                  (_isCreateMode || _isUpdateMode)
                                      ? DepartmentManagementFormCard(
                                        formKey: _createFormKey,
                                        isUpdateMode: _isUpdateMode,
                                        nameController: _createNameController,
                                        codeController: _createCodeController,
                                        managerController:
                                            _createManagerController,
                                        isActive: _createIsActive,
                                        selectedEmployees: _selectedEmployees,
                                        onPickManager: _pickManager,
                                        onPickEmployees: _pickEmployees,
                                        onActiveChanged: (value) {
                                          setState(
                                            () => _createIsActive = value,
                                          );
                                        },
                                        onRemoveEmployee: (employee) {
                                          setState(() {
                                            _selectedEmployees.remove(employee);
                                          });
                                        },
                                        onCancel: _closeCreateDepartmentScreen,
                                        onSubmit:
                                            _isUpdateMode
                                                ? _submitUpdateDepartment
                                                : _submitCreateDepartment,
                                      )
                                      : DepartmentManagementTableSection(
                                        paginatedDepartments:
                                            _paginatedDepartments,
                                        filteredDepartments:
                                            _filteredDepartments,
                                        departmentActiveMap:
                                            _departmentActiveMap,
                                        statusFilter: _statusFilter,
                                        currentPage: _currentPage,
                                        rowsPerPage: _rowsPerPage,
                                        onCodeChanged: (value) {
                                          setState(() {
                                            _codeQuery = value;
                                            _currentPage = 1;
                                          });
                                        },
                                        onManagerChanged: (value) {
                                          setState(() {
                                            _managerQuery = value;
                                            _currentPage = 1;
                                          });
                                        },
                                        onStatusChanged: (value) {
                                          setState(() {
                                            _statusFilter = value;
                                            _currentPage = 1;
                                          });
                                        },
                                        onToggleActive: (dept, value) {
                                          setState(() {
                                            _departmentActiveMap[dept.id] =
                                                value;
                                          });
                                        },
                                        onEdit: _openUpdateDepartmentScreen,
                                        onDelete: _handleDeleteDepartment,
                                        onShowDetail:
                                            _showDepartmentDetailDialog,
                                        onPrevPage:
                                            _currentPage > 1
                                                ? () {
                                                  setState(() {
                                                    _currentPage--;
                                                  });
                                                }
                                                : null,
                                        onNextPage:
                                            _currentPage * _rowsPerPage <
                                                    _filteredDepartments.length
                                                ? () {
                                                  setState(() {
                                                    _currentPage++;
                                                  });
                                                }
                                                : null,
                                      ),
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
}
