import 'package:flutter/material.dart';
import 'profile_section_card.dart';
import 'profile_small_text_field.dart';

class ProfileSecuritySection extends StatelessWidget {
  final TextEditingController oldPassController;
  final TextEditingController newPassController;
  final TextEditingController confirmPassController;
  final Color primaryColor;
  final VoidCallback onUpdatePassword;

  const ProfileSecuritySection({
    super.key,
    required this.oldPassController,
    required this.newPassController,
    required this.confirmPassController,
    required this.primaryColor,
    required this.onUpdatePassword,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileSectionCard(
      title: "Bảo mật & Xác thực",
      subtitle: "Quản lý mật khẩu và giữ tài khoản của bạn an toàn.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shield_outlined, color: Colors.green),
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
                      "Thêm một lớp bảo mật bổ sung cho tài khoản của bạn.",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
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
                          "Hiện đang bật",
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
              OutlinedButton(onPressed: () {}, child: const Text("Cấu hình")),
            ],
          ),
        ],
      ),
    );
  }
}
