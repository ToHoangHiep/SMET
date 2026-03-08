import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileWebHeader extends StatelessWidget {
  const ProfileWebHeader({super.key});

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
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.close, size: 28, color: Colors.grey),
            tooltip: 'Đóng',
          ),
        ],
      ),
    );
  }
}
