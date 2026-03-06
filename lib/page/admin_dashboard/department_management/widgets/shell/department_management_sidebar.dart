import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DepartmentManagementSidebar extends StatelessWidget {
  final VoidCallback onLogout;
  final String userDisplayName;

  const DepartmentManagementSidebar({
    super.key,
    required this.onLogout,
    this.userDisplayName = 'John Doe',
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
                      'S',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Quản trị SMETS',
                  style: TextStyle(
                    color: Color(0xFF137FEC),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _sidebarItem(context, Icons.person, 'Quản lý nhân viên', route: '/'),
          _sidebarItem(
            context,
            Icons.model_training,
            'Quản lý đào tạo',
            route: '/training_management',
          ),
          _sidebarItem(
            context,
            Icons.apartment,
            'Quản lý phòng ban',
            route: '/department_management',
            isActive: true,
          ),
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
              'Quản trị viên',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(userDisplayName, style: const TextStyle(fontSize: 12)),
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
