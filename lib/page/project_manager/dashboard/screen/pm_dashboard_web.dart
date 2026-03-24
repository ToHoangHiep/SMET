import 'package:flutter/material.dart';
import 'package:smet/page/project_manager/widgets/shell/pm_sidebar.dart';
import 'package:smet/page/project_manager/widgets/shell/pm_top_header.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';

class PmDashboardWeb extends StatelessWidget {
  final Widget welcomeSection;
  final Widget statsCards;
  final Widget projectStatusChart;
  final Widget recentProjects;
  final String userName;
  final VoidCallback onLogout;
  final VoidCallback? onProfileTap;
  final List<BreadcrumbItem>? breadcrumbs;

  const PmDashboardWeb({
    super.key,
    required this.welcomeSection,
    required this.statsCards,
    required this.projectStatusChart,
    required this.recentProjects,
    required this.userName,
    required this.onLogout,
    this.onProfileTap,
    this.breadcrumbs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PmSidebar(
          userDisplayName: userName,
          onLogout: onLogout,
          onProfileTap: onProfileTap,
        ),
        Expanded(
          child: Column(
            children: [
              PmTopHeader(
                currentPage: 'Bảng điều khiển',
                breadcrumbs:
                    breadcrumbs ??
                    const [BreadcrumbItem(label: 'Trang chủ', route: '/home')],
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
                      projectStatusChart,
                      const SizedBox(height: 24),
                      recentProjects,
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
