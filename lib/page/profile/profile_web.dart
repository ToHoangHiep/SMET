import 'package:flutter/material.dart';
import 'package:smet/model/user_model.dart';
import 'package:go_router/go_router.dart';

class ProfilePageWeb extends StatelessWidget {
  final Widget formContent;
  final UserModel? currentUser; // Dữ liệu user để hiển thị Avatar/Tên

  const ProfilePageWeb({
    super.key,
    required this.formContent,
    this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Navigation Bar
            _buildWebHeader(context),

            // 2. Main Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 24,
                ),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 2.1 Sidebar (Left)
                        _buildSidebar(),

                        const SizedBox(width: 32),

                        // 2.2 Content (Right)
                        Expanded(
                          child: Column(
                            children: [
                              // Card hiển thị thông tin chung (Avatar, Tên)
                              _buildProfileHeaderCard(),

                              const SizedBox(height: 24),

                              // Form nhập liệu (Được truyền từ ProfileScreen)
                              formContent,
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widgets con ---

  Widget _buildWebHeader(BuildContext context) {
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
          // Bên trái: Giữ lại Logo SMETS cho đẹp
          const Row(
            children: [
              Icon(Icons.school, color: Color(0xFF137FEC)),
              SizedBox(width: 8),
              Text(
                "SMETS",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),

          // Bên phải: Nút X để đóng
          IconButton(
            onPressed: () {
              // Quay về trang Home (giả sử đường dẫn Home là '/')
              context.go('/home');
            },
            icon: const Icon(Icons.close, size: 28, color: Colors.grey),
            tooltip: 'Đóng',
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return SizedBox(
      width: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Cài đặt",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Quản lý tùy chọn tài khoản của bạn",
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Active Menu Item
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF137FEC).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 14),
              leading: Icon(Icons.manage_accounts, color: Color(0xFF137FEC)),
              title: Text(
                "Tài khoản của tôi",
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

          // Inactive Menu Item
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            leading: Icon(Icons.notifications_none, color: Colors.grey[600]),
            title: Text(
              "Thông báo",
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
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[100]!, width: 4),
                  image:
                      currentUser?.avatarUrl != null
                          ? DecorationImage(
                            image: NetworkImage(currentUser!.avatarUrl!),
                            fit: BoxFit.cover,
                          )
                          : null,
                  color: Colors.grey[200],
                ),
                child:
                    currentUser?.avatarUrl == null
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF137FEC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),

          // Info Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentUser?.fullName ?? "Đang tải...",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  currentUser?.role.name.toUpperCase() ?? "User",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildBadge(
                      currentUser?.role.name.toUpperCase() ?? "USER",
                      Colors.blue[50]!,
                      Colors.blue[800]!,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textCol,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
