import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/user_model.dart';
import 'package:smet/service/common/user_service.dart';

class ProfileWebHeader extends StatelessWidget {
  final UserModel? currentUser;

  const ProfileWebHeader({
    super.key,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.school, color: const Color(0xFF137FEC)),
              const SizedBox(width: 8),
              const Text(
                'SMETS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () async {
              UserRole? role = currentUser?.role;
              if (role == null) {
                try {
                  final u = await UserService.getProfile();
                  role = u.role;
                } catch (_) {
                  role = null;
                }
              }
              if (!context.mounted) return;
              switch (role) {
                case UserRole.ADMIN:
                  context.go('/user_management');
                  break;
                case UserRole.PROJECT_MANAGER:
                  context.go('/pm/dashboard');
                  break;
                case UserRole.MENTOR:
                  context.go('/mentor/dashboard');
                  break;
                case UserRole.USER:
                default:
                  context.go('/employee/dashboard');
              }
            },
            icon: const Icon(Icons.close, size: 28, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
