import 'package:flutter/material.dart';
import 'package:smet/page/employee/widgets/shell/employee_top_header.dart';

class CourseCatalogWeb extends StatelessWidget {
  final String pageTitle;
  final Widget searchFilters;
  final Widget courseGrid;
  final List<BreadcrumbItem>? breadcrumbs;

  const CourseCatalogWeb({
    super.key,
    required this.pageTitle,
    required this.searchFilters,
    required this.courseGrid,
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                searchFilters,
                const SizedBox(height: 24),
                courseGrid,
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
