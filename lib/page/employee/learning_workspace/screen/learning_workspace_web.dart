import 'package:flutter/material.dart';
import 'package:smet/page/employee/widgets/shell/employee_top_header.dart';

/// Layout web — elevated Coursera-style learning workspace:
/// - More breathing room (larger padding)
/// - Improved spacing between sections
/// - Content area flows: breadcrumb → video → header → tabs → content
/// - Refined visual hierarchy
class LearningWorkspaceWeb extends StatelessWidget {
  final Widget sidebarNavigation;
  final Widget contentArea;
  final Widget lessonHeader;
  final Widget tabs;
  final Widget tabContent;
  final Widget? resourcesSidebar;
  final Function(String) onNavigate;
  final VoidCallback onLogout;
  final List<BreadcrumbItem>? breadcrumbs;
  final bool isQuizMode;

  const LearningWorkspaceWeb({
    super.key,
    required this.sidebarNavigation,
    required this.contentArea,
    required this.lessonHeader,
    required this.tabs,
    required this.tabContent,
    this.resourcesSidebar,
    required this.onNavigate,
    required this.onLogout,
    this.breadcrumbs,
    this.isQuizMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Row(
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
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(36, 28, 36, 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (breadcrumbs == null || breadcrumbs!.isEmpty)
                          _buildBreadcrumbs(),
                        const SizedBox(height: 24),
                        contentArea,
                        const SizedBox(height: 28),
                        if (!isQuizMode) ...[
                          lessonHeader,
                          const SizedBox(height: 20),
                          tabs,
                          const SizedBox(height: 28),
                          resourcesSidebar == null
                              ? tabContent
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: tabContent,
                                    ),
                                    const SizedBox(width: 28),
                                    SizedBox(
                                      width: 320,
                                      child: resourcesSidebar!,
                                    ),
                                  ],
                                ),
                        ] else ...[
                          // Quiz mode — content area already has header
                          const SizedBox(height: 0),
                        ],
                      ],
                    ),
                  ),
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
        _buildBreadcrumbItem(
          'Khóa học',
          onTap: () => onNavigate('/employee/courses'),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right, size: 18, color: Color(0xFFCBD5E1)),
        const SizedBox(width: 4),
        _buildBreadcrumbItem(
          'SMETS Fundamentals',
          onTap: () => onNavigate('/employee/course/smet-fundamentals'),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right, size: 18, color: Color(0xFFCBD5E1)),
        const SizedBox(width: 4),
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
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive
                ? const Color(0xFF0F172A)
                : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
