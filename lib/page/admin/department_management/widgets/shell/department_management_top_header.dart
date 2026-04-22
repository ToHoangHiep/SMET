import 'package:flutter/material.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/page/shared/widgets/notification_bell_button.dart';

class DepartmentManagementTopHeader extends StatefulWidget {
  final Color primaryColor;
  final List<BreadcrumbItem>? breadcrumbs;

  const DepartmentManagementTopHeader({
    super.key,
    this.primaryColor = const Color(0xFF137FEC),
    this.breadcrumbs,
  });

  @override
  State<DepartmentManagementTopHeader> createState() =>
      _DepartmentManagementTopHeaderState();
}

class _DepartmentManagementTopHeaderState
    extends State<DepartmentManagementTopHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.breadcrumbs != null &&
                widget.breadcrumbs!.isNotEmpty) ...[
              SharedBreadcrumb(
                items: widget.breadcrumbs!,
                primaryColor: widget.primaryColor,
                fontSize: 12,
                padding: const EdgeInsets.only(bottom: 4),
              ),
            ],
            Row(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.dashboard_outlined,
                        color: widget.primaryColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Bảng điều khiển quản trị',
                      style: TextStyle(
                        color: Color(0xFF374151),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                NotificationBellButton(
                  primaryColor: widget.primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
