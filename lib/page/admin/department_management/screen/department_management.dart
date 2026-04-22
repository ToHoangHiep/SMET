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
import 'package:smet/service/common/global_notification_service.dart';
import 'dart:async';
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

class _DepartmentManagementPageState extends State<DepartmentManagementPage>
    with WidgetsBindingObserver {
  String username = "";

  final DepartmentService _departmentService = DepartmentService();
  List<DepartmentModel> _departments = [];
  bool _isLoading = true;

  String _codeQuery = '';
  String _managerQuery = '';
  String _statusFilter = 'Tất cả';

  int _currentPage = 1;
  final int _rowsPerPage = 5;
  int _totalDepartments = 0;
  Timer? _searchDebounce;

  final Map<int, bool> _departmentActiveMap = {};
  bool _isCreateMode = false;
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
    WidgetsBinding.instance.addObserver(this);
    _fetchDepartments();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchDebounce?.cancel();
    _createNameController.dispose();
    _createCodeController.dispose();
    _createManagerController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchDepartments();
    }
  }

  Future<void> _pickManager() async {
    List<user_model.UserModel> managers;
    try {
      managers = await fetchSelectableUsers(
        UserSelectionContext.departmentProjectManager,
      );
    } catch (e) {
      if (!mounted) return;
      GlobalNotificationService.show(
        context: context,
        message: 'Lỗi lấy danh sách người quản lý: $e',
        type: NotificationType.error,
      );
      return;
    }

    if (!mounted) return;

    final selected = await UserSelectionDialog.selectManager(
      context: context,
      primaryColor: _primaryColor,
      managers: managers,
      currentManager: _selectedManager,
      excludeDepartmentId: null,
      onSearch: (keyword) async {
        return await fetchSelectableUsers(
          UserSelectionContext.departmentProjectManager,
          keyword: keyword.isNotEmpty ? keyword : null,
        );
      },
    );

    setState(() {
      _selectedManager = selected;
    });
  }

  Future<void> _pickEmployees() async {
    List<user_model.UserModel> availableUsers;
    try {
      availableUsers = await fetchSelectableUsers(
        UserSelectionContext.departmentMembers,
        assigned: false,
      );
    } catch (e) {
      if (!mounted) return;
      GlobalNotificationService.show(
        context: context,
        message: 'Lỗi lấy danh sách thành viên: $e',
        type: NotificationType.error,
      );
      return;
    }

    if (!mounted) return;

    final result = await UserSelectionDialog.selectMembers(
      context: context,
      primaryColor: _primaryColor,
      members: availableUsers,
      preSelectedMembers: _selectedEmployees,
      excludeDepartmentId: null,
      onSearch: (keyword) async {
        return await fetchSelectableUsers(
          UserSelectionContext.departmentMembers,
          keyword: keyword.isNotEmpty ? keyword : null,
          assigned: false,
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

  Future<void> _fetchDepartments({String? keywordOverride}) async {
    _searchDebounce?.cancel();
    try {
      final keyword = keywordOverride ?? _codeQuery;
      final page = _currentPage - 1;

      final departmentResult = await _departmentService.searchDepartments(
        keyword: keyword.isNotEmpty ? keyword : null,
        active: _statusFilter == 'Đang hoạt động'
            ? true
            : _statusFilter == 'Tạm dừng'
                ? false
                : null,
        page: page,
        size: _rowsPerPage,
      );

      final departments =
          departmentResult['departments'] as List<DepartmentModel>;
      final totalElements = departmentResult['totalElements'] as int;

      setState(() {
        _departments = departments;
        _totalDepartments = totalElements;
        _departmentActiveMap
          ..clear()
          ..addEntries(departments.map((e) => MapEntry(e.id, e.isActive)));
        _isLoading = false;
      });

      log("DEPARTMENTS LOADED: ${_departments.length} / TOTAL: $_totalDepartments");
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
                                  _isCreateMode
                                      ?                                       DepartmentManagementFormCard(
                                        primaryColor: _primaryColor,
                                        formKey: _createFormKey,
                                        isUpdateMode: false,
                                        nameController: _createNameController,
                                        codeController: _createCodeController,
                                        selectedManager: _selectedManager,
                                        managerFallbackText:
                                            _createManagerController.text,
                                        isActive: _createIsActive,
                                        selectedEmployees: _selectedEmployees,
                                        onPickManager: _pickManager,
                                        onRemoveManager: () {
                                          setState(() {
                                            _selectedManager = null;
                                          });
                                        },
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
                                        onSubmit: _submitCreateDepartment,
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
                                          _searchDebounce?.cancel();
                                          _searchDebounce = Timer(
                                            const Duration(milliseconds: 400),
                                            () => _fetchDepartments(),
                                          );
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
                                          _fetchDepartments();
                                        },
                                        onToggleActive: (dept, value) async {
                                          try {
                                            await _departmentService
                                                .toggleDepartmentActive(dept.id);
                                            if (mounted) {
                                              setState(() {
                                                _departmentActiveMap[dept.id] =
                                                    value;
                                              });
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              GlobalNotificationService.show(
                                                context: context,
                                                message: 'Không thể thay đổi trạng thái: $e',
                                                type: NotificationType.error,
                                              );
                                              // Revert toggle
                                              setState(() {
                                                _departmentActiveMap[dept.id] =
                                                    !value;
                                              });
                                            }
                                          }
                                        },
                                        onDelete: _handleDeleteDepartment,
                                        onShowDetail:
                                            (dept) async {
                                          await context.push(
                                            '/department_management/${dept.id}',
                                          );
                                          _fetchDepartments();
                                        },
                                        onPrevPage:
                                            _currentPage > 1
                                                ? () {
                                                  setState(() {
                                                    _currentPage--;
                                                  });
                                                  _fetchDepartments();
                                                }
                                                : null,
                                        onNextPage:
                                            _currentPage * _rowsPerPage <
                                                    _totalDepartments
                                                ? () {
                                                  setState(() {
                                                    _currentPage++;
                                                  });
                                                  _fetchDepartments();
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

  void _openCreateDepartmentScreen() {
    setState(() {
      _isCreateMode = true;
      _createNameController.clear();
      _createCodeController.clear();
      _createManagerController.clear();
      _selectedManager = null;
      _createIsActive = true;
      _selectedEmployees.clear();
    });
  }

  void _closeCreateDepartmentScreen() {
    setState(() {
      _isCreateMode = false;
    });
  }

  Future<void> _submitCreateDepartment() async {
    if (!_createFormKey.currentState!.validate()) {
      return;
    }

    // Kiểm tra trùng mã phòng ban
    final code = _createCodeController.text.trim();
    final isCodeDuplicate = _departments.any(
      (d) => d.code.toLowerCase() == code.toLowerCase(),
    );
    if (isCodeDuplicate) {
      GlobalNotificationService.show(
        context: context,
        message: 'Mã phòng ban đã tồn tại',
        type: NotificationType.error,
      );
      return;
    }

    // Kiểm tra trùng tên phòng ban
    final name = _createNameController.text.trim();
    final isNameDuplicate = _departments.any(
      (d) => d.name.toLowerCase() == name.toLowerCase(),
    );
    if (isNameDuplicate) {
      GlobalNotificationService.show(
        context: context,
        message: 'Tên phòng ban đã tồn tại',
        type: NotificationType.error,
      );
      return;
    }

    // Lưu projectManagerId - cho phép null (không bắt buộc chọn PM)
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

    try {
      await _departmentService.createDepartment(
        name: name,
        code: code,
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

      GlobalNotificationService.show(
        context: context,
        message: 'Đã tạo bộ phận thành công',
        type: NotificationType.success,
      );
    } catch (e) {
      final msg = e.toString();

      if (msg.contains('User inactive')) {
        GlobalNotificationService.show(
          context: context,
          message: 'Một số thành viên đã bị vô hiệu hóa và không thể thêm',
          type: NotificationType.error,
        );
      } else if (msg.contains('User must be mentor')) {
        GlobalNotificationService.show(
          context: context,
          message: 'Một số thành viên không có vai trò Mentor',
          type: NotificationType.error,
        );
      } else if (msg.contains('is in active project')) {
        final regex = RegExp(r"User '([^']+)' \(([^)]+)\) is in active project: (.+)");
        final match = regex.firstMatch(msg);
        if (match != null) {
          final userName = match.group(1);
          final role = match.group(2);
          final projectTitle = match.group(3);
          GlobalNotificationService.show(
            context: context,
            message: '"$userName" ($role) đã ở trong project "$projectTitle"',
            type: NotificationType.warning,
          );
        } else {
          GlobalNotificationService.show(
            context: context,
            message: 'Thành viên đã ở trong project đang hoạt động',
            type: NotificationType.warning,
          );
        }
      } else if (msg.contains('User must be USER')) {
        GlobalNotificationService.show(
          context: context,
          message: 'Một số thành viên không có vai trò User',
          type: NotificationType.error,
        );
      } else if (msg.contains('Some users not found')) {
        GlobalNotificationService.show(
          context: context,
          message: 'Một số thành viên không tồn tại trong hệ thống',
          type: NotificationType.error,
        );
      } else if (msg.contains('Department already has a manager')) {
        GlobalNotificationService.show(
          context: context,
          message: 'Người quản lý này đã thuộc một phòng ban khác',
          type: NotificationType.error,
        );
      } else {
        final cleanMsg = msg.replaceAll('Exception: ', '');
        GlobalNotificationService.show(
          context: context,
          message: cleanMsg.length > 100 ? '${cleanMsg.substring(0, 100)}...' : cleanMsg,
          type: NotificationType.error,
        );
      }
    }
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
      GlobalNotificationService.show(
        context: context,
        message: message,
        type: NotificationType.success,
      );

      setState(() {
        _departments.removeWhere((dept) => dept.id == department.id);
      });
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      final displayMsg = errorMsg.length > 100
          ? '${errorMsg.substring(0, 100)}...'
          : errorMsg;
      GlobalNotificationService.show(
        context: context,
        message: displayMsg,
        type: NotificationType.error,
      );
    }
  }

  List<DepartmentModel> get _filteredDepartments {
    if (_managerQuery.trim().isEmpty) return _departments;
    return _departments.where((dept) {
      return dept.projectManagerName?.toLowerCase().contains(
            _managerQuery.toLowerCase().trim(),
          ) ??
          false;
    }).toList();
  }

  List<DepartmentModel> get _paginatedDepartments => _filteredDepartments;
}
