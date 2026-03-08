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
  String? _editingUserId;
  final _createFormKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
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
    _usernameController.dispose();
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
      _usernameController.clear();
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
      _usernameController.text = user.username;
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
      _editingUserId = null;
    });
  }

  Future<void> _submitCreateUser() async {
    if (!_createFormKey.currentState!.validate()) return;

    final newUser = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: _usernameController.text.trim(),
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
      username: _usernameController.text.trim(),
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
                                usernameController: _usernameController,
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

  void _handleLogout() {
    context.go('/login');
  }
}
