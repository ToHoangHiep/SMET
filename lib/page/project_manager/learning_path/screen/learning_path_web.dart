import 'package:flutter/material.dart';
import 'package:smet/page/project_manager/widgets/shell/pm_sidebar.dart';
import 'package:smet/page/project_manager/widgets/shell/pm_top_header.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';

class LearningPathWeb extends StatelessWidget {
  final Widget pageHeader;
  final Widget tableSection;
  final String userName;
  final VoidCallback onLogout;

  const LearningPathWeb({
    super.key,
    required this.pageHeader,
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
              PmTopHeader(
                currentPage: 'Lộ trình học',
                breadcrumbs: const [
                  BreadcrumbItem(label: 'Trang chủ', route: '/home'),
                  BreadcrumbItem(label: 'Lộ trình học'),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      pageHeader,
                      const SizedBox(height: 20),
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
