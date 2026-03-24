import 'package:flutter/material.dart';
import 'package:smet/page/employee/widgets/shell/employee_top_header.dart';
import 'package:smet/page/sidebar/shared_sidebar.dart';
import 'package:smet/page/sidebar/sidebar_menu_item.dart';

class EmployeeDashboardWeb extends StatelessWidget {
  final Widget welcomeSection;
  final Widget statsCards;
  final Widget courseList;
  final Widget deadlines;
  final Widget liveSessions;
  final String userName;
  final String userRole;
  final List<SidebarMenuItem> menuItems;
  final Function(String) onNavigate;
  final VoidCallback onLogout;
  final List<BreadcrumbItem>? breadcrumbs;

  const EmployeeDashboardWeb({
    super.key,
    required this.welcomeSection,
    required this.statsCards,
    required this.courseList,
    required this.deadlines,
    required this.liveSessions,
    required this.userName,
    required this.userRole,
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
          activeRoute: '/employee/dashboard',
          userDisplayName: userName.isNotEmpty ? userName : 'Employee',
          userRole: userRole.isNotEmpty ? userRole : 'Nhân viên',
          onLogout: onLogout,
          onProfileTap: () => onNavigate('/profile'),
        ),
        Expanded(
          child: Column(
            children: [
              EmployeeTopHeader(
                currentPage: 'Trang chủ',
                breadcrumbs: breadcrumbs,
              ),
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: courseList),
                          const SizedBox(width: 24),
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
}
