import 'package:flutter/material.dart';
import 'package:smet/page/employee/widgets/shell/employee_top_header.dart';
import 'package:smet/page/sidebar/shared_sidebar.dart';
import 'package:smet/page/sidebar/sidebar_menu_item.dart';

class MyCoursesWeb extends StatelessWidget {
  final String pageTitle;
  final Widget courseGrid;
  final List<SidebarMenuItem> menuItems;
  final Function(String) onNavigate;
  final VoidCallback onLogout;
  final List<BreadcrumbItem>? breadcrumbs;

  const MyCoursesWeb({
    super.key,
    required this.pageTitle,
    required this.courseGrid,
    required this.menuItems,
    required this.onNavigate,
    required this.onLogout,
    this.breadcrumbs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SharedSidebar(
          primaryColor: const Color(0xFF137FEC),
          logoIcon: Icons.school,
          logoText: 'SMETS',
          subtitle: 'EMPLOYEE PORTAL',
          menuItems: menuItems,
          activeRoute: '/employee/my-courses',
          userDisplayName: 'Employee',
          userRole: 'Nhân viên',
          onLogout: onLogout,
          onProfileTap: () => onNavigate('/profile'),
        ),
        Expanded(
          child: Column(
            children: [
              EmployeeTopHeader(
                currentPage: pageTitle,
                breadcrumbs: breadcrumbs,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [courseGrid],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
