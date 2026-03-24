import 'package:flutter/material.dart';

class EmployeeDashboardMobile extends StatelessWidget {
  final Widget welcomeSection;
  final Widget statsGrid;
  final Widget courseList;
  final Widget deadlines;
  final Widget liveSessions;
  final String userName;
  final String userRole;
  final Function(String) onNavigate;
  final VoidCallback onLogout;

  const EmployeeDashboardMobile({
    super.key,
    required this.welcomeSection,
    required this.statsGrid,
    required this.courseList,
    required this.deadlines,
    required this.liveSessions,
    required this.userName,
    required this.userRole,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 64,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF137FEC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.school,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'SMETS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF137FEC),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF64748B),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF137FEC).withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF137FEC),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.person,
                color: Color(0xFF137FEC),
                size: 18,
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            welcomeSection,
            const SizedBox(height: 20),
            statsGrid,
            const SizedBox(height: 20),
            courseList,
            const SizedBox(height: 20),
            deadlines,
            const SizedBox(height: 20),
            liveSessions,
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF137FEC),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  userName.isNotEmpty ? userName : 'Employee',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  userRole.isNotEmpty ? userRole : 'Nhân viên',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.dashboard,
            label: 'Dashboard',
            isActive: true,
            onTap: () {
              Navigator.pop(context);
              onNavigate('/employee/dashboard');
            },
          ),
          _buildDrawerItem(
            icon: Icons.library_books,
            label: 'Khóa học của tôi',
            isActive: false,
            onTap: () => Navigator.pop(context),
          ),
          _buildDrawerItem(
            icon: Icons.explore,
            label: 'Danh mục',
            isActive: false,
            onTap: () {
              Navigator.pop(context);
              onNavigate('/employee/courses');
            },
          ),
          _buildDrawerItem(
            icon: Icons.work,
            label: 'Dự án',
            isActive: false,
            onTap: () => Navigator.pop(context),
          ),
          _buildDrawerItem(
            icon: Icons.workspace_premium,
            label: 'Thành tích',
            isActive: false,
            onTap: () => Navigator.pop(context),
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.settings,
            label: 'Cài đặt',
            isActive: false,
            onTap: () => Navigator.pop(context),
          ),
          _buildDrawerItem(
            icon: Icons.logout,
            label: 'Đăng xuất',
            isActive: false,
            onTap: () {
              Navigator.pop(context);
              onLogout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? const Color(0xFF137FEC) : const Color(0xFF64748B),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isActive ? const Color(0xFF137FEC) : const Color(0xFF0F172A),
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF137FEC),
      unselectedItemColor: const Color(0xFF64748B),
      selectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
      ),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.library_books),
          label: 'Khóa học',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.work),
          label: 'Dự án',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Cá nhân',
        ),
      ],
    );
  }
}
