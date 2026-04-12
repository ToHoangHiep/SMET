import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/user_model.dart';
import 'package:smet/page/sidebar/sidebar_menu_item.dart';
import 'package:smet/page/sidebar/shared_sidebar.dart';
import 'package:smet/service/common/auth_guard_service.dart';
import 'package:smet/service/common/auth_service.dart';

// ================================================================
// UNIFIED REPORT SHELL
// Dynamically renders the correct sidebar + layout based on user role.
// Used by all report screens (list, detail, edit, version).
// ================================================================

class ReportShell extends StatefulWidget {
  final Widget child;
  final String? initialRolePrefix;

  const ReportShell({
    super.key,
    required this.child,
    this.initialRolePrefix,
  });

  @override
  State<ReportShell> createState() => _ReportShellState();
}

class _ReportShellState extends State<ReportShell> {
  String _userDisplayName = '';
  String _userRoleLabel = '';
  UserRole? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (!mounted) return;
      final name =
          user.fullName.trim().isNotEmpty ? user.fullName.trim() : user.email;
      setState(() {
        _userDisplayName = name;
        _userRoleLabel = user.role.displayName;
        _userRole = user.role;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _userDisplayName = 'Người dùng';
        _userRoleLabel = '—';
        _userRole = null;
      });
    }
  }

  Color get _primaryColor {
    switch (_userRole) {
      case UserRole.ADMIN:
        return const Color(0xFF6366F1);
      case UserRole.PROJECT_MANAGER:
        return const Color(0xFF137FEC);
      case UserRole.MENTOR:
        return const Color(0xFF6366F1);
      case UserRole.USER:
      case null:
        return const Color(0xFF137FEC);
    }
  }

  String get _subtitle {
    switch (_userRole) {
      case UserRole.ADMIN:
        return 'Quản trị';
      case UserRole.PROJECT_MANAGER:
        return 'Quản lý dự án';
      case UserRole.MENTOR:
        return 'Mentor Portal';
      case UserRole.USER:
      case null:
        return 'EMPLOYEE PORTAL';
    }
  }

  String get _dashboardRoute {
    return AuthGuardService.getRedirectPath(
      _userRole ?? UserRole.USER,
    );
  }

  String get _reportsRoute {
    return '/reports';
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SharedSidebar(
                primaryColor: _primaryColor,
                logoIcon: Icons.school,
                logoText: 'SMETS',
                subtitle: _subtitle,
                menuItems: _reportMenuItems,
                activeRoute: location,
                userDisplayName:
                    _userDisplayName.isEmpty ? '…' : _userDisplayName,
                userRole: _userRoleLabel.isEmpty ? '…' : _userRoleLabel,
                onProfileTap: () => context.go('/profile'),
                onLogout: () async {
                  await AuthService.logout();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đăng xuất thành công')),
                  );
                  context.go('/login');
                },
              ),
              Expanded(child: widget.child),
            ],
          ),
        ],
      ),
    );
  }

  List<SidebarMenuItem> get _reportMenuItems {
    switch (_userRole) {
      case UserRole.ADMIN:
        return _adminReportMenu;
      case UserRole.PROJECT_MANAGER:
        return _pmReportMenu;
      case UserRole.MENTOR:
        return _mentorReportMenu;
      case UserRole.USER:
        return _userReportMenu;
      case null:
        return [];
    }
  }

  List<SidebarMenuItem> get _adminReportMenu => [
        SidebarMenuItem(
          icon: Icons.dashboard_rounded,
          title: 'Tổng quan',
          route: '/user_management',
          tooltip: 'Tổng quan',
        ),
        SidebarMenuItem(
          icon: Icons.assessment_rounded,
          title: 'Báo cáo',
          route: '/reports',
          tooltip: 'Báo cáo',
        ),
        SidebarMenuItem(
          icon: Icons.people_rounded,
          title: 'Người dùng',
          route: '/user_management',
          tooltip: 'Quản lý người dùng',
        ),
        SidebarMenuItem(
          icon: Icons.folder_rounded,
          title: 'Phòng ban',
          route: '/department_management',
          tooltip: 'Quản lý phòng ban',
        ),
      ];

  List<SidebarMenuItem> get _pmReportMenu => [
        SidebarMenuItem(
          icon: Icons.dashboard_rounded,
          title: 'Bảng điều khiển',
          route: '/pm/dashboard',
          tooltip: 'Bảng điều khiển',
        ),
        SidebarMenuItem(
          icon: Icons.assessment_rounded,
          title: 'Báo cáo',
          route: '/reports',
          tooltip: 'Báo cáo',
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
      ];

  List<SidebarMenuItem> get _mentorReportMenu => [
        SidebarMenuItem(
          icon: Icons.grid_view_rounded,
          title: 'Tổng quan',
          route: '/mentor/dashboard',
          tooltip: 'Tổng quan',
        ),
        SidebarMenuItem(
          icon: Icons.menu_book_rounded,
          title: 'Khóa học',
          route: '/mentor/courses',
          tooltip: 'Khóa học',
        ),
        SidebarMenuItem(
          icon: Icons.assessment_rounded,
          title: 'Báo cáo',
          route: '/reports',
          tooltip: 'Báo cáo',
        ),
        SidebarMenuItem(
          icon: Icons.calendar_month_rounded,
          title: 'Lịch mentor',
          route: '/mentor/live-sessions',
          tooltip: 'Lịch mentor',
        ),
      ];

  List<SidebarMenuItem> get _userReportMenu => [
        SidebarMenuItem(
          icon: Icons.dashboard_rounded,
          title: 'Trang chủ',
          route: '/employee/dashboard',
          tooltip: 'Trang chủ',
        ),
        SidebarMenuItem(
          icon: Icons.assessment_rounded,
          title: 'Báo cáo',
          route: '/reports',
          tooltip: 'Báo cáo',
        ),
        SidebarMenuItem(
          icon: Icons.library_books_rounded,
          title: 'Khóa học của tôi',
          route: '/employee/my-courses',
          tooltip: 'Khóa học của tôi',
        ),
      ];
}
