import 'package:flutter/material.dart';
import 'package:smet/page/project_manager/widgets/shell/pm_top_header.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';

class ProjectManagementWeb extends StatelessWidget {
  final Widget pageHeader;
  final Widget formCard;
  final Widget tableSection;
  final bool showForm;
  final String userName;
  final VoidCallback onLogout;
  final VoidCallback? onProfileTap;

  const ProjectManagementWeb({
    super.key,
    required this.pageHeader,
    required this.formCard,
    required this.tableSection,
    required this.showForm,
    required this.userName,
    required this.onLogout,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PmTopHeader(
          currentPage: 'Quản lý dự án',
          breadcrumbs: const [
            BreadcrumbItem(label: 'Trang chủ', route: '/home'),
            BreadcrumbItem(label: 'Quản lý dự án'),
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
                showForm ? formCard : tableSection,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
