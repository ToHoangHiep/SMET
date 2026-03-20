import 'package:flutter/material.dart';
import 'package:smet/page/project_manager/widgets/shell/pm_sidebar.dart';
import 'package:smet/page/project_manager/widgets/shell/pm_top_header.dart';

class PmDashboardWeb extends StatelessWidget {
  final Widget welcomeSection;
  final Widget statsCards;
  final Widget projectStatusChart;
  final Widget recentProjects;
  final String userName;
  final VoidCallback onLogout;

  const PmDashboardWeb({
    super.key,
    required this.welcomeSection,
    required this.statsCards,
    required this.projectStatusChart,
    required this.recentProjects,
    required this.userName,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PmSidebar(
          userDisplayName: userName,
          onLogout: onLogout,
        ),
        Expanded(
          child: Column(
            children: [
              const PmTopHeader(currentPage: 'Bảng điều khiển'),
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
