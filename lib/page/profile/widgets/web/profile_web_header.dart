import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/user_model.dart';

class ProfileWebHeader extends StatelessWidget {
  final UserModel? currentUser;
  const ProfileWebHeader({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
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
          const Row(
            children: [
              Icon(Icons.school, color: Color(0xFF137FEC)),
              SizedBox(width: 8),
              Text(
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
            onPressed: () {
              final role = currentUser?.role;

              switch (role) {
                case UserRole.ADMIN:
                  context.go('/user_management');
                  break;

                case UserRole.PROJECT_MANAGER:
                  context.go('/');
                  break;

                case UserRole.MENTOR:
                  context.go('/');
                  break;

                case UserRole.USER:
                  context.go('/');
                  break;

                default:
                  context.go('/');
              }
            },
            icon: const Icon(Icons.close, size: 28, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
