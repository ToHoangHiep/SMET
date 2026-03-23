import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationSidebar extends StatelessWidget {
  final Color primaryColor;
  final String userDisplayName;
  final VoidCallback onLogout;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onProfileTap;

  const NotificationSidebar({
    super.key,
    required this.primaryColor,
    required this.userDisplayName,
    required this.onLogout,
    this.onNotificationsTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withAlpha(204)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white.withAlpha(51),
                  child: Text(
                    userDisplayName.isNotEmpty ? userDisplayName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userDisplayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'Thông báo',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Menu items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  label: 'Tất cả thông báo',
                  isActive: true,
                  onTap: onNotificationsTap ?? () {},
                ),
                _MenuItem(
                  icon: Icons.person_outline,
                  label: 'Hồ sơ cá nhân',
                  onTap: onProfileTap ?? () => context.go('/profile'),
                ),
                _MenuItem(
                  icon: Icons.settings_outlined,
                  label: 'Cài đặt',
                  onTap: () {},
                ),
              ],
            ),
          ),

          // Logout
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: _MenuItem(
              icon: Icons.logout,
              label: 'Đăng xuất',
              onTap: onLogout,
              iconColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color? iconColor;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF137FEC).withAlpha(13) : null,
            border: isActive
                ? const Border(left: BorderSide(color: Color(0xFF137FEC), width: 3))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: iconColor ?? (isActive ? const Color(0xFF137FEC) : Colors.grey[600]),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? const Color(0xFF137FEC) : Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
