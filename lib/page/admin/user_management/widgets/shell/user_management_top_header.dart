import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/page/shared/widgets/notification_bell_button.dart';

class UserManagementTopHeader extends StatefulWidget {
  final List<BreadcrumbItem>? breadcrumbs;

  const UserManagementTopHeader({super.key, this.breadcrumbs});

  @override
  State<UserManagementTopHeader> createState() =>
      _UserManagementTopHeaderState();
}

class _UserManagementTopHeaderState extends State<UserManagementTopHeader>
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
                primaryColor: const Color(0xFF137FEC),
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
                      child: const Icon(
                        Icons.admin_panel_settings_outlined,
                        color: Color(0xFF4F46E5),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Quản trị Hệ thống',
                      style: GoogleFonts.notoSans(
                        color: const Color(0xFF374151),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                NotificationBellButton(
                  primaryColor: const Color(0xFF6366F1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
