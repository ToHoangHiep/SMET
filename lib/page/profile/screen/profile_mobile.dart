import 'package:flutter/material.dart';
import 'package:smet/model/user_model.dart';
import '../widgets/mobile/profile_mobile_app_bar.dart';
import '../widgets/profile_user_header.dart';

class ProfilePageMobile extends StatelessWidget {
  final Widget formContent;
  final UserModel? currentUser;

  const ProfilePageMobile({
    super.key,
    required this.formContent,
    this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: const ProfileMobileAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            children: [
              // 1. Profile Header (Card dọc)
              _buildMobileProfileHeader(),

              const SizedBox(height: 20),

              // 2. Form Content (Được truyền vào)
              formContent,

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileProfileHeader() {
    return ProfileUserHeader(
      currentUser: currentUser,
      variant: ProfileUserHeaderVariant.mobile,
    );
  }
}
