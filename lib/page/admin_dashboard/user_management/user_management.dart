import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/user_model.dart';
import 'package:smet/service/user_management/api_user_management.dart';

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
  int _rowsPerPage = 5;

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
            _buildSidebar(),
            Expanded(
              child: Column(
                children: [
                  _buildTopHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPageHeader(),
                          const SizedBox(height: 20),
                          (_isCreateMode || _isUpdateMode)
                              ? _buildCreateUserScreen()
                              : _buildUserTableCard(),
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

  Widget _buildSidebar() {
    return Container(
      width: 270,
      margin: const EdgeInsets.fromLTRB(12, 12, 0, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
                    color: _primaryColor,
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
                Text(
                  'Quản trị SMETS',
                  style: TextStyle(
                    color: _primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _sidebarItem(
            Icons.person,
            'Quản lý nhân viên',
            route: '/user_management',
            isActive: true,
          ),
          _sidebarItem(
            Icons.model_training,
            'Quản lý đào tạo',
            route: '/training_management',
          ),
          _sidebarItem(
            Icons.apartment,
            'Quản lý phòng ban',
            route: '/department_management',
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
            subtitle: Text(
              _users.isNotEmpty ? _users.first.fullName : 'Nhân viên',
              style: const TextStyle(fontSize: 12),
            ),
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
                ? Border(right: BorderSide(width: 4, color: _primaryColor))
                : null,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: isActive ? _primaryColor : Colors.grey[600]),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? _primaryColor : Colors.grey[700],
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

  Widget _buildTopHeader() {
    return Container(
      height: 76,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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

  Widget _buildPageHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 14,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quản lý nhân viên',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Quản lý toàn bộ nhân viên và quyền truy cập hệ thống.',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: _handleImportExcel,
                icon: const Icon(Icons.upload_file),
                label: const Text('Nhập tệp Excel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _openCreateUserScreen,
                icon: const Icon(Icons.add),
                label: const Text('Tạo nhân viên mới'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreateUserScreen() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Form(
        key: _createFormKey,
        child: Center(
          child: SizedBox(
            width: 620,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      TextSpan(
                        text:
                            _isUpdateMode
                                ? ' / Cập nhật nhân viên'
                                : ' / Tạo nhân viên mới',
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: '* Tên đăng nhập',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên đăng nhập';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: '* Tên',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nhập tên';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: '* Họ',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nhập họ';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: '* Email',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<UserRole>(
                        value: _createRole,
                        decoration: const InputDecoration(
                          labelText: 'Vai trò',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: UserRole.admin,
                            child: Text('Quản trị viên'),
                          ),
                          DropdownMenuItem(
                            value: UserRole.projectManager,
                            child: Text('Quản lý dự án'),
                          ),
                          DropdownMenuItem(
                            value: UserRole.mentor,
                            child: Text('Người hướng dẫn'),
                          ),
                          DropdownMenuItem(
                            value: UserRole.employee,
                            child: Text('Nhân viên'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _createRole = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _closeCreateUserScreen,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryColor,
                        side: BorderSide(color: _primaryColor),
                      ),
                      child: const Text('HỦY'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed:
                          _isUpdateMode ? _submitUpdateUser : _submitCreateUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_isUpdateMode ? 'CẬP NHẬT' : 'XÁC NHẬN'),
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

  Widget _buildUserTableCard() {
    final total = _filteredUsers.length;

    final start = total == 0 ? 0 : (_currentPage - 1) * _rowsPerPage + 1;

    final end =
        total == 0
            ? 0
            : (_currentPage * _rowsPerPage > total
                ? total
                : _currentPage * _rowsPerPage);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: 280,
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _currentPage = 1;
                      });
                    },
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Tìm theo tên hoặc email...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 210,
                  child: DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 15,
                      ),
                    ),
                    items:
                        _roleOptions
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item['value'],
                                child: Text(item['label']!),
                              ),
                            )
                            .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() {
                        _selectedRole = val;
                        _currentPage = 1;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 50,
                dataRowMinHeight: 64,
                dataRowMaxHeight: 72,
                horizontalMargin: 20,
                columnSpacing: 28,
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF9FAFB),
                ),
                columns: const [
                  DataColumn(
                    label: Text(
                      'NHÂN VIÊN',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'VAI TRÒ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'HOẠT ĐỘNG',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'NGÀY TẠO',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'CẬP NHẬT GẦN NHẤT',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  DataColumn(label: Text(''), numeric: true),
                ],
                rows:
                    _paginatedUsers.map((user) => _buildDataRow(user)).toList(),
              ),
            ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hiển thị $start - $end trong số ${_filteredUsers.length} kết quả',
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
                          _currentPage * _rowsPerPage < _filteredUsers.length
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
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(UserModel user) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              CircleAvatar(
                backgroundColor: _primaryColor.withValues(alpha: 0.1),
                child: Text(
                  '${user.firstName.isNotEmpty ? user.firstName[0] : ''}'
                  '${user.lastName.isNotEmpty ? user.lastName[0] : ''}',
                  style: TextStyle(
                    color: _primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF111827),
                    ),
                  ),
                  Text(
                    user.email,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        DataCell(_buildRoleBadge(user.role)),
        DataCell(
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: user.isActive,
              activeColor: _primaryColor,
              onChanged: (val) {
                setState(() => user.isActive = val);
              },
            ),
          ),
        ),
        DataCell(
          Text(
            (user.createdAt ?? user.lastUpdated).toString().split(' ')[0],
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          ),
        ),
        DataCell(
          Text(
            user.lastUpdated.toString().split(' ')[0],
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          ),
        ),
        DataCell(
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                onPressed: () => _openUpdateUserScreen(user),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(UserRole role) {
    Color bg;
    Color text;
    String label;

    switch (role) {
      case UserRole.admin:
        bg = const Color(0xFFF3E8FF);
        text = const Color(0xFF6B21A8);
        label = 'QUẢN TRỊ';
        break;
      case UserRole.projectManager:
        bg = const Color(0xFFDBEAFE);
        text = const Color(0xFF1E40AF);
        label = 'QUẢN LÝ DỰ ÁN';
        break;
      case UserRole.mentor:
        bg = const Color(0xFFDCFCE7);
        text = const Color(0xFF166534);
        label = 'HƯỚNG DẪN';
        break;
      default:
        bg = const Color(0xFFF3F4F6);
        text = const Color(0xFF374151);
        label = 'NHÂN VIÊN';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
