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

  void _showCreateUserDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return _CreateUserDialog(
          primaryColor: _primaryColor,
          onSave: (newUser) async {
            await _apiService.createUser(newUser);
            _fetchUsers();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tạo nhân viên thành công!')),
              );
            }
          },
        );
      },
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
                          _buildUserTableCard(),
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
          _sidebarItem(Icons.person, 'Quản lý nhân viên', isActive: true),
          _sidebarItem(Icons.model_training, 'Quản lý đào tạo'),
          _sidebarItem(Icons.apartment, 'Quản lý phòng ban'),
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

  Widget _sidebarItem(IconData icon, String title, {bool isActive = false}) {
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
        onTap: () {},
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
                onPressed: _showCreateUserDialog,
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
                      'TRẠNG THÁI',
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
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.grey),
                onPressed: () {},
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

class _CreateUserDialog extends StatefulWidget {
  final Color primaryColor;
  final Function(UserModel) onSave;

  const _CreateUserDialog({required this.primaryColor, required this.onSave});

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();

  String _username = '';
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _phone = '';
  UserRole _role = UserRole.employee;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text(
        'Tạo nhân viên mới',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  'Tên đăng nhập',
                  (v) => _username = v!,
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'Tên',
                        (v) => _firstName = v!,
                        icon: Icons.badge_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField('Họ', (v) => _lastName = v!),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  'Địa chỉ email',
                  (v) => _email = v!,
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  'Số điện thoại',
                  (v) => _phone = v!,
                  icon: Icons.phone_android,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<UserRole>(
                  value: _role,
                  decoration: InputDecoration(
                    labelText: 'Vai trò',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    prefixIcon: const Icon(Icons.security, size: 20),
                  ),
                  items:
                      UserRole.values.map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(_getRoleNameVi(role)),
                        );
                      }).toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() => _role = val);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: Colors.grey),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Tạo nhân viên'),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    Function(String?) onSave, {
    IconData? icon,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
        prefixIcon:
            icon != null ? Icon(icon, size: 20, color: Colors.grey) : null,
      ),
      validator: (value) => value == null || value.isEmpty ? 'Bắt buộc' : null,
      onSaved: onSave,
    );
  }

  String _getRoleNameVi(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Quản trị viên';
      case UserRole.projectManager:
        return 'Quản lý dự án';
      case UserRole.mentor:
        return 'Người hướng dẫn';
      default:
        return 'Nhân viên';
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newUser = UserModel(
        id: DateTime.now().toString(),
        username: _username,
        firstName: _firstName,
        lastName: _lastName,
        email: _email,
        phone: _phone,
        role: _role,
        lastUpdated: DateTime.now(),
      );

      widget.onSave(newUser);
      Navigator.pop(context);
    }
  }
}
