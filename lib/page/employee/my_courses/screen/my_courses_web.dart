import 'package:flutter/material.dart';
import 'package:smet/page/employee/widgets/shell/employee_top_header.dart';

class MyCoursesWeb extends StatelessWidget {
  final String pageTitle;
  final Widget content;
  final List<BreadcrumbItem>? breadcrumbs;

  const MyCoursesWeb({
    super.key,
    required this.pageTitle,
    required this.content,
    this.breadcrumbs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        EmployeeTopHeader(
          currentPage: pageTitle,
          breadcrumbs: breadcrumbs,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
            child: content,
          ),
        ),
      ],
    );
  }
}
