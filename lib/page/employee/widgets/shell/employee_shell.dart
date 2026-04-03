import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/user_model.dart';
import 'package:smet/page/sidebar/shared_sidebar.dart';
import 'package:smet/page/shared/widgets/app_toast.dart';
import 'package:smet/page/sidebar/sidebar_menu_item.dart';
import 'package:smet/service/common/auth_guard_service.dart';
import 'package:smet/service/common/auth_service.dart';

/// Employee Shell - Layout chung cho tất cả các màn hình employee
/// Sử dụng SharedSidebar dùng chung cho cả dự án
class EmployeeShell extends StatefulWidget {
  final Widget child;

  const EmployeeShell({super.key, required this.child});

  /// Employee color theme
  static const Color employeePrimaryColor = Color(0xFF137FEC);

  /// Menu items cho employee sidebar
  static List<SidebarMenuItem> get employeeMenuItems => [
    SidebarMenuItem(
      icon: Icons.dashboard_rounded,
      title: 'Trang chủ',
      route: '/employee/dashboard',
      tooltip: 'Trang chủ',
    ),
    SidebarMenuItem(
      icon: Icons.library_books_rounded,
      title: 'Khóa học của tôi',
      route: '/employee/my-courses',
      tooltip: 'Khóa học của tôi',
    ),
    SidebarMenuItem(
      icon: Icons.route_rounded,
      title: 'Lộ trình học tập',
      route: '/employee/my-learning-paths',
      tooltip: 'Lộ trình học tập',
    ),
    SidebarMenuItem(
      icon: Icons.explore_rounded,
      title: 'Danh mục',
      route: '/employee/courses',
      tooltip: 'Danh mục khóa học',
    ),
    SidebarMenuItem(
      icon: Icons.work_rounded,
      title: 'Dự án của tôi',
      route: '/employee/projects',
      tooltip: 'Dự án của tôi',
    ),
    SidebarMenuItem(
      icon: Icons.workspace_premium_rounded,
      title: 'Chứng chỉ',
      route: '/employee/certificates',
      tooltip: 'Chứng chỉ của tôi',
    ),
    SidebarMenuItem(
      icon: Icons.live_tv_rounded,
      title: 'Buổi học trực tuyến',
      route: '/employee/live-sessions',
      tooltip: 'Buổi học trực tuyến',
    ),
  ];

  @override
  State<EmployeeShell> createState() => _EmployeeShellState();
}

class _EmployeeShellState extends State<EmployeeShell> {
  String _userDisplayName = '';
  String _userRoleLabel = '';

  @override
  void initState() {
    super.initState();
    _loadUserForSidebar();
  }

  Future<void> _loadUserForSidebar() async {
    try {
      // Dùng getCurrentUser để vừa lấy user vừa cache
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
        _userRoleLabel = UserRole.USER.displayName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    // Safety net: nếu user đã cached nhưng role không phù hợp → redirect
    final cachedUser = AuthService.currentUserCached;
    if (cachedUser != null) {
      final targetRole = cachedUser.role;
      // Chặn USER (employee) vào các route không thuộc employee
      if (!AuthGuardService.canAccess('/employee', targetRole)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go(AuthGuardService.getRedirectPath(targetRole));
        });
        return const SizedBox.shrink();
      }
      // Chặn ADMIN/PM/MENTOR ở trong employee shell (đang navigate sang route khác namespace)
      if (targetRole != UserRole.USER && (location.startsWith('/admin') || location.startsWith('/pm') || location.startsWith('/mentor'))) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go(AuthGuardService.getRedirectPath(targetRole));
        });
        return const SizedBox.shrink();
      }
    }

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SharedSidebar(
            primaryColor: EmployeeShell.employeePrimaryColor,
            logoIcon: Icons.school,
            logoText: 'SMETS',
            subtitle: 'EMPLOYEE PORTAL',
            menuItems: EmployeeShell.employeeMenuItems,
            activeRoute: location,
            userDisplayName: _userDisplayName.isEmpty ? '…' : _userDisplayName,
            userRole: _userRoleLabel.isEmpty ? '…' : _userRoleLabel,
            onProfileTap: () => context.go('/profile'),
            onLogout: () async {
              await AuthService.logout();
              if (!mounted) return;
              context.showAppToast('Đăng xuất thành công!');
              context.go('/login');
            },
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
