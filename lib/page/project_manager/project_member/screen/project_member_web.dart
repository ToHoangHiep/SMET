import 'package:flutter/material.dart';
import 'package:smet/page/project_manager/widgets/shell/pm_sidebar.dart';
import 'package:smet/page/project_manager/widgets/shell/pm_top_header.dart';

class ProjectMemberWeb extends StatelessWidget {
  final Widget pageHeader;
  final Widget formCard;
  final Widget tableSection;
  final bool showForm;
  final String userName;
  final VoidCallback onLogout;

  const ProjectMemberWeb({
    super.key,
    required this.pageHeader,
    required this.formCard,
    required this.tableSection,
    required this.showForm,
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
              const PmTopHeader(currentPage: 'Thành viên'),
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
          ),
        ),
      ],
    );
  }
}
