import 'package:flutter/material.dart';

class CourseCatalogWeb extends StatelessWidget {
  final String pageTitle;
  final Widget searchFilters;
  final Widget courseGrid;
  final Function(String) onNavigate;
  final VoidCallback onLogout;

  const CourseCatalogWeb({
    super.key,
    required this.pageTitle,
    required this.searchFilters,
    required this.courseGrid,
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
                      searchFilters,
                      const SizedBox(height: 24),
                      courseGrid,
                      const SizedBox(height: 32),
                      // Footer
                      _buildFooter(),
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
                  isActive: false,
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
                  isActive: true,
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
          // User profile
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFFCBD5E1),
                    child: Icon(Icons.person, size: 18, color: Colors.white),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nhân viên',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Nhân viên',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
          color:
              isActive
                  ? const Color(0xFF137FEC).withValues(alpha: 0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color:
                  isActive ? const Color(0xFF137FEC) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color:
                    isActive
                        ? const Color(0xFF137FEC)
                        : const Color(0xFF64748B),
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
          // Title with icon
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFF137FEC),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                pageTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Quick search
          SizedBox(
            width: 250,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm nhanh...',
                prefixIcon: const Icon(
                  Icons.search,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Notifications
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF64748B),
            ),
          ),
          // Help
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.help_outline, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.only(top: 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '© 2024 SMETS Learning Management. All rights reserved.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          Row(
            children: [
              _buildFooterLink('Chính sách bảo mật'),
              const SizedBox(width: 24),
              _buildFooterLink('Điều khoản dịch vụ'),
              const SizedBox(width: 24),
              _buildFooterLink('Liên hệ hỗ trợ'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text) {
    return InkWell(
      onTap: () {},
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
      ),
    );
  }
}
