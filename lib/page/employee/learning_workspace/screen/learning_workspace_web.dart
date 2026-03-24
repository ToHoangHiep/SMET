import 'package:flutter/material.dart';
import 'package:smet/page/employee/widgets/shell/employee_top_header.dart';

/// Layout web: sidebar danh sách khóa học (w-80) + nội dung bài học — không dùng icon rail.
class LearningWorkspaceWeb extends StatelessWidget {
  final Widget sidebarNavigation;
  final Widget videoPlayer;
  final Widget lessonHeader;
  final Widget tabs;
  final Widget tabContent;
  final Widget resourcesSidebar;
  final Function(String) onNavigate;
  final VoidCallback onLogout;
  final List<BreadcrumbItem>? breadcrumbs;

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
    this.breadcrumbs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sidebarNavigation,
        Expanded(
          child: Column(
            children: [
              EmployeeTopHeader(
                currentPage: 'Học tập',
                breadcrumbs: breadcrumbs,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (breadcrumbs == null || breadcrumbs!.isEmpty)
                        _buildBreadcrumbs(),
                      const SizedBox(height: 20),
                      videoPlayer,
                      const SizedBox(height: 24),
                      lessonHeader,
                      const SizedBox(height: 24),
                      tabs,
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: tabContent),
                          const SizedBox(width: 24),
                          SizedBox(width: 300, child: resourcesSidebar),
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

  Widget _buildBreadcrumbs() {
    return Row(
      children: [
        _buildBreadcrumbItem(
          'Courses',
          onTap: () => onNavigate('/employee/courses'),
        ),
        const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
        _buildBreadcrumbItem('SMETS Fundamentals', onTap: () {}),
        const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
        _buildBreadcrumbItem('1.1 Welcome to SMETS', isActive: true),
      ],
    );
  }

  Widget _buildBreadcrumbItem(
    String text, {
    VoidCallback? onTap,
    bool isActive = false,
  }) {
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
