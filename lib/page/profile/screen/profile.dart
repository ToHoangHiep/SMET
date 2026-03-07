import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smet/model/user_model.dart';
import 'package:smet/service/common/api_profile.dart';
import 'profile_web.dart';
import 'profile_mobile.dart';
import '../widgets/profile_contact_section.dart';
import '../widgets/profile_security_section.dart';

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
  /// Ảnh vừa chọn chưa lưu
  Uint8List? _pickedAvatarBytes;

  /// Ảnh đã lưu (khi backend trả avatarUrl == '__local__')
  Uint8List? _localAvatarBytes;

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
        Uint8List? localBytes;
        if (user.avatarUrl == '__local__') {
          localBytes = _apiProfile.getAvatarBytes();
        }
        setState(() {
          _currentUser = user;
          _isLoading = false;
          _localAvatarBytes = localBytes;

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

    try {
      // Nếu có ảnh mới chọn thì cập nhật avatar trước
      if (_pickedAvatarBytes != null) {
        await _apiProfile.updateAvatar(_pickedAvatarBytes!);
      }

      // Tạo object mới từ dữ liệu form
      final updatedUser = _currentUser!.copyWith(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phone: _phoneController.text,
      );
      await _apiProfile.updateUserProfile(updatedUser);

      if (mounted) {
        final newUser = await _apiProfile.getUserProfile();
        final newLocalBytes =
            newUser.avatarUrl == '__local__'
                ? _apiProfile.getAvatarBytes()
                : null;
        setState(() {
          _currentUser = newUser;
          _pickedAvatarBytes = null;
          _localAvatarBytes = newLocalBytes;
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
      setState(() => _pickedAvatarBytes = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đã hủy thay đổi")));
    }
  }

  // 5. Chọn ảnh đại diện (máy ảnh hoặc thư viện)
  Future<void> _pickAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder:
          (ctx) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Chọn từ thư viện'),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Chụp ảnh'),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
              ],
            ),
          ),
    );
    if (source == null || !mounted) return;

    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (xFile == null || !mounted) return;
      final bytes = await xFile.readAsBytes();
      if (mounted) {
        setState(() => _pickedAvatarBytes = bytes);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã chọn ảnh. Bấm "Lưu" để cập nhật.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể chọn ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

    final avatarBytes = _pickedAvatarBytes ?? _localAvatarBytes;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return ProfilePageWeb(
            formContent: formContent,
            currentUser: _currentUser,
            avatarBytes: avatarBytes,
            onAvatarTap: _pickAvatar,
          );
        } else {
          return ProfilePageMobile(
            formContent: formContent,
            currentUser: _currentUser,
            avatarBytes: avatarBytes,
            onAvatarTap: _pickAvatar,
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
        ProfileContactSection(
          firstNameController: _firstNameController,
          lastNameController: _lastNameController,
          emailController: _emailController,
          phoneController: _phoneController,
          isSaving: _isSaving,
          primaryColor: _primaryColor,
          onCancel: _handleCancel,
          onSave: _handleSaveProfile,
        ),
        const SizedBox(height: 24),
        ProfileSecuritySection(
          oldPassController: _oldPassController,
          newPassController: _newPassController,
          confirmPassController: _confirmPassController,
          primaryColor: _primaryColor,
          onUpdatePassword: _handleUpdatePassword,
        ),
      ],
    );
  }
}
