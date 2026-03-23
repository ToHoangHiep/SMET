import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';

export 'package:smet/page/shared/widgets/shared_breadcrumb.dart' show BreadcrumbItem;

class EmployeeTopHeader extends StatelessWidget {
  final String currentPage;
  final VoidCallback? onNotificationTap;
  final List<BreadcrumbItem>? breadcrumbs;

  const EmployeeTopHeader({
    super.key,
    required this.currentPage,
    this.onNotificationTap,
    this.breadcrumbs,
  });

  static const _primary = Color(0xFF137FEC);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (breadcrumbs != null && breadcrumbs!.isNotEmpty) ...[
            SharedBreadcrumb(
              items: breadcrumbs!,
              primaryColor: _primary,
              fontSize: 12,
              padding: const EdgeInsets.only(bottom: 4),
            ),
          ],
          Row(
            children: [
              Text(
                currentPage,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed:
                    onNotificationTap ?? () => context.go('/notifications'),
                tooltip: 'Thông báo',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
