import 'package:flutter/material.dart';
import 'profile_section_card.dart';
import 'profile_text_field.dart';

class ProfileContactSection extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final bool isSaving;
  final Color primaryColor;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const ProfileContactSection({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.phoneController,
    required this.isSaving,
    required this.primaryColor,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileSectionCard(
      title: "Thông tin liên hệ",
      subtitle: "Cập nhật thông tin cá nhân và địa chỉ của bạn.",
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 500;
              return Flex(
                direction: isWide ? Axis.horizontal : Axis.vertical,
                children: [
                  Expanded(
                    flex: isWide ? 1 : 0,
                    child: ProfileTextField(
                      label: "Tên",
                      controller: firstNameController,
                      primaryColor: primaryColor,
                    ),
                  ),
                  SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 16),
                  Expanded(
                    flex: isWide ? 1 : 0,
                    child: ProfileTextField(
                      label: "Họ",
                      controller: lastNameController,
                      primaryColor: primaryColor,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          ProfileTextField(
            label: "Địa chỉ email",
            controller: emailController,
            icon: Icons.mail_outline,
            readOnly: true,
            primaryColor: primaryColor,
          ),
          const SizedBox(height: 16),
          ProfileTextField(
            label: "Số điện thoại",
            controller: phoneController,
            icon: Icons.phone,
            primaryColor: primaryColor,
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.end,
              children: [
                TextButton(
                  onPressed: isSaving ? null : onCancel,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  child: const Text(
                    "Hủy",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
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
                      isSaving
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text("Lưu thay đổi"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
