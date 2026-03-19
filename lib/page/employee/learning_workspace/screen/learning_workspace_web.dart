import 'package:flutter/material.dart';

class LearningWorkspaceWeb extends StatelessWidget {
  final Widget sidebarNavigation;
  final Widget videoPlayer;
  final Widget lessonHeader;
  final Widget tabs;
  final Widget tabContent;
  final Widget resourcesSidebar;
  final Function(String) onNavigate;
  final VoidCallback onLogout;

  const LearningWorkspaceWeb({
    super.key,
    required this.sidebarNavigation,
    required this.videoPlayer,
    required this.lessonHeader,
    required this.tabs,
    required this.tabContent,
    required this.resourcesSidebar,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Sidebar Navigation
        sidebarNavigation,
        // Main Content
        Expanded(
          child: Column(
            children: [
              // Top Header
              _buildTopHeader(),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Breadcrumbs
                      _buildBreadcrumbs(),
                      const SizedBox(height: 20),
                      // Video Player
                      videoPlayer,
                      const SizedBox(height: 24),
                      // Lesson Header
                      lessonHeader,
                      const SizedBox(height: 24),
                      // Tabs
                      tabs,
                      const SizedBox(height: 24),
                      // Content + Sidebar
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Main Content
                          Expanded(
                            flex: 2,
                            child: tabContent,
                          ),
                          const SizedBox(width: 24),
                          // Right Sidebar
                          SizedBox(
                            width: 300,
                            child: resourcesSidebar,
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

  Widget _buildTopHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Search
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm bài học, tài liệu...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
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
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF64748B),
            ),
          ),
          // User
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFF137FEC),
                  child: Icon(Icons.person, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Alex Johnson',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Learner ID: #4402',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    return Row(
      children: [
        _buildBreadcrumbItem('Courses', onTap: () => onNavigate('/employee/courses')),
        const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
        _buildBreadcrumbItem('SMETS Fundamentals', onTap: () {}),
        const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
        _buildBreadcrumbItem('1.1 Welcome to SMETS', isActive: true),
      ],
    );
  }

  Widget _buildBreadcrumbItem(String text, {VoidCallback? onTap, bool isActive = false}) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isActive ? const Color(0xFF0F172A) : const Color(0xFF64748B),
        ),
      ),
    );
  }
}
