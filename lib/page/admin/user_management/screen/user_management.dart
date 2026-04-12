import 'dart:developer';
import 'dart:html' as html; // For web file download
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:smet/model/user_model.dart';
import 'package:smet/model/department_model.dart';
import 'package:smet/service/admin/user_management/user_management_service.dart';
import 'package:smet/service/admin/department_management/api_department_management.dart';
import 'package:smet/service/common/global_notification_service.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import '../widgets/form/user_management_form_card.dart';
import '../widgets/shell/user_management_page_header.dart';
import '../widgets/shell/user_management_top_header.dart';
import '../widgets/table/user_management_table_card.dart';
import '../widgets/table/user_management_role_badge.dart';
import '../widgets/dialog/change_department_dialog.dart';
import '../widgets/dialog/reassignment_dialog.dart';
import 'package:flutter/foundation.dart';

int? _parsePaginationInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final UserManagementApi _apiService = UserManagementApi();
  final DepartmentService _departmentService = DepartmentService();

  String _searchQuery = '';
  String _selectedRole = 'ALL';
  bool? _selectedIsActive;
  int? _selectedDepartmentId;
  List<DepartmentModel> _departments = [];

  List<UserModel> _users = [];
  bool _isLoading = true;

  int _currentPage = 0;
  final int _rowsPerPage = 10;
  int _totalElements = 0;
  int _totalPages = 0;

  bool _isCreateMode = false;
  bool _isUpdateMode = false;
  bool _isViewMode = false;
  int? _editingUserId;
  UserModel? _viewingUser;
  final _createFormKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  UserRole _createRole = UserRole.USER;

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
    _fetchUsers();
  }

  Future<void> _fetchDepartments() async {
    try {
      final result = await _departmentService.searchDepartments(
        page: 0,
        size: 100,
      );
      if (mounted) {
        setState(() {
          _departments = result['departments'] as List<DepartmentModel>? ?? [];
        });
      }
    } catch (e) {
      log("Lỗi khi tải danh sách phòng ban: $e");
    }
  }

  final Color _primaryColor = const Color(0xFF6366F1); // Indigo như login
  final Color _bgLight = const Color(0xFFF3F6FC);

  final List<Map<String, String>> _roleOptions = const [
    {'value': 'ALL', 'label': 'Tất cả vai trò'},
    {'value': 'ADMIN', 'label': 'Quản trị viên'},
    {'value': 'PROJECT_MANAGER', 'label': 'Quản lý dự án'},
    {'value': 'MENTOR', 'label': 'Người hướng dẫn'},
    {'value': 'USER', 'label': 'Nhân viên'},
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers({bool resetPage = false}) async {
    if (resetPage) {
      _currentPage = 0;
    }
    setState(() => _isLoading = true);

    try {
      final result = await _apiService.getUsers(
        page: _currentPage,
        size: _rowsPerPage,
        keyword: _searchQuery.isNotEmpty ? _searchQuery : null,
        role: _selectedRole != 'ALL' ? _selectedRole : null,
        isActive: _selectedIsActive,
        departmentId: _selectedDepartmentId,
      );

      setState(() {
        _users = result['users'] as List<UserModel>;
        _totalElements = _parsePaginationInt(result['totalElements']) ?? 0;
        _totalPages = _parsePaginationInt(result['totalPages']) ?? 0;
        if (_totalPages > 0 && _currentPage >= _totalPages) {
          _currentPage = _totalPages - 1;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleImportExcel() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      allowMultiple: false,
    );

    if (result == null) {
      return;
    }

    final PlatformFile file = result.files.first;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _apiService.importExcelFile(file);

      if (mounted) {
        Navigator.pop(context);
        GlobalNotificationService.show(
          context: context,
          message: "Đã nhập file '${file.name}' thành công!",
          type: NotificationType.success,
        );

        _fetchUsers();
      }
    } catch (e) {
      Navigator.pop(context);
      GlobalNotificationService.show(
        context: context,
        message: 'Lỗi khi nhập file: $e',
        type: NotificationType.error,
      );
    }
  }

  Future<void> _handleDownloadTemplate() async {
    if (!mounted) return;
    final NavigatorState rootNav = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    var downloadOk = false;
    Object? caught;

    try {
      final res = await _apiService.downloadTemplate();
      if (!mounted) return;

      final bytes = res.bodyBytes;
      final blob = html.Blob(
        [bytes],
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      final url = html.Url.createObjectUrlFromBlob(blob);

      html.AnchorElement(href: url)
        ..setAttribute('download', 'user_import_template.xlsx')
        ..click();

      html.Url.revokeObjectUrl(url);
      downloadOk = true;
    } catch (e) {
      caught = e;
    } finally {
      // Dùng NavigatorState đã bắt trước showDialog — tránh ctx.mounted sai trên Web.
      // Không mở thông báo trước bước này (tránh 2 dialog chồng nhau làm pop lệch).
      rootNav.pop();
    }

    if (!mounted) return;
    if (downloadOk) {
      GlobalNotificationService.show(
        context: context,
        message: 'Đã tải template thành công!',
        type: NotificationType.success,
      );
    } else if (caught != null) {
      GlobalNotificationService.show(
        context: context,
        message: 'Lỗi khi tải template: $caught',
        type: NotificationType.error,
      );
    }
  }

  void _openCreateUserScreen() {
    setState(() {
      _isCreateMode = true;
      _isUpdateMode = false;
      _editingUserId = null;
      _firstNameController.clear();
      _lastNameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _createRole = UserRole.USER;
    });
  }

  void _openUpdateUserScreen(UserModel user) {
    // ADMIN không thể tự sửa chính mình — hệ thống chỉ có duy nhất 1 admin
    if (user.role == UserRole.ADMIN) {
      GlobalNotificationService.show(
        context: context,
        message: 'Không thể chỉnh sửa tài khoản Quản trị viên.',
        type: NotificationType.warning,
      );
      return;
    }

    setState(() {
      _isCreateMode = false;
      _isUpdateMode = true;
      _editingUserId = user.id;
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName ?? '';
      _emailController.text = user.email;
      _phoneController.text = user.phone;
      _createRole = user.role;
    });
  }

  void _closeCreateUserScreen() {
    setState(() {
      _isCreateMode = false;
      _isUpdateMode = false;
      _isViewMode = false;
      _editingUserId = null;
      _viewingUser = null;
    });
  }

  void _openViewUserScreen(UserModel user) {
    setState(() {
      _isViewMode = true;
      _isCreateMode = false;
      _isUpdateMode = false;
      _viewingUser = user;
    });
  }

  Future<void> _showChangeDepartmentDialog(UserModel user) async {
    if (user.role == UserRole.ADMIN) return;

    if (user.role == UserRole.MENTOR) {
      // Mentor: dùng ReassignmentDialog — chuyển khóa học trước khi đổi phòng ban
      await ReassignmentDialog.show(
        context: context,
        mentor: user,
        departments: _departments,
        primaryColor: _primaryColor,
        onComplete: () async {
          await _fetchUsers();
          if (context.mounted) {
            GlobalNotificationService.show(
              context: context,
              message: 'Đổi phòng ban thành công!',
              type: NotificationType.success,
            );
          }
        },
      );
      return;
    }

    // Role khác: dùng ChangeDepartmentDialog đơn giản
    await ChangeDepartmentDialog.show(
      context: context,
      user: user,
      departments: _departments,
      primaryColor: _primaryColor,
      onConfirm: (newDepartmentId, {bool confirmSwap = false}) async {
        try {
          await _apiService.updateUser(
            user,
            departmentId: newDepartmentId,
            confirmSwap: confirmSwap,
          );
          await _fetchUsers();
          return true;
        } catch (e) {
          if (context.mounted) {
            GlobalNotificationService.show(
              context: context,
              message: 'Đổi phòng ban thất bại: ${e.toString().replaceFirst('Exception: ', '')}',
              type: NotificationType.error,
            );
          }
          return false;
        }
      },
    );
  }

  Future<void> _submitCreateUser() async {
    if (!_createFormKey.currentState!.validate()) return;

    final newUser = UserModel(
      id: 0,
      userName: _emailController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      role: _createRole,
      mustChangePassword: true,
      lastUpdated: DateTime.now(),
    );

    await _apiService.createUser({
      "email": newUser.email,
      "firstName": newUser.firstName,
      "lastName": newUser.lastName,
      "phone": newUser.phone,
      "role": newUser.role.name.toUpperCase(),
    });
    await _fetchUsers();

    if (!mounted) return;

    setState(() {
      _isCreateMode = false;
      _currentPage = 1;
    });

    GlobalNotificationService.show(
      context: context,
      message: 'Tạo nhân viên thành công!',
      type: NotificationType.success,
    );
  }

  Future<void> _submitUpdateUser() async {
    if (!_createFormKey.currentState!.validate()) return;
    if (_editingUserId == null) return;

    final existingUser = _users.firstWhere((u) => u.id == _editingUserId!);

    final updatedUser = UserModel(
      id: _editingUserId!,
      userName: existingUser.userName,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      role: _createRole,
      mustChangePassword: existingUser.mustChangePassword,
      department: _departmentController.text.trim(),
      createdAt: existingUser.createdAt,
      lastUpdated: DateTime.now(),
      isActive: existingUser.isActive,
    );
    await _apiService.updateUser(
      updatedUser,
      departmentId: updatedUser.departmentId,
    );
    await _fetchUsers();

    if (!mounted) return;

    setState(() {
      _isUpdateMode = false;
      _editingUserId = null;
    });

    GlobalNotificationService.show(
      context: context,
      message: 'Cập nhật nhân viên thành công!',
      type: NotificationType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    // CHẶN MOBILE
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
          const UserManagementTopHeader(
                    breadcrumbs: [BreadcrumbItem(label: 'Quản lý nhân viên')],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UserManagementPageHeader(
                            primaryColor: _primaryColor,
                            onImportExcel: _handleImportExcel,
                            onDownloadTemplate: _handleDownloadTemplate,
                            onCreateUser: _openCreateUserScreen,
                          ),
                          const SizedBox(height: 20),
                          (_isCreateMode || _isUpdateMode)
                              ? UserManagementFormCard(
                                formKey: _createFormKey,
                                primaryColor: _primaryColor,
                                isUpdateMode: _isUpdateMode,
                                firstNameController: _firstNameController,
                                lastNameController: _lastNameController,
                                emailController: _emailController,
                                phoneController: _phoneController,
                                selectedRole: _createRole,
                                onRoleChanged: (role) {
                                  setState(() => _createRole = role);
                                },
                                onCancel: _closeCreateUserScreen,
                                onSubmit:
                                    _isUpdateMode
                                        ? _submitUpdateUser
                                        : _submitCreateUser,
                              )
                              : _isViewMode && _viewingUser != null
                              ? _buildViewUserCard()
                              : UserManagementTableCard(
                                primaryColor: _primaryColor,
                                paginatedUsers: _users,
                                filteredUsers: _users,
                                roleOptions: _roleOptions,
                                isLoading: _isLoading,
                                selectedRole: _selectedRole,
                                selectedIsActive: _selectedIsActive,
                                departments: _departments,
                                selectedDepartmentId: _selectedDepartmentId,
                                currentPage: _currentPage + 1,
                                rowsPerPage: _rowsPerPage,
                                totalElements: _totalElements,
                                onSearchChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                  _fetchUsers(resetPage: true);
                                },
                                onRoleChanged: (val) {
                                  setState(() {
                                    _selectedRole = val;
                                  });
                                  _fetchUsers(resetPage: true);
                                },
                                onIsActiveChanged: (val) {
                                  setState(() {
                                    _selectedIsActive = val;
                                  });
                                  _fetchUsers(resetPage: true);
                                },
                                onDepartmentChanged: (val) {
                                  setState(() {
                                    _selectedDepartmentId = val;
                                  });
                                  _fetchUsers(resetPage: true);
                                },
                                onPrevPage:
                                    _currentPage > 0
                                        ? () {
                                          setState(() {
                                            _currentPage--;
                                          });
                                          _fetchUsers();
                                        }
                                        : null,
                                onNextPage:
                                    _currentPage < _totalPages - 1
                                        ? () {
                                          setState(() {
                                            _currentPage++;
                                          });
                                          _fetchUsers();
                                        }
                                        : null,
                                onEditUser: _openUpdateUserScreen,
                                onViewUser: _openViewUserScreen,
                                onToggleActive: (user) async {
                                  await _apiService.toggleUserActive(user.id);
                                  await _fetchUsers();
                                },
                                onReassignDepartment: _showChangeDepartmentDialog,
                              ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildViewUserCard() {
    final user = _viewingUser!;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(user.id),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: SizedBox(
            width: 560,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildViewHeader(),
                const SizedBox(height: 32),
                Center(
                  child: Column(
                    children: [
                      _buildUserAvatar(),
                      const SizedBox(height: 20),
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      UserManagementRoleBadge(role: user.role),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildDetailCard('ID', user.id.toString(), Icons.tag, 0),
                _buildDetailCard(
                  'Tên nhân viên',
                  user.fullName,
                  Icons.person_outline,
                  1,
                ),
                _buildDetailCard(
                  'Vai trò',
                  _getRoleLabel(user.role),
                  Icons.badge_outlined,
                  2,
                ),
                _buildDetailCard(
                  'Số điện thoại',
                  user.phone.isNotEmpty ? user.phone : 'Chưa cập nhật',
                  Icons.phone_outlined,
                  3,
                ),
                _buildDetailCard('Email', user.email, Icons.email_outlined, 4),
                _buildDetailCard(
                  'Trạng thái',
                  user.isActive ? 'Hoạt động' : 'Không hoạt động',
                  user.isActive
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  5,
                  isStatus: true,
                  isActive: user.isActive,
                ),
                _buildDetailCard(
                  'Phòng ban',
                  user.department ?? 'Chưa phân công',
                  Icons.business_outlined,
                  6,
                ),
                _buildDetailCard(
                  'Ngày tạo',
                  _formatDate(user.createdAt ?? user.lastUpdated),
                  Icons.calendar_today_outlined,
                  7,
                ),
                _buildDetailCard(
                  'Cập nhật gần nhất',
                  _formatDate(user.lastUpdated),
                  Icons.update_outlined,
                  8,
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [_buildCloseButton()],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.person_outline_rounded,
            color: _primaryColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14),
              children: [
                TextSpan(
                  text: 'Quản lý nhân viên',
                  style: TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(
                  text: ' / Chi tiết nhân viên',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),
        _AnimatedCloseIcon(
          primaryColor: _primaryColor,
          onPressed: _closeCreateUserScreen,
        ),
      ],
    );
  }

  Widget _buildUserAvatar() {
    final user = _viewingUser!;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _primaryColor.withValues(alpha: 0.2),
            _primaryColor.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _primaryColor.withValues(alpha: 0.15),
              _primaryColor.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(
            color: _primaryColor.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            '${user.firstName.isNotEmpty ? user.firstName[0] : ''}'
            '${(user.lastName ?? '').isNotEmpty ? user.lastName![0] : ''}',
            style: TextStyle(
              color: _primaryColor,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(
    String label,
    String value,
    IconData icon,
    int index, {
    bool isStatus = false,
    bool isActive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300 + (index * 50)),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFFFAFBFC), const Color(0xFFF8FAFC)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    isStatus
                        ? (isActive
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFF3F4F6))
                        : _primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color:
                    isStatus
                        ? (isActive
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF9CA3AF))
                        : _primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color:
                          isStatus
                              ? (isActive
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF6B7280))
                              : const Color(0xFF111827),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

  Widget _buildCloseButton() {
    return _AnimatedButton(
      onPressed: _closeCreateUserScreen,
      label: 'Đóng',
      icon: Icons.close_rounded,
      primaryColor: _primaryColor,
    );
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.ADMIN:
        return 'Quản trị viên';
      case UserRole.PROJECT_MANAGER:
        return 'Quản lý dự án';
      case UserRole.MENTOR:
        return 'Người hướng dẫn';
      default:
        return 'Nhân viên';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _AnimatedCloseIcon extends StatefulWidget {
  final Color primaryColor;
  final VoidCallback onPressed;

  const _AnimatedCloseIcon({
    required this.primaryColor,
    required this.onPressed,
  });

  @override
  State<_AnimatedCloseIcon> createState() => _AnimatedCloseIconState();
}

class _AnimatedCloseIconState extends State<_AnimatedCloseIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFFFEF2F2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Icon(
            Icons.close_rounded,
            color: _isHovered ? const Color(0xFFEF4444) : Colors.grey[400],
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final Color primaryColor;

  const _AnimatedButton({
    required this.onPressed,
    required this.label,
    required this.icon,
    required this.primaryColor,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color:
                  _isHovered
                      ? widget.primaryColor.withValues(alpha: 0.1)
                      : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    _isHovered
                        ? widget.primaryColor.withValues(alpha: 0.5)
                        : const Color(0xFFD1D5DB),
              ),
            ),
            child: InkWell(
              onTap: widget.onPressed,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    size: 20,
                    color:
                        _isHovered
                            ? widget.primaryColor
                            : const Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.label.toUpperCase(),
                    style: TextStyle(
                      color:
                          _isHovered
                              ? widget.primaryColor
                              : const Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
