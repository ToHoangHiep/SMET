import 'package:flutter/material.dart';
import 'package:smet/model/user_model.dart';

class UserManagementRoleBadge extends StatelessWidget {
  final UserRole role;

  const UserManagementRoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    String label;

    switch (role) {
      case UserRole.ADMIN:
        bg = const Color(0xFFF3E8FF);
        text = const Color(0xFF6B21A8);
        label = 'QUẢN TRỊ';
        break;
      case UserRole.PROJECT_MANAGER:
        bg = const Color(0xFFDBEAFE);
        text = const Color(0xFF1E40AF);
        label = 'QUẢN LÝ DỰ ÁN';
        break;
      case UserRole.MENTOR:
        bg = const Color(0xFFDCFCE7);
        text = const Color(0xFF166534);
        label = 'HƯỚNG DẪN';
        break;
      default:
        bg = const Color(0xFFF3F4F6);
        text = const Color(0xFF374151);
        label = 'NHÂN VIÊN';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
