import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/user_model.dart';
import 'package:smet/page/shared/widgets/notification_bell_button.dart';
import 'package:smet/page/sidebar/shared_sidebar.dart';
import 'package:smet/page/sidebar/sidebar_menu_item.dart';
import 'package:smet/service/common/auth_guard_service.dart';
import 'package:smet/service/common/auth_service.dart';

/// AdminShell — Layout chung cho tất cả các màn hình admin
/// Bao gồm shell guard để đảm bảo chỉ ADMIN mới truy cập được
class AdminShell extends StatefulWidget {
  final Widget child;

  const AdminShell({
    super.key,
    required this.child,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  String _currentUserName = 'Admin';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final userData = await AuthService.getMe();
      if (!mounted) return;
      final name =
          '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
      if (name.isNotEmpty) {
        setState(() => _currentUserName = name);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Shell guard: chỉ ADMIN mới được ở trong admin shell
    final cachedUser = AuthService.currentUserCached;
    if (cachedUser != null) {
      if (cachedUser.role != UserRole.ADMIN) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go(AuthGuardService.getRedirectPath(cachedUser.role));
        });
        return const SizedBox.shrink();
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      body: Stack(
        children: [
          SafeArea(
            child: Row(
              children: [
                SharedSidebar(
                  primaryColor: const Color(0xFF6366F1),
                  logoIcon: Icons.school,
                  logoText: 'SMETS',
                  subtitle: 'Quản trị hệ thống',
                  userDisplayName: _currentUserName,
                  userRole: 'System Admin',
                  activeRoute: GoRouterState.of(context).uri.path,
                  onProfileTap: () => context.go('/profile'),
                  onLogout: () async {
                    await AuthService.logout();
                    if (!mounted) return;
                    context.go('/login');
                  },
                  menuItems: const [
                    SidebarMenuItem(
                      icon: Icons.dashboard_outlined,
                      title: 'Bảng điều khiển',
                      route: '/admin/dashboard',
                      tooltip: 'Bảng điều khiển',
                    ),
                    SidebarMenuItem(
                      icon: Icons.people_outline_rounded,
                      title: 'Quản lý nhân viên',
                      route: '/user_management',
                      tooltip: 'Quản lý nhân viên',
                    ),
                    SidebarMenuItem(
                      icon: Icons.apartment_outlined,
                      title: 'Quản lý phòng ban',
                      route: '/department_management',
                      tooltip: 'Quản lý phòng ban',
                    ),
                    SidebarMenuItem(
                      icon: Icons.assignment_ind_outlined,
                      title: 'Gán khóa học',
                      route: '/assignment_management',
                      tooltip: 'Gán khóa học',
                    ),
                    SidebarMenuItem(
                      icon: Icons.verified_outlined,
                      title: 'Phê duyệt khóa học',
                      route: '/course_approval',
                      tooltip: 'Phê duyệt khóa học',
                    ),
                    SidebarMenuItem(
                      icon: Icons.description_rounded,
                      title: 'Báo cáo',
                      route: '/admin/reports',
                      tooltip: 'Báo cáo',
                    ),
                  ],
                ),
                Expanded(child: widget.child),
              ],
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: NotificationBellButton(
              primaryColor: const Color(0xFF6366F1),
              onOpenPanel: () => context.go('/notifications'),
            ),
          ),
        ],
      ),
    );
  }
}
