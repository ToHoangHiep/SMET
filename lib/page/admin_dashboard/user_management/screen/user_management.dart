import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/user_model.dart';
import 'package:smet/service/user_management/api_user_management.dart';
import '../widgets/form/user_management_form_card.dart';
import '../widgets/shell/user_management_page_header.dart';
import '../widgets/shell/user_management_sidebar.dart';
import '../widgets/shell/user_management_top_header.dart';
import '../widgets/table/user_management_table_card.dart';
import '../widgets/table/user_management_role_badge.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final ApiService _apiService = ApiService();

  String _searchQuery = '';
  String _selectedRole = 'ALL';

  List<UserModel> _users = [];
  bool _isLoading = true;

  int _currentPage = 1;
  final int _rowsPerPage = 5;

  bool _isCreateMode = false;
  bool _isUpdateMode = false;
  bool _isViewMode = false;
  String? _editingUserId;
  UserModel? _viewingUser;
  final _createFormKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  UserRole _createRole = UserRole.employee;

  final Color _primaryColor = const Color(0xFF137FEC);
  final Color _bgLight = const Color(0xFFF3F6FC);

  final List<Map<String, String>> _roleOptions = const [
    {'value': 'ALL', 'label': 'Tất cả vai trò'},
    {'value': 'ADMIN', 'label': 'Quản trị viên'},
    {'value': 'PM', 'label': 'Quản lý dự án'},
    {'value': 'MENTOR', 'label': 'Người hướng dẫn'},
    {'value': 'USER', 'label': 'Nhân viên'},
  ];

  List<UserModel> get _filteredUsers {
    return _users.where((user) {
      final nameLower = '${user.firstName} ${user.lastName}'.toLowerCase();
      final emailLower = user.email.toLowerCase();
      final queryLower = _searchQuery.toLowerCase();

      final matchesSearch =
          nameLower.contains(queryLower) || emailLower.contains(queryLower);

      final roleString = user.role.toString().split('.').last.toUpperCase();
      final matchesRole = _selectedRole == 'ALL' || roleString == _selectedRole;

      return matchesSearch && matchesRole;
    }).toList();
  }

  List<UserModel> get _paginatedUsers {
    final start = (_currentPage - 1) * _rowsPerPage;
    final end = start + _rowsPerPage;

    if (start >= _filteredUsers.length) return [];

    return _filteredUsers.sublist(
      start,
      end > _filteredUsers.length ? _filteredUsers.length : end,
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    final users = await _apiService.getUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
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
      final newUsers = await _apiService.importExcelFile();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Đã nhập file '${file.name}' thành công! Thêm ${newUsers.length} Nhân viên.",
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        _fetchUsers();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi nhập file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      _createRole = UserRole.employee;
    });
  }

  void _openUpdateUserScreen(UserModel user) {
    setState(() {
      _isCreateMode = false;
      _isUpdateMode = true;
      _editingUserId = user.id;
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
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

  Future<void> _submitCreateUser() async {
    if (!_createFormKey.currentState!.validate()) return;

    final newUser = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      role: _createRole,
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );

    await _apiService.createUser(newUser);
    await _fetchUsers();

    if (!mounted) return;

    setState(() {
      _isCreateMode = false;
      _currentPage = 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tạo nhân viên thành công!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _submitUpdateUser() async {
    if (!_createFormKey.currentState!.validate()) return;
    if (_editingUserId == null) return;

    final existingUser = _users.firstWhere((u) => u.id == _editingUserId!);

    final updatedUser = UserModel(
      id: _editingUserId!,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      role: _createRole,
      createdAt: existingUser.createdAt,
      lastUpdated: DateTime.now(),
    );

    await _apiService.updateUser(updatedUser);
    await _fetchUsers();

    if (!mounted) return;

    setState(() {
      _isUpdateMode = false;
      _editingUserId = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cập nhật nhân viên thành công!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      body: SafeArea(
        child: Row(
          children: [
            UserManagementSidebar(
              primaryColor: _primaryColor,
              userDisplayName:
                  _users.isNotEmpty ? _users.first.fullName : 'Nhân viên',
              onLogout: _handleLogout,
            ),
            Expanded(
              child: Column(
                children: [
                  const UserManagementTopHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UserManagementPageHeader(
                            primaryColor: _primaryColor,
                            onImportExcel: _handleImportExcel,
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
                                paginatedUsers: _paginatedUsers,
                                filteredUsers: _filteredUsers,
                                roleOptions: _roleOptions,
                                isLoading: _isLoading,
                                selectedRole: _selectedRole,
                                currentPage: _currentPage,
                                rowsPerPage: _rowsPerPage,
                                onSearchChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                    _currentPage = 1;
                                  });
                                },
                                onRoleChanged: (val) {
                                  setState(() {
                                    _selectedRole = val;
                                    _currentPage = 1;
                                  });
                                },
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
                                            _filteredUsers.length
                                        ? () {
                                          setState(() {
                                            _currentPage++;
                                          });
                                        }
                                        : null,
                                onEditUser: _openUpdateUserScreen,
                                onViewUser: _openViewUserScreen,
                                onToggleActive: (user) {
                                  setState(() {});
                                },
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

  Widget _buildViewUserCard() {
    final user = _viewingUser!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: SizedBox(
          width: 620,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
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
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _closeCreateUserScreen,
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: _primaryColor.withValues(alpha: 0.1),
                      child: Text(
                        '${user.firstName.isNotEmpty ? user.firstName[0] : ''}'
                        '${user.lastName.isNotEmpty ? user.lastName[0] : ''}',
                        style: TextStyle(
                          color: _primaryColor,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    UserManagementRoleBadge(role: user.role),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildDetailRow('Email', user.email),
              const SizedBox(height: 16),
              _buildDetailRow(
                'Ngày tạo',
                (user.createdAt ?? user.lastUpdated).toString().split(' ')[0],
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                'Cập nhật gần nhất',
                user.lastUpdated.toString().split(' ')[0],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _closeCreateUserScreen,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryColor,
                      side: BorderSide(color: _primaryColor),
                    ),
                    child: const Text('ĐÓNG'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    context.go('/login');
  }
}
