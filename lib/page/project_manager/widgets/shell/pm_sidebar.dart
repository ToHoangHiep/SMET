import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PmSidebar extends StatelessWidget {
  final VoidCallback onLogout;
  final String userDisplayName;

  const PmSidebar({
    super.key,
    required this.onLogout,
    this.userDisplayName = 'Quản lý dự án',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      margin: const EdgeInsets.fromLTRB(12, 12, 0, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF137FEC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'P',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Quản lý dự án',
                  style: TextStyle(
                    color: Color(0xFF137FEC),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _sidebarItem(context, Icons.dashboard, 'Bảng điều khiển',
              route: '/pm/dashboard', isActive: _isCurrentRoute('/pm/dashboard', context)),
          _sidebarItem(context, Icons.folder, 'Dự án',
              route: '/pm/projects', isActive: _isCurrentRoute('/pm/projects', context)),
          _sidebarItem(context, Icons.people, 'Thành viên',
              route: '/pm/project_members', isActive: _isCurrentRoute('/pm/project_members', context)),
          _sidebarItem(context, Icons.trending_up, 'Tiến độ',
              route: '/pm/project_progress', isActive: _isCurrentRoute('/pm/project_progress', context)),
          _sidebarItem(context, Icons.menu_book, 'Lộ trình học',
              route: '/pm/learning_path', isActive: _isCurrentRoute('/pm/learning_path', context)),
          const Spacer(),
          const Divider(height: 1),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 4,
            ),
            leading: const CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: const Text(
              'Quản lý dự án',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              userDisplayName,
              style: const TextStyle(fontSize: 12),
            ),
            onTap: () => context.go('/profile'),
            trailing: Tooltip(
              message: 'Đăng xuất',
              child: IconButton(
                icon: const Icon(Icons.logout, color: Colors.grey),
                onPressed: onLogout,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  bool _isCurrentRoute(String route, BuildContext context) {
    return GoRouterState.of(context).uri.path == route;
  }

  Widget _sidebarItem(
    BuildContext context,
    IconData icon,
    String title, {
    bool isActive = false,
    required String route,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFEBF5FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border:
            isActive
                ? const Border(
                  right: BorderSide(width: 4, color: Color(0xFF137FEC)),
                )
                : null,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          icon,
          color: isActive ? const Color(0xFF137FEC) : Colors.grey[600],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? const Color(0xFF137FEC) : Colors.grey[700],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        onTap: () => context.go(route),
      ),
    );
  }
}
