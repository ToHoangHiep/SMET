import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';

class PmTopHeader extends StatelessWidget {
  final String currentPage;
  final String userName;
  final String userRole;
  final VoidCallback? onProfileTap;
  final VoidCallback? onLogout;
  final List<BreadcrumbItem>? breadcrumbs;

  const PmTopHeader({
    super.key,
    required this.currentPage,
    this.userName = '',
    this.userRole = 'Quản lý dự án',
    this.onProfileTap,
    this.onLogout,
    this.breadcrumbs,
  });

  static const _primary = Color(0xFF137FEC);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (breadcrumbs != null && breadcrumbs!.isNotEmpty) ...[
            SharedBreadcrumb(
              items: breadcrumbs!,
              primaryColor: _primary,
              fontSize: 12,
              padding: const EdgeInsets.only(bottom: 4),
            ),
          ],
          Row(
            children: [
              Text(
                currentPage,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.go('/notifications'),
                tooltip: 'Thông báo',
              ),
              const SizedBox(width: 8),
              _buildUserDropdown(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserDropdown(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'profile',
          child: const Row(
            children: [
              Icon(Icons.person_outline, size: 20),
              SizedBox(width: 12),
              Text('Hồ sơ cá nhân'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'settings',
          child: const Row(
            children: [
              Icon(Icons.settings_outlined, size: 20),
              SizedBox(width: 12),
              Text('Cài đặt'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout, size: 20, color: Color(0xFFEF4444)),
              const SizedBox(width: 12),
              const Text(
                'Đăng xuất',
                style: TextStyle(color: Color(0xFFEF4444)),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'profile':
            (onProfileTap ?? () => context.go('/profile'))();
            break;
          case 'settings':
            context.go('/settings');
            break;
          case 'logout':
            (onLogout ?? () => context.go('/login'))();
            break;
        }
      },
      child: Container(
        padding: const EdgeInsets.only(left: 16),
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
        ),
        child: Row(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  userName.isNotEmpty ? userName : 'PM User',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  userRole.isNotEmpty ? userRole : 'Quản lý dự án',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: _primary, width: 2),
              ),
              child: Icon(
                Icons.person,
                color: _primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF64748B),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
