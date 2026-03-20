import 'package:flutter/material.dart';
import 'package:smet/model/user_model.dart';

class UserManagementRoleBadge extends StatefulWidget {
  final UserRole role;

  const UserManagementRoleBadge({super.key, required this.role});

  @override
  State<UserManagementRoleBadge> createState() => _UserManagementRoleBadgeState();
}

class _UserManagementRoleBadgeState extends State<UserManagementRoleBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    String label;
    IconData icon;

    switch (widget.role) {
      case UserRole.ADMIN:
        bg = const Color(0xFFF3E8FF);
        text = const Color(0xFF6B21A8);
        label = 'Quản trị';
        icon = Icons.admin_panel_settings_rounded;
        break;
      case UserRole.PROJECT_MANAGER:
        bg = const Color(0xFFDBEAFE);
        text = const Color(0xFF1E40AF);
        label = 'Quản lý';
        icon = Icons.business_center_rounded;
        break;
      case UserRole.MENTOR:
        bg = const Color(0xFFDCFCE7);
        text = const Color(0xFF166534);
        label = 'Hướng dẫn';
        icon = Icons.school_rounded;
        break;
      default:
        bg = const Color(0xFFF3F4F6);
        text = const Color(0xFF374151);
        label = 'Nhân viên';
        icon = Icons.person_rounded;
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              bg,
              bg.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: text.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: text.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: text,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: text,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
