import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/admin/user_management/widgets/shell/user_management_sidebar.dart';

class NotificationSidebar extends StatelessWidget {
  final Color primaryColor;
  final String userDisplayName;
  final VoidCallback onLogout;

  const NotificationSidebar({
    super.key,
    required this.primaryColor,
    required this.userDisplayName,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return UserManagementSidebar(
      primaryColor: primaryColor,
      userDisplayName: userDisplayName,
      onLogout: onLogout,
    );
  }
}
