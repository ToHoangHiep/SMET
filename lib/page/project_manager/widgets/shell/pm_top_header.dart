import 'package:flutter/material.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/page/shared/widgets/notification_bell_button.dart';

class PmTopHeader extends StatelessWidget {
  final String currentPage;
  final List<BreadcrumbItem>? breadcrumbs;

  const PmTopHeader({
    super.key,
    required this.currentPage,
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
              NotificationBellButton(
                primaryColor: _primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
