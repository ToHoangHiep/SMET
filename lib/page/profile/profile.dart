import 'package:flutter/material.dart';
import 'package:smet/model/user_model.dart';
import 'package:smet/service/common/api_profile.dart';
import 'profile_web.dart';
import 'profile_mobile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // --- SERVICE & STATE ---
  final ApiProfile _apiProfile = ApiProfile();

  UserModel? _currentUser;
  bool _isLoading = true; // Loading ban đầu
  bool _isSaving = false; // Loading khi ấn Save

  // Theme Color
  final Color _primaryColor = const Color(0xFF137FEC);

  // --- CONTROLLERS (PROFILE) ---
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // --- CONTROLLERS (PASSWORD) ---
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // ================= LOGIC XỬ LÝ =================

  // 1. Lấy dữ liệu từ API
  Future<void> _fetchProfileData() async {
    try {
      final user = await _apiProfile.getUserProfile();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;

          // Đổ dữ liệu vào Form
          _firstNameController.text = user.firstName;
          _lastNameController.text = user.lastName;
          _emailController.text = user.email;
          _phoneController.text = user.phone;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi tải dữ liệu: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 2. Lưu thông tin Profile
  Future<void> _handleSaveProfile() async {
    if (_currentUser == null) return;

    // Validate cơ bản
    if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tên không được để trống"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Tạo object mới từ dữ liệu form
    final updatedUser = _currentUser!.copyWith(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      phone: _phoneController.text,
    );

    try {
      await _apiProfile.updateUserProfile(updatedUser);

      if (mounted) {
        setState(() {
          _currentUser = updatedUser;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cập nhật hồ sơ thành công!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 3. Đổi mật khẩu
  Future<void> _handleUpdatePassword() async {
    // Validate khớp mật khẩu
    if (_newPassController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mật khẩu xác nhận không khớp!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_newPassController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng nhập mật khẩu mới"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _apiProfile.changePassword(
        _oldPassController.text,
        _newPassController.text,
      );

      if (mounted) {
        // Clear form mật khẩu sau khi thành công
        _oldPassController.clear();
        _newPassController.clear();
        _confirmPassController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đổi mật khẩu thành công!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi: ${e.toString().replaceAll('Exception: ', '')}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 4. Reset Form về dữ liệu gốc
  void _handleCancel() {
    if (_currentUser != null) {
      _firstNameController.text = _currentUser!.firstName;
      _lastNameController.text = _currentUser!.lastName;
      _emailController.text = _currentUser!.email;
      _phoneController.text = _currentUser!.phone;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đã hủy thay đổi")));
    }
  }

  // ================= GIAO DIỆN CHÍNH =================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Xây dựng Widget Form để truyền xuống View
    final Widget formContent = _buildFormContent();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          // Giao diện Web
          return ProfilePageWeb(
            formContent: formContent,
            currentUser: _currentUser,
          );
        } else {
          // Giao diện Mobile
          return ProfilePageMobile(
            formContent: formContent,
            currentUser: _currentUser,
          );
        }
      },
    );
  }

  // ================= XÂY DỰNG FORM CONTENT =================

  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- SECTION 1: CONTACT DETAILS ---
        _buildSectionCard(
          title: "Contact Details",
          subtitle: "Update your personal information and address.",
          child: Column(
            children: [
              // Hàng Tên (Responsive: Mobile dọc, Web ngang)
              LayoutBuilder(
                builder: (context, constraints) {
                  bool isWide = constraints.maxWidth > 500;
                  return Flex(
                    direction: isWide ? Axis.horizontal : Axis.vertical,
                    children: [
                      Expanded(
                        flex: isWide ? 1 : 0,
                        child: _buildTextField(
                          "First Name",
                          _firstNameController,
                        ),
                      ),
                      SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 16),
                      Expanded(
                        flex: isWide ? 1 : 0,
                        child: _buildTextField(
                          "Last Name",
                          _lastNameController,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              _buildTextField(
                "Email Address",
                _emailController,
                icon: Icons.mail_outline,
                readOnly: true,
              ), // Email thường không cho sửa
              const SizedBox(height: 16),
              _buildTextField(
                "Phone Number",
                _phoneController,
                icon: Icons.phone,
              ),
              const SizedBox(height: 16),

              const SizedBox(height: 24),

              // Nút Action (Cancel / Save)
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : _handleCancel,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _handleSaveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child:
                          _isSaving
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text("Save Changes"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // --- SECTION 2: SECURITY ---
        _buildSectionCard(
          title: "Security & Authentication",
          subtitle: "Manage your password and keep your account secure.",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Box Update Password
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 18,
                          color: Colors.grey[800],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Update Password",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Password Fields
                    LayoutBuilder(
                      builder: (context, constraints) {
                        bool isWide = constraints.maxWidth > 600;
                        return Flex(
                          direction: isWide ? Axis.horizontal : Axis.vertical,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: isWide ? 1 : 0,
                              child: _buildSmallTextField(
                                "Old Password",
                                _oldPassController,
                                obscure: true,
                              ),
                            ),
                            SizedBox(
                              width: isWide ? 16 : 0,
                              height: isWide ? 0 : 12,
                            ),
                            Expanded(
                              flex: isWide ? 1 : 0,
                              child: _buildSmallTextField(
                                "New Password",
                                _newPassController,
                                obscure: true,
                              ),
                            ),
                            SizedBox(
                              width: isWide ? 16 : 0,
                              height: isWide ? 0 : 12,
                            ),
                            Expanded(
                              flex: isWide ? 1 : 0,
                              child: _buildSmallTextField(
                                "Confirm Password",
                                _confirmPassController,
                                obscure: true,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: _handleUpdatePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("Update Password"),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Box 2FA (Static UI)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Two-Factor Authentication (2FA)",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Add an extra layer of security to your account.",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              "Currently Enabled",
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text("Configure"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= HELPER WIDGETS =================

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    IconData? icon,
    int maxLines = 1,
    bool readOnly = false,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon:
                icon != null
                    ? Icon(icon, color: Colors.grey[500], size: 20)
                    : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primaryColor, width: 1.2),
            ),
            filled: true,
            fillColor: readOnly ? Colors.grey[100] : Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallTextField(
    String label,
    TextEditingController controller, {
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _primaryColor, width: 1.1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
