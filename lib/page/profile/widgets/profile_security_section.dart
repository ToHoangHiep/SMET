import 'package:flutter/material.dart';
import 'package:smet/model/user_model.dart';
import 'package:smet/page/profile/widgets/two_factor_setup_dialog.dart';
import 'package:smet/service/common/two_factor_service.dart';
import 'profile_section_card.dart';
import 'profile_small_text_field.dart';

class ProfileSecuritySection extends StatelessWidget {
  final TextEditingController oldPassController;
  final TextEditingController newPassController;
  final TextEditingController confirmPassController;
  final Color primaryColor;
  final VoidCallback onUpdatePassword;
  final UserModel? currentUser;
  final VoidCallback? on2FAStatusChanged;

  const ProfileSecuritySection({
    super.key,
    required this.oldPassController,
    required this.newPassController,
    required this.confirmPassController,
    required this.primaryColor,
    required this.onUpdatePassword,
    this.currentUser,
    this.on2FAStatusChanged,
  });

  Future<void> _onToggle2FA(BuildContext context) async {
    final isCurrentlyEnabled = currentUser?.isTwoFactorEnabled ?? false;

    // If currently enabled, ask for confirmation to disable
    if (isCurrentlyEnabled) {
      final shouldDisable = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Tắt xác thực hai yếu tố?"),
          content: const Text(
            "Sau khi tắt, tài khoản của bạn sẽ chỉ được bảo mật bằng mật khẩu. "
            "Bạn có chắc chắn muốn tắt không?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Tắt 2FA"),
            ),
          ],
        ),
      );

      if (shouldDisable != true) return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final result = await TwoFactorService.toggle2FA();

      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();

      if (result.needsSetup && result.qrCode != null) {
        // Show QR code setup dialog
        final success = await TwoFactorSetupDialog.show(
          context: context,
          qrCodeBase64: result.qrCode!,
        );

        if (success == true && context.mounted) {
          on2FAStatusChanged?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Đã bật xác thực hai yếu tố!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (result.twoFactorEnabled == false && !result.needsSetup) {
        // 2FA was disabled
        if (context.mounted) {
          on2FAStatusChanged?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Đã tắt xác thực hai yếu tố."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog first
      if (context.mounted) Navigator.of(context).pop();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi: ${e.toString().replaceAll('Exception: ', '')}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final is2FAEnabled = currentUser?.isTwoFactorEnabled ?? false;

    return ProfileSectionCard(
      title: "Bảo mật & Xác thực",
      subtitle: "Quản lý mật khẩu và giữ tài khoản của bạn an toàn.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Password Update Section
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
                    Icon(Icons.lock_outline, size: 18, color: Colors.grey[800]),
                    const SizedBox(width: 8),
                    Text(
                      "Cập nhật mật khẩu",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 600;
                    return Flex(
                      direction: isWide ? Axis.horizontal : Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: isWide ? 1 : 0,
                          child: ProfileSmallTextField(
                            label: "Mật khẩu cũ",
                            controller: oldPassController,
                            obscure: true,
                            primaryColor: primaryColor,
                          ),
                        ),
                        SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 12),
                        Expanded(
                          flex: isWide ? 1 : 0,
                          child: ProfileSmallTextField(
                            label: "Mật khẩu mới",
                            controller: newPassController,
                            obscure: true,
                            primaryColor: primaryColor,
                          ),
                        ),
                        SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 12),
                        Expanded(
                          flex: isWide ? 1 : 0,
                          child: ProfileSmallTextField(
                            label: "Xác nhận mật khẩu",
                            controller: confirmPassController,
                            obscure: true,
                            primaryColor: primaryColor,
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
                    onPressed: onUpdatePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
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
          // 2FA Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: is2FAEnabled ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  is2FAEnabled ? Icons.shield_outlined : Icons.shield_outlined,
                  color: is2FAEnabled ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Xác thực hai yếu tố (2FA)",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Thêm một lớp bảo mật bổ sung cho tài khoản của bạn bằng Google Authenticator.",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: is2FAEnabled ? Colors.green : Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          is2FAEnabled ? "Hiện đang bật" : "Hiện đang tắt",
                          style: TextStyle(
                            color: is2FAEnabled ? Colors.green : Colors.orange,
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
                onPressed: () => _onToggle2FA(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: is2FAEnabled ? Colors.red : primaryColor,
                  side: BorderSide(
                    color: is2FAEnabled ? Colors.red : primaryColor,
                  ),
                ),
                child: Text(is2FAEnabled ? "Tắt" : "Bật"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
