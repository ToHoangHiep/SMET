import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/user_model.dart';
import 'package:smet/page/admin/widgets/admin_sidebar.dart';
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
      body: SafeArea(
        child: Row(
          children: [
            AdminSidebar(
              primaryColor: const Color(0xFF6366F1),
              userDisplayName: _currentUserName,
              activeRoute: GoRouterState.of(context).uri.path,
              onProfileTap: () => context.go('/profile'),
              onLogout: () async {
                await AuthService.logout();
                if (!mounted) return;
                context.go('/login');
              },
            ),
            Expanded(child: widget.child),
          ],
        ),
      ),
    );
  }
}
