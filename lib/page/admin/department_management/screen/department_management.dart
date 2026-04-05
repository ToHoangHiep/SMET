import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/department_model.dart';
import 'package:smet/model/user_model.dart' as user_model;
import 'package:smet/service/admin/department_management/api_department_management.dart';
import 'package:smet/service/common/user_selection_service.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import '../widgets/form/department_management_form_card.dart';
import '../widgets/shell/department_management_page_header.dart';
import '../widgets/shell/department_management_top_header.dart';
import '../widgets/table/department_management_table_section.dart';
import '../widgets/dialog/user_selection_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:smet/service/admin/user_management/user_management_service.dart';
import 'package:smet/service/common/auth_service.dart';
import 'package:smet/page/shared/widgets/app_toast.dart';
import 'dart:developer';

// --- ĐỊNH NGHĨA MÀU SẮC CHUNG ---
class AppColors {
  static const Color primary = Color(0xFF6366F1); // Indigo như login
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
  String username = "";

  final DepartmentService _departmentService = DepartmentService();
  final UserManagementApi _apiService = UserManagementApi();
  List<DepartmentModel> _departments = [];
  List<user_model.UserModel> _users = [];
  bool _isLoading = true;

  String _codeQuery = '';
  String _managerQuery = '';
  String _statusFilter = 'Tất cả';

  int _currentPage = 1;
  final int _rowsPerPage = 5;

  final Map<int, bool> _departmentActiveMap = {};
  bool _isCreateMode = false;
  bool _isUpdateMode = false;
  int? _editingDepartmentId;
  final _createFormKey = GlobalKey<FormState>();
  final TextEditingController _createNameController = TextEditingController();
  final TextEditingController _createCodeController = TextEditingController();
  final TextEditingController _createManagerController =
      TextEditingController();
  bool _createIsActive = true;

  user_model.UserModel? _selectedManager;
  final List<user_model.UserModel> _selectedEmployees = [];

  final Color _primaryColor = const Color(0xFF6366F1); // Indigo như login
  final Color _bgLight = const Color(0xFFF3F6FC);

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
    // Gọi API mới: lấy danh sách Project Manager
    List<user_model.UserModel> managers;
    try {
      managers = await fetchSelectableUsers(
        UserSelectionContext.departmentProjectManager,
      );
    } catch (e) {
      if (!mounted) return;
      context.showAppToast('Lỗi lấy danh sách: $e', variant: AppToastVariant.error);
      return;
    }

    if (!mounted) return;

    final selected = await UserSelectionDialog.selectManager(
      context: context,
      primaryColor: _primaryColor,
      managers: managers,
      currentManager: _selectedManager,
      excludeDepartmentId: _editingDepartmentId,
    );

    if (selected == null) return;

    setState(() {
      _selectedManager = selected;
    });
  }

  Future<void> _pickEmployees() async {
    // Gọi API mới: lấy danh sách User + Mentor cho Department
    List<user_model.UserModel> availableUsers;
    try {
      availableUsers = await fetchSelectableUsers(
        UserSelectionContext.departmentMembers,
      );
    } catch (e) {
      if (!mounted) return;
      context.showAppToast('Lỗi lấy danh sách: $e', variant: AppToastVariant.error);
      return;
    }

    if (!mounted) return;

    final result = await UserSelectionDialog.selectMembers(
      context: context,
      primaryColor: _primaryColor,
      members: availableUsers,
      preSelectedMembers: _selectedEmployees,
      excludeDepartmentId: _editingDepartmentId,
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
      // Gọi API lấy departments và users
      final departmentResult = await _departmentService.getDepartments();
      final usersResult = await _apiService.getUsers();

      final departments =
          departmentResult['departments'] as List<DepartmentModel>;
      final users = usersResult['users'] as List<user_model.UserModel>;
      final totalElements = departmentResult['totalElements'] as int;

      log("TOTAL DEPARTMENTS FROM API: $totalElements");

      setState(() {
        _departments = departments;
        _users = users;
        _departmentActiveMap
          ..clear()
          ..addEntries(departments.map((e) => MapEntry(e.id, e.isActive)));
        _isLoading = false;
      });

      log("DEPARTMENTS LOADED: ${_departments.length}");
    } catch (e) {
      log("FETCH DEPARTMENTS ERROR: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🚫 CHẶN MOBILE
    if (!kIsWeb) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Trang quản trị chỉ hỗ trợ trên Web",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return ColoredBox(
      color: _bgLight,
      child: Column(
        children: [
          DepartmentManagementTopHeader(
                    primaryColor: _primaryColor,
                    breadcrumbs: const [
                      BreadcrumbItem(label: 'Quản lý phòng ban'),
                    ],
                  ),
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
                                    primaryColor: _primaryColor,
                                    onCreateDepartment:
                                        _openCreateDepartmentScreen,
                                  ),
                                  const SizedBox(height: 20),
                                  (_isCreateMode || _isUpdateMode)
                                      ? DepartmentManagementFormCard(
                                        primaryColor: _primaryColor,
                                        formKey: _createFormKey,
                                        isUpdateMode: _isUpdateMode,
                                        nameController: _createNameController,
                                        codeController: _createCodeController,
                                        selectedManager: _selectedManager,
                                        managerFallbackText:
                                            _createManagerController.text,
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
                                            _selectedEmployees.removeWhere(
                                              (e) => e.id == employee.id,
                                            );
                                          });
                                        },
                                        onCancel: _closeCreateDepartmentScreen,
                                        onSubmit:
                                            _isUpdateMode
                                                ? _submitUpdateDepartment
                                                : _submitCreateDepartment,
                                      )
                                      : DepartmentManagementTableSection(
                                        primaryColor: _primaryColor,
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
                                            (dept) => context.push(
                                              '/department_management/${dept.id}',
                                            ),
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
    );
  }

  // ===================== WIDGETS THÀNH PHẦN =====================

  void _handleLogout() async {
    await AuthService.logout();
    if (!mounted) return;
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
      _selectedManager = null;
      _createIsActive = true;
      _selectedEmployees.clear();
    });
  }

  void _openUpdateDepartmentScreen(DepartmentModel department) async {
    // Gọi API lấy danh sách PM để tìm manager hiện tại
    List<user_model.UserModel> managers;
    try {
      managers = await fetchSelectableUsers(
        UserSelectionContext.departmentProjectManager,
      );
    } catch (e) {
      managers = [];
    }

    final match =
        managers.where((u) => u.id == department.projectManagerId).toList();
    final manager = match.isEmpty ? null : match.first;

    // Gọi API lấy danh sách members của department
    List<Map<String, dynamic>> departmentMembers = [];
    try {
      departmentMembers = await _departmentService.getDepartmentMembers(
        department.id,
      );
      log(
        "Loaded ${departmentMembers.length} members for department ${department.id}",
      );
    } catch (e) {
      log("Error loading department members: $e");
    }

    // Chuyển đổi department members sang UserModel
    final selectedEmployees = <user_model.UserModel>[];
    for (final member in departmentMembers) {
      // Lọc bỏ PM vì đã có trong _selectedManager
      final role = member['role'] as String?;
      if (role != 'PROJECT_MANAGER' && role != 'ADMIN') {
        selectedEmployees.add(
          user_model.UserModel(
            id: member['id'] as int,
            userName: member['userName'] as String?,
            firstName: member['firstName'] ?? '',
            lastName: member['lastName'] as String?,
            email: member['email'] ?? '',
            phone: '',
            role: _parseRole(role ?? 'USER'),
            lastUpdated: DateTime.now(),
          ),
        );
      }
    }

    setState(() {
      _isCreateMode = false;
      _isUpdateMode = true;
      _editingDepartmentId = department.id;
      _createNameController.text = department.name;
      _createCodeController.text = department.code;
      _selectedManager = manager;
      if (manager == null) {
        _createManagerController.text = department.projectManagerName ?? '';
      } else {
        _createManagerController.clear();
      }
      _createIsActive = _departmentActiveMap[department.id] ?? true;
      _selectedEmployees
        ..clear()
        ..addAll(selectedEmployees);
    });
  }

  user_model.UserRole _parseRole(String role) {
    switch (role) {
      case 'ADMIN':
        return user_model.UserRole.ADMIN;
      case 'PROJECT_MANAGER':
        return user_model.UserRole.PROJECT_MANAGER;
      case 'MENTOR':
        return user_model.UserRole.MENTOR;
      default:
        return user_model.UserRole.USER;
    }
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

    if (_selectedManager == null) {
      context.showAppToast('Vui lòng chọn người quản lý', variant: AppToastVariant.info);
      return;
    }

    // Lưu projectManagerId trước khi gọi API
    final pmId = _selectedManager!.id;

    // Tách riêng USER và MENTOR từ danh sách đã chọn
    final mentorList =
        _selectedEmployees
            .where((e) => e.role.name == 'MENTOR')
            .map((e) => e.id)
            .toList();
    final userList =
        _selectedEmployees
            .where((e) => e.role.name == 'USER')
            .map((e) => e.id)
            .toList();

    final created = await _departmentService.createDepartment(
      name: _createNameController.text.trim(),
      code: _createCodeController.text.trim(),
      isActive: _createIsActive,
      projectManagerId: pmId,
      mentorIds: mentorList.isNotEmpty ? mentorList : null,
      userIds: userList.isNotEmpty ? userList : null,
    );

    setState(() {
      _isCreateMode = false;
      _currentPage = 1;
    });

    await _fetchDepartments();

    if (!mounted) return;

    context.showAppToast('Đã tạo bộ phận thành công');
  }

  Future<void> _submitUpdateDepartment() async {
    if (!_createFormKey.currentState!.validate()) {
      return;
    }
    if (_editingDepartmentId == null) return;

    // Lưu projectManagerId trước khi gọi API
    final pmId = _selectedManager?.id;

    // Tách riêng USER và MENTOR từ danh sách đã chọn
    final mentorList =
        _selectedEmployees
            .where((e) => e.role.name == 'MENTOR')
            .map((e) => e.id)
            .toList();
    final userList =
        _selectedEmployees
            .where((e) => e.role.name == 'USER')
            .map((e) => e.id)
            .toList();

    final updated = await _departmentService.updateDepartment(
      id: _editingDepartmentId!,
      name: _createNameController.text.trim(),
      code: _createCodeController.text.trim(),
      isActive: _createIsActive,
      projectManagerId: pmId,
      mentorIds: mentorList.isNotEmpty ? mentorList : null,
      userIds: userList.isNotEmpty ? userList : null,
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

    context.showAppToast('Đã cập nhật bộ phận thành công');
  }

  Future<void> _handleDeleteDepartment(DepartmentModel department) async {
    bool forceDelete = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text('Xóa phòng ban'),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bạn có chắc muốn xóa phòng ban "${department.name}" không?',
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Phòng ban này có thể chứa nhân viên, khóa học hoặc lộ trình học tập.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange.shade800,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: forceDelete ? Colors.red.shade50 : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: forceDelete ? Colors.red.shade200 : Colors.grey.shade300,
                        ),
                      ),
                      child: CheckboxListTile(
                        value: forceDelete,
                        onChanged: (val) {
                          setDialogState(() => forceDelete = val ?? false);
                        },
                        title: Row(
                          children: [
                            Icon(
                              Icons.delete_forever_rounded,
                              size: 20,
                              color: forceDelete ? Colors.red.shade700 : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Xóa toàn bộ dữ liệu',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: forceDelete ? Colors.red.shade700 : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(left: 28, top: 4),
                          child: Text(
                            forceDelete
                                ? 'Xóa tất cả nhân viên, khóa học, lộ trình liên quan'
                                : 'Chỉ xóa phòng ban rỗng',
                            style: TextStyle(
                              fontSize: 12,
                              color: forceDelete ? Colors.red.shade600 : Colors.grey.shade500,
                            ),
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(
                    'Hủy',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: forceDelete ? Colors.red : Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        forceDelete ? Icons.delete_forever_rounded : Icons.delete_rounded,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(forceDelete ? 'Xóa toàn bộ' : 'Xóa'),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    try {
      final result = await _departmentService.deleteDepartment(
        department.id,
        force: forceDelete,
      );

      if (!mounted) return;

      // Hiển thị thông báo thành công từ backend
      final message = result['message'] ?? 'Đã xóa phòng ban thành công';
      context.showAppToast(message, variant: AppToastVariant.success);

      setState(() {
        _departments.removeWhere((dept) => dept.id == department.id);
      });
    } catch (e) {
      if (!mounted) return;
      // Truncate error message nếu quá dài
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      final displayMsg = errorMsg.length > 100
          ? '${errorMsg.substring(0, 100)}...'
          : errorMsg;
      context.showAppToast(displayMsg, variant: AppToastVariant.error);
    }
  }

  Future<void> _showDepartmentDetailDialog(DepartmentModel department) async {
    const int averageSkillLevel = 0;

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
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.business, color: Colors.white),
                  ),
                  title: Text(
                    department.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 24),
                _buildDetailRow(
                  'Department Lead',
                  department.projectManagerName ?? '',
                ),

                _buildDetailRow(
                  'Active Projects',
                  '${department.isActive ? 'Đang hoạt động' : 'Không hoạt động'}',
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
      final idLike = dept.code.toLowerCase().contains(_codeQuery.toLowerCase());
      // Khi không tìm theo quản lý: cho qua. Khi có: so sánh (phòng ban không có quản lý = null thì không match)
      final managerMatch =
          _managerQuery.trim().isEmpty
              ? true
              : (dept.projectManagerName?.toLowerCase().contains(
                    _managerQuery.toLowerCase().trim(),
                  ) ??
                  false);
      final isActive = _departmentActiveMap[dept.id] ?? dept.isActive;
      final statusMatch =
          _statusFilter == 'Tất cả' ||
          (_statusFilter == 'Đang hoạt động' ? isActive : !isActive);
      return idLike && managerMatch && statusMatch;
    }).toList();
  }

  List<DepartmentModel> get _paginatedDepartments {
    final start = (_currentPage - 1) * _rowsPerPage;
    if (start >= _filteredDepartments.length) return [];
    final end = (start + _rowsPerPage).clamp(0, _filteredDepartments.length);
    return _filteredDepartments.sublist(start, end);
  }
}
