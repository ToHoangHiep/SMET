import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smet/model/user_model.dart';
import 'package:smet/service/common/user_service.dart';
import 'package:smet/service/common/global_notification_service.dart';
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
  final Color _primaryColor = const Color(0xFF137FEC);

  UserModel? _currentUser;
  Uint8List? _pickedAvatarBytes;
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers for profile form
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();

  // Controllers for password form
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await UserService.getProfile();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;

          _firstNameController.text = user.firstName;
          _lastNameController.text = user.lastName ?? '';
          _emailController.text = user.email;
          _phoneController.text = user.phone;
          _departmentController.text = user.department ?? '';
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      GlobalNotificationService.show(
        context: context,
        message: "Lỗi tải profile: $e",
        type: NotificationType.error,
      );
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    if (_firstNameController.text.isEmpty) {
      GlobalNotificationService.show(
        context: context,
        message: "Tên không được để trống",
        type: NotificationType.warning,
      );
      return;
    }

    final bool emailChanged = _emailController.text != _currentUser!.email;

    setState(() => _isSaving = true);

    try {
      final updatedUser = await UserService.updateProfile(
        firstName: _firstNameController.text,
        lastName:
            _lastNameController.text.isNotEmpty
                ? _lastNameController.text
                : null,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        email: _emailController.text,
      );

      setState(() {
        _currentUser = updatedUser;
        _isSaving = false;
      });

      if (emailChanged) {
        GlobalNotificationService.show(
          context: context,
          message: "Đã gửi email xác nhận đến \"${_emailController.text}\". Vui lòng kiểm tra hộp thư để xác nhận thay đổi.",
          type: NotificationType.success,
        );
      } else {
        GlobalNotificationService.show(
          context: context,
          message: "Cập nhật hồ sơ thành công!",
          type: NotificationType.success,
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      GlobalNotificationService.show(
        context: context,
        message: "Lỗi: $e",
        type: NotificationType.error,
      );
    }
  }

  void _handleCancel() {
    if (_currentUser != null) {
      _firstNameController.text = _currentUser!.firstName;
      _lastNameController.text = _currentUser!.lastName ?? '';
      _emailController.text = _currentUser!.email;
      _phoneController.text = _currentUser!.phone;
      _departmentController.text = _currentUser!.department ?? '';
    }
    GlobalNotificationService.show(
      context: context,
      message: "Đã hủy thay đổi",
      type: NotificationType.info,
    );
  }

  Future<void> _handleUpdatePassword() async {
    if (_oldPassController.text.isEmpty ||
        _newPassController.text.isEmpty ||
        _confirmPassController.text.isEmpty) {
      GlobalNotificationService.show(
        context: context,
        message: "Vui lòng nhập đầy đủ thông tin mật khẩu",
        type: NotificationType.warning,
      );
      return;
    }

    if (_newPassController.text != _confirmPassController.text) {
      GlobalNotificationService.show(
        context: context,
        message: "Mật khẩu xác nhận không khớp!",
        type: NotificationType.warning,
      );
      return;
    }

    if (_newPassController.text.length < 6) {
      GlobalNotificationService.show(
        context: context,
        message: "Mật khẩu mới phải có ít nhất 6 ký tự",
        type: NotificationType.warning,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await UserService.changePassword(
        oldPassword: _oldPassController.text,
        newPassword: _newPassController.text,
      );

      _oldPassController.clear();
      _newPassController.clear();
      _confirmPassController.clear();
      setState(() => _isSaving = false);
      GlobalNotificationService.show(
        context: context,
        message: "Đổi mật khẩu thành công!",
        type: NotificationType.success,
      );
    } catch (e) {
      setState(() => _isSaving = false);
      GlobalNotificationService.show(
        context: context,
        message: "Lỗi: ${e.toString().replaceAll('Exception: ', '')}",
        type: NotificationType.error,
      );
    }
  }

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
      setState(() => _pickedAvatarBytes = bytes);
      GlobalNotificationService.show(
        context: context,
        message: 'Đã chọn ảnh. Bấm "Lưu" để cập nhật.',
        type: NotificationType.success,
      );
    } catch (e) {
      GlobalNotificationService.show(
        context: context,
        message: 'Không thể chọn ảnh: $e',
        type: NotificationType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final Widget formContent = _buildFormContent();
    final avatarBytes = _pickedAvatarBytes;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Nếu là web hoặc desktop thì dựa vào chiều rộng màn hình
        if (kIsWeb || constraints.maxWidth > 900) {
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

  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileContactSection(
          firstNameController: _firstNameController,
          lastNameController: _lastNameController,
          emailController: _emailController,
          phoneController: _phoneController,
          departmentController: _departmentController,
          isSaving: _isSaving,
          primaryColor: _primaryColor,
          onCancel: _handleCancel,
          onSave: _handleSaveProfile,
          pendingEmail: _currentUser?.pendingEmail,
        ),
        const SizedBox(height: 24),
        ProfileSecuritySection(
          oldPassController: _oldPassController,
          newPassController: _newPassController,
          confirmPassController: _confirmPassController,
          primaryColor: _primaryColor,
          onUpdatePassword: _handleUpdatePassword,
          currentUser: _currentUser,
          on2FAStatusChanged: _loadUserProfile,
        ),
      ],
    );
  }
}
