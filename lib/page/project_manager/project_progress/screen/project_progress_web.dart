import 'package:flutter/material.dart';
import 'package:smet/page/project_manager/widgets/shell/pm_sidebar.dart';
import 'package:smet/page/project_manager/widgets/shell/pm_top_header.dart';

class ProjectProgressWeb extends StatelessWidget {
  final Widget statsCards;
  final Widget tableSection;
  final String userName;
  final VoidCallback onLogout;

  const ProjectProgressWeb({
    super.key,
    required this.statsCards,
    required this.tableSection,
    required this.userName,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PmSidebar(userDisplayName: userName, onLogout: onLogout),
        Expanded(
          child: Column(
            children: [
              const PmTopHeader(currentPage: 'Tiến độ dự án'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      statsCards,
                      const SizedBox(height: 24),
                      tableSection,
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
