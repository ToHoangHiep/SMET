import 'package:flutter/material.dart';
import 'package:smet/page/employee/widgets/shell/employee_top_header.dart';

class EmployeeDashboardWeb extends StatelessWidget {
  final Widget welcomeSection;
  final Widget statsCards;
  final Widget courseList;
  final Widget deadlines;
  final Widget liveSessions;
  final List<BreadcrumbItem>? breadcrumbs;

  const EmployeeDashboardWeb({
    super.key,
    required this.welcomeSection,
    required this.statsCards,
    required this.courseList,
    required this.deadlines,
    required this.liveSessions,
    this.breadcrumbs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}
