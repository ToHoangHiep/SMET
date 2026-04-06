import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/user_model.dart';
import 'package:smet/page/sidebar/shared_sidebar.dart';
import 'package:smet/page/sidebar/sidebar_menu_item.dart';
import 'package:smet/service/common/auth_guard_service.dart';
import 'package:smet/service/common/auth_service.dart';

/// Mentor Shell - Layout chung cho tất cả các màn hình mentor
/// Sử dụng SharedSidebar dùng chung cho cả dự án
class MentorShell extends StatefulWidget {
  final Widget child;
  final int currentIndex;

  const MentorShell({super.key, required this.child, this.currentIndex = 0});

  /// Menu items cho mentor sidebar
  static List<SidebarMenuItem> get mentorMenuItems => [
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
      icon: Icons.account_tree_rounded,
      title: 'Lộ trình',
      route: '/mentor/learning-paths',
      tooltip: 'Lộ trình học tập',
    ),
    SidebarMenuItem(
      icon: Icons.assessment_rounded,
      title: 'Báo cáo',
      route: '/mentor/course-report',
      tooltip: 'Báo cáo',
    ),
    SidebarMenuItem(
      icon: Icons.calendar_month_rounded,
      title: 'Lịch mentor',
      route: '/mentor/live-sessions',
      tooltip: 'Lịch mentor',
    ),
    SidebarMenuItem(
      icon: Icons.rate_review_rounded,
      title: 'Chấm bài',
      route: '/mentor/review-assignments',
      tooltip: 'Chấm bài',
    ),
    SidebarMenuItem(
      icon: Icons.people_rounded,
      title: 'Học viên',
      route: '/mentor/students',
      tooltip: 'Học viên',
    ),
    SidebarMenuItem(
      icon: Icons.work_rounded,
      title: 'Dự án',
      route: '/mentor/projects',
      tooltip: 'Dự án hướng dẫn',
    ),
    SidebarMenuItem(
      icon: Icons.chat_bubble_rounded,
      title: 'Tin nhắn',
      route: '/mentor/messages',
      tooltip: 'Tin nhắn',
    ),
  ];

  /// Map route path → index để highlight sidebar item đúng
  static int getIndexFromRoute(String path) {
    if (path.startsWith('/mentor/dashboard')) return 0;
    if (path.startsWith('/mentor/courses') ||
        path.startsWith('/mentor/quizzes'))
      return 1;
    if (path.startsWith('/mentor/learning-paths')) return 2;
    if (path.startsWith('/mentor/course-report')) return 3;
    if (path.startsWith('/mentor/live-sessions')) return 4;
    if (path.startsWith('/mentor/review-assignments')) return 5;
    if (path.startsWith('/mentor/students')) return 6;
    if (path.startsWith('/mentor/projects')) return 7;
    if (path.startsWith('/mentor/messages')) return 8;
    return 0;
  }

  /// Mentor color theme
  static const Color mentorPrimaryColor = Color(0xFF6366F1);

  @override
  State<MentorShell> createState() => _MentorShellState();
}

class _MentorShellState extends State<MentorShell> {
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
        _userRoleLabel = UserRole.MENTOR.displayName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safety net: nếu user đã cached nhưng role không phù hợp → redirect
    final cachedUser = AuthService.currentUserCached;
    if (cachedUser != null &&
        !AuthGuardService.canAccess('/mentor', cachedUser.role)) {
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
            primaryColor: MentorShell.mentorPrimaryColor,
            logoIcon: Icons.school,
            logoText: 'SMETS',
            subtitle: 'Mentor Portal',
            menuItems: MentorShell.mentorMenuItems,
            activeRoute: location,
            userDisplayName: _userDisplayName.isEmpty ? '…' : _userDisplayName,
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
    );
  }
}
