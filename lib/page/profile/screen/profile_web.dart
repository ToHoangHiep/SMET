import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:smet/model/user_model.dart';
import '../widgets/profile_user_header.dart';
import '../widgets/web/profile_web_header.dart';
import '../widgets/web/profile_web_sidebar.dart';
import '../widgets/profile_user_avatar.dart';
import 'package:smet/page/profile/screen/profile.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePageWeb extends StatelessWidget {
  final Widget formContent;
  final UserModel? currentUser;
  final Uint8List? avatarBytes;
  final VoidCallback? onAvatarTap;

  const ProfilePageWeb({
    super.key,
    required this.formContent,
    this.currentUser,
    this.avatarBytes,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Navigation Bar
            ProfileWebHeader(currentUser: currentUser),

            // 2. Main Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 24,
                ),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 2.1 Sidebar (Left)
                        const ProfileWebSidebar(),

                        const SizedBox(width: 32),

                        // 2.2 Content (Right)
                        Expanded(
                          child: Column(
                            children: [
                              // Card hiển thị thông tin chung (Avatar, Tên)
                              _buildProfileHeaderCard(),

                              const SizedBox(height: 24),

                              // Form nhập liệu (Được truyền từ ProfileScreen)
                              formContent,
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard() {
    return ProfileUserHeader(
      currentUser: currentUser,
      variant: ProfileUserHeaderVariant.web,
      avatarBytes: avatarBytes,
      onAvatarTap: onAvatarTap,
    );
  }
}
