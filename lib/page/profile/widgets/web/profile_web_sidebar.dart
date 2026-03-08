import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileWebSidebar extends StatelessWidget {
  const ProfileWebSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cài đặt',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Quản lý tùy chọn tài khoản của bạn',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF137FEC).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 14),
              leading: Icon(Icons.manage_accounts, color: Color(0xFF137FEC)),
              title: Text(
                'Tài khoản của tôi',
                style: TextStyle(
                  color: Color(0xFF137FEC),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              dense: true,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(height: 4),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            leading: Icon(Icons.notifications_none, color: Colors.grey[600]),
            title: Text(
              'Thông báo',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            dense: true,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            onTap: () => context.go('/notifications'),
          ),
        ],
      ),
    );
  }
}
