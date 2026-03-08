import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:smet/model/user_model.dart';
import 'profile_role_badge.dart';
import 'profile_user_avatar.dart';

enum ProfileUserHeaderVariant { web, mobile }

class ProfileUserHeader extends StatelessWidget {
  final UserModel? currentUser;
  final ProfileUserHeaderVariant variant;

  /// Ảnh đại diện dạng bytes (ảnh mới chọn hoặc ảnh đã lưu local)
  final Uint8List? avatarBytes;

  /// Bấm vào avatar để đổi ảnh
  final VoidCallback? onAvatarTap;

  const ProfileUserHeader({
    super.key,
    required this.currentUser,
    required this.variant,
    this.avatarBytes,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = variant == ProfileUserHeaderVariant.mobile;
    final role = currentUser?.role.name.toUpperCase() ?? "USER";

    return Container(
      width: isMobile ? double.infinity : null,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isMobile ? 0.02 : 0.03),
            blurRadius: isMobile ? 12 : 14,
            offset: Offset(0, isMobile ? 4 : 6),
          ),
        ],
      ),
      child: isMobile ? _buildMobileContent(role) : _buildWebContent(role),
    );
  }

  Widget _buildWebContent(String role) {
    return Row(
      children: [
        ProfileUserAvatar(
          avatarUrl: currentUser?.avatarUrl,
          avatarBytes: avatarBytes,
          onTap: onAvatarTap,
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentUser?.fullName ?? "Đang tải...",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                role,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ProfileRoleBadge(text: role),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileContent(String role) {
    return Column(
      children: [
        ProfileUserAvatar(
          avatarUrl: currentUser?.avatarUrl,
          avatarBytes: avatarBytes,
          onTap: onAvatarTap,
          size: 80,
          iconSize: 40,
          editIconSize: 14,
          editPadding: 4,
        ),
        const SizedBox(height: 12),
        Text(
          currentUser?.fullName ?? "Đang tải...",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(role, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            ProfileRoleBadge(
              text: role,
              fontSize: 11,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
          ],
        ),
      ],
    );
  }
}
