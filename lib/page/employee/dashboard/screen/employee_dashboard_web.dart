import 'package:flutter/material.dart';

class EmployeeDashboardWeb extends StatelessWidget {
  final Widget welcomeSection;
  final Widget statsCards;
  final Widget courseList;
  final Widget deadlines;
  final Widget liveSessions;
  final String userName;
  final String userRole;
  final Function(String) onNavigate;
  final VoidCallback onLogout;

  const EmployeeDashboardWeb({
    super.key,
    required this.welcomeSection,
    required this.statsCards,
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
    return Row(
      children: [
        // Sidebar
        _buildSidebar(),
        // Main Content
        Expanded(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      welcomeSection,
                      const SizedBox(height: 24),
                      statsCards,
                      const SizedBox(height: 24),
                      // Main content area: Course list + Right sidebar
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Course list - 2/3 width
                          Expanded(flex: 2, child: courseList),
                          const SizedBox(width: 24),
                          // Right sidebar - 1/3 width
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                deadlines,
                                const SizedBox(height: 24),
                                liveSessions,
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Column(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF137FEC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SMETS',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF137FEC),
                      ),
                    ),
                    Text(
                      'EMPLOYEE PORTAL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Navigation
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              children: [
                _buildNavItem(
                  icon: Icons.dashboard,
                  label: 'Trang chủ',
                  isActive: true,
                  onTap: () => onNavigate('/employee/dashboard'),
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  icon: Icons.library_books,
                  label: 'Khóa học của tôi',
                  isActive: false,
                  onTap: () {},
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  icon: Icons.explore,
                  label: 'Danh mục',
                  isActive: false,
                  onTap: () => onNavigate('/employee/courses'),
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  icon: Icons.work,
                  label: 'Dự án của tôi',
                  isActive: false,
                  onTap: () {},
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  icon: Icons.workspace_premium,
                  label: 'Chứng chỉ của tôi',
                  isActive: false,
                  onTap: () {},
                ),
              ],
            ),
          ),
          // Settings & Logout
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const Divider(height: 1),
                const SizedBox(height: 12),
                _buildNavItem(
                  icon: Icons.settings,
                  label: 'Cài đặt',
                  isActive: false,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF137FEC) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Row(
        children: [
          // Search bar
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm khóa học, file, công việc...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF64748B),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF6F7F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Notifications
          IconButton(
            onPressed: () {},
            icon: Stack(
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF64748B),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // User info
          Container(
            padding: const EdgeInsets.only(left: 16),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      userName.isNotEmpty ? userName : 'Employee',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      userRole.isNotEmpty ? userRole : 'Nhân viên',
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
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
