import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/user_model.dart';
import 'package:smet/service/admin/user_management/api_user_management.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  // Service
  final ApiService _apiService = ApiService();
  String _searchQuery = ''; // Lưu từ khóa tìm kiếm
  String _selectedRole = 'All Roles'; // Lưu role đang chọn lọc

  // State Variables
  List<UserModel> _users = [];
  bool _isLoading = true;

  // Hàm này sẽ tự động chạy lại mỗi khi giao diện được vẽ lại (setState)
  List<UserModel> get _filteredUsers {
    return _users.where((user) {
      // 1. Logic tìm kiếm (Search)
      // Chuyển hết về chữ thường (lowercase) để tìm không phân biệt hoa thường
      final nameLower = "${user.firstName} ${user.lastName}".toLowerCase();
      final emailLower = user.email.toLowerCase();
      final queryLower = _searchQuery.toLowerCase();

      // 2. Logic so sánh
      final matchesSearch =
          nameLower.contains(queryLower) || emailLower.contains(queryLower);

      final roleString = user.role.toString().split('.').last.toUpperCase();

      final matchesRole =
          _selectedRole == 'All Roles' || roleString == _selectedRole;

      return matchesSearch && matchesRole;
    }).toList();
  }

  // Theme Colors
  final Color _primaryColor = const Color(0xFF137FEC);
  final Color _bgLight = const Color(0xFFF3F6FC);

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

  // --- Logic Import Excel (Đã sửa đổi) ---
  Future<void> _handleImportExcel() async {
    // 1. Mở cửa sổ chọn file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'], // Chỉ cho phép file Excel
      allowMultiple: false,
    );

    // 2. Kiểm tra xem người dùng có chọn file hay không
    if (result != null) {
      // Lấy file đã chọn (trên Web là bytes, trên Mobile/Desktop là path)
      PlatformFile file = result.files.first;

      // Hiển thị loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // Giả lập gửi file lên server hoặc xử lý file
        // Bạn có thể truy cập file.bytes (Web) hoặc file.path (Mobile) tại đây
        print("Đang xử lý file: ${file.name} (Kích thước: ${file.size} bytes)");

        // Gọi service mock import (giả lập việc đọc file mất 2 giây)
        final newUsers = await _apiService.importExcelFile();

        if (mounted) {
          Navigator.pop(context); // Đóng loading dialog

          // Hiển thị thông báo thành công
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Đã import file '${file.name}' thành công! Thêm ${newUsers.length} users.",
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          _fetchUsers(); // Reload lại bảng dữ liệu
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Đóng loading dialog nếu lỗi
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Lỗi khi import: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Người dùng hủy chọn file (bấm Cancel)
      // Không làm gì cả hoặc hiện thông báo nhỏ
      print("Người dùng đã hủy chọn file.");
    }
  }

  // --- Logic Create User Dialog ---
  void _showCreateUserDialog() {
    showDialog(
      context: context,
      builder:
          (context) => _CreateUserDialog(
            primaryColor: _primaryColor,
            onSave: (newUser) async {
              // Gọi API save
              await _apiService.createUser(newUser);
              // Reload UI
              _fetchUsers();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Tạo User thành công!")),
                );
              }
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      body: Row(
        children: [
          // 1. Sidebar (Định nghĩa trực tiếp tại đây)
          _buildSidebar(),

          // 2. Main Content
          Expanded(
            child: Column(
              children: [
                _buildTopHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPageHeader(),
                        const SizedBox(height: 24),
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
    );
  }

  // --- UI Components ---

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      "S",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "SMETS Admin",
                  style: TextStyle(
                    color: _primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _sidebarItem(Icons.person, "User Management", isActive: true),
          _sidebarItem(Icons.model_training, "Training Management"),
          _sidebarItem(Icons.apartment, "Department Management"),
          const Spacer(),
          const Divider(),
          const ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              "Admin User",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            subtitle: Text("Super Admin", style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String title, {bool isActive = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFEBF5FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border:
            isActive
                ? Border(right: BorderSide(width: 4, color: _primaryColor))
                : null,
      ),
      child: ListTile(
        leading: Icon(icon, color: isActive ? _primaryColor : Colors.grey[600]),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? _primaryColor : Colors.grey[600],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        onTap: () {},
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Spacer(), // Dùng Spacer để đẩy icon chuông sang phải
          // Notification Icon
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "User Management",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Manage all users and their system access.",
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _handleImportExcel,
              icon: const Icon(Icons.upload_file),
              label: const Text("Import Excel"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                foregroundColor: Colors.grey[700],
                side: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _showCreateUserDialog,
              icon: const Icon(Icons.add),
              label: const Text("Create New User"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserTableCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          // Table Filters (Search + Role Dropdown)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                SizedBox(
                  width: 250,
                  child: TextField(
                    // Cập nhật biến _searchQuery khi gõ
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search by name or email...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 15,
                      ),
                    ),
                    // Gán giá trị đang chọn
                    value: _selectedRole,
                    items:
                        [
                              'All Roles',
                              'ADMIN',
                              'PM',
                              'MENTOR',
                              'USER',
                            ] // Đảm bảo khớp với data
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    // Cập nhật biến _selectedRole khi chọn
                    onChanged: (val) {
                      setState(() {
                        _selectedRole = val!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Table Data
          _isLoading
              ? const Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              )
              : SizedBox(
                width: double.infinity,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFFF9FAFB),
                  ),
                  columns: const [
                    DataColumn(
                      label: Text(
                        "USER",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "ROLE",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "STATUS",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "LAST UPDATED",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(label: Text(""), numeric: true),
                  ],
                  rows:
                      _filteredUsers
                          .map((user) => _buildDataRow(user))
                          .toList(),
                ),
              ),
          // Pagination (Fake UI)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Showing 1 to ${_users.length} of ${_users.length} results",
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text("Previous"),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(onPressed: () {}, child: const Text("Next")),
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
    String firstInitial = user.firstName.isNotEmpty ? user.firstName[0] : '';
    String lastInitial = user.lastName.isNotEmpty ? user.lastName[0] : '';
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
    String label = role.name.toUpperCase();

    switch (role) {
      case UserRole.admin:
        bg = const Color(0xFFF3E8FF); // Purple 100
        text = const Color(0xFF6B21A8); // Purple 800
        break;
      case UserRole.projectManager:
        bg = const Color(0xFFDBEAFE); // Blue 100
        text = const Color(0xFF1E40AF); // Blue 800
        break;
      case UserRole.mentor:
        bg = const Color(0xFFDCFCE7); // Green 100
        text = const Color(0xFF166534); // Green 800
        break;
      default:
        bg = const Color(0xFFF3F4F6); // Gray 100
        text = const Color(0xFF374151); // Gray 800
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
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

// --- CLASS RIÊNG CHO DIALOG CREATE USER (Để clean code) ---
class _CreateUserDialog extends StatefulWidget {
  final Color primaryColor;
  final Function(UserModel) onSave;

  const _CreateUserDialog({required this.primaryColor, required this.onSave});

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();

  // Form Fields
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
        "Create New User",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 500, // Độ rộng cố định cho Dialog
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  "Username",
                  (v) => _username = v!,
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        "First Name",
                        (v) => _firstName = v!,
                        icon: Icons.badge_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        "Last Name",
                        (v) => _lastName = v!,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  "Email Address",
                  (v) => _email = v!,
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  "Phone Number",
                  (v) => _phone = v!,
                  icon: Icons.phone_android,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<UserRole>(
                  value: _role,
                  decoration: InputDecoration(
                    labelText: "Role",
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
                          child: Text(role.name.toUpperCase()),
                        );
                      }).toList(),
                  onChanged: (val) => setState(() => _role = val!),
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
          child: const Text("Cancel"),
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
          child: const Text("Create User"),
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
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      onSaved: onSave,
    );
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
