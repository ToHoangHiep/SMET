import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/user_model.dart';
import 'package:smet/page/sidebar/shared_sidebar.dart';
import 'package:smet/page/sidebar/sidebar_menu_item.dart';
import 'package:smet/service/common/auth_guard_service.dart';
import 'package:smet/service/common/auth_service.dart';
import 'package:smet/service/common/global_notification_service.dart';

/// Pm Shell - Layout chung cho tất cả các màn hình PM
/// Sử dụng SharedSidebar dùng chung cho cả dự án
class PmShell extends StatefulWidget {
  final Widget child;

  const PmShell({super.key, required this.child});

  @override
  State<PmShell> createState() => _PmShellState();

  /// Menu items cho PM sidebar
  static List<SidebarMenuItem> get pmMenuItems => [
    SidebarMenuItem(
      icon: Icons.dashboard_rounded,
      title: 'Bảng điều khiển',
      route: '/pm/dashboard',
      tooltip: 'Bảng điều khiển',
    ),
    SidebarMenuItem(
      icon: Icons.folder_rounded,
      title: 'Dự án',
      route: '/pm/projects',
      tooltip: 'Dự án',
    ),
    SidebarMenuItem(
      icon: Icons.fact_check_rounded,
      title: 'Duyệt dự án',
      route: '/pm/project-reviews',
      tooltip: 'Duyệt dự án',
    ),
    SidebarMenuItem(
      icon: Icons.people_rounded,
      title: 'Thành viên',
      route: '/pm/project_members',
      tooltip: 'Thành viên',
    ),
    SidebarMenuItem(
      icon: Icons.trending_up_rounded,
      title: 'Tiến độ',
      route: '/pm/project_progress',
      tooltip: 'Tiến độ',
    ),
    SidebarMenuItem(
      icon: Icons.menu_book_rounded,
      title: 'Lộ trình học',
      route: '/pm/learning_path',
      tooltip: 'Lộ trình học',
    ),
    SidebarMenuItem(
      icon: Icons.description_rounded,
      title: 'Báo cáo',
      route: '/reports',
      tooltip: 'Báo cáo',
    ),
  ];

  /// PM color theme
  static const Color pmPrimaryColor = Color(0xFF137FEC);
}

class _PmShellState extends State<PmShell> {
  String _userDisplayName = '';
  String _userRoleLabel = '';

  @override
  void initState() {
    super.initState();
    _loadUserForSidebar();
  }

  Future<void> _loadUserForSidebar() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (!mounted) return;
      final name =
          user.fullName.trim().isNotEmpty ? user.fullName.trim() : user.email;
      setState(() {
        _userDisplayName = name;
        _userRoleLabel = user.role.displayName;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _userDisplayName = 'Người dùng';
        _userRoleLabel = 'Quản lý dự án';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safety net: nếu cached user là role không phù hợp → redirect
    final cachedUser = AuthService.currentUserCached;
    if (cachedUser != null && !AuthGuardService.canAccess('/pm', cachedUser.role)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(AuthGuardService.getRedirectPath(cachedUser.role));
      });
      return const SizedBox.shrink();
    }

    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SharedSidebar(
            primaryColor: PmShell.pmPrimaryColor,
            logoIcon: Icons.school,
            logoText: 'SMETS',
            subtitle: 'Quản lý dự án',
            menuItems: PmShell.pmMenuItems,
            activeRoute: location,
            userDisplayName: _userDisplayName.isEmpty ? '…' : _userDisplayName,
            userRole: _userRoleLabel.isEmpty ? '…' : _userRoleLabel,
            onProfileTap: () => context.go('/profile'),
            onLogout: () async {
              await AuthService.logout();
              if (!mounted) return;
              GlobalNotificationService.show(
                context: context,
                message: 'Đăng xuất thành công',
                type: NotificationType.success,
              );
              context.go('/login');
            },
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
