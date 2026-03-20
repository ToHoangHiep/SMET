import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Mentor Shell - Layout chung cho tất cả các màn hình mentor
/// Chứa sidebar điều hướng và nội dung chính
class MentorShell extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const MentorShell({
    super.key,
    required this.child,
    this.currentIndex = 0,
  });

  /// Get current index based on route path
  static int getIndexFromPath(String path) {
    if (path.startsWith('/mentor/courses')) return 1;
    if (path.startsWith('/mentor/learning-paths')) return 2;
    if (path.startsWith('/mentor/dashboard')) return 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    // Get current route to highlight sidebar
    final location = GoRouterState.of(context).uri.path;
    final index = getIndexFromPath(location);

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          _MentorSidebar(
            selectedIndex: index,
            onItemSelected: (idx) => _navigateTo(context, idx),
          ),
          // Main content
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/mentor/dashboard');
        break;
      case 1:
        context.go('/mentor/courses');
        break;
      case 2:
        context.go('/mentor/learning-paths');
        break;
      case 3:
      case 4:
      case 5:
        // Chưa có trang - hiện thông báo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trang đang phát triển')),
        );
        break;
    }
  }
}

/// Sidebar widget cho mentor - có chức năng collapse/expand
class _MentorSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int)? onItemSelected;

  const _MentorSidebar({
    this.selectedIndex = 0,
    this.onItemSelected,
  });

  @override
  State<_MentorSidebar> createState() => _MentorSidebarState();
}

class _MentorSidebarState extends State<_MentorSidebar> {
  bool _isExpanded = false;
  bool _isHovered = false;

  static const double _expandedWidth = 250.0;
  static const double _collapsedWidth = 72.0;

  void _toggleSidebar() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Auto expand when hovered, collapse when not hovered
    final bool shouldExpand = _isExpanded || _isHovered;
    final width = shouldExpand ? _expandedWidth : _collapsedWidth;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            right: BorderSide(color: Color(0xffe0e0e0)),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // LOGO
            if (shouldExpand)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.school, color: Color(0xff1a90ff), size: 24),
                  SizedBox(width: 8),
                  Text(
                    "SMETS",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  )
                ],
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Icon(Icons.school, color: Color(0xff1a90ff), size: 28),
              ),

            const SizedBox(height: 20),

            // MENU ITEMS
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _menuItem(context, Icons.grid_view_rounded, "Tổng quan", 0),
                  _menuItem(context, Icons.menu_book_rounded, "Khóa học", 1),
                  _menuItem(context, Icons.account_tree_rounded, "Lộ trình", 2),
                  _menuItem(context, Icons.people_rounded, "Học viên", 3),
                  _menuItem(context, Icons.chat_bubble_rounded, "Tin nhắn", 4),
                  _menuItem(context, Icons.settings_rounded, "Cài đặt", 5),
                ],
              ),
            ),

            // Collapse/Expand button - chỉ hiện khi KHÔNG hover (collapsed mode)
            if (!shouldExpand)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xffe0e0e0)),
                  ),
                ),
                child: _buildCollapsedCollapseButton(),
              ),

            // PROFILE SECTION
            if (shouldExpand)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xffe0e0e0)),
                  ),
                ),
                child: _buildExpandedProfile(),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xffe0e0e0)),
                  ),
                ),
                child: _buildCollapsedProfile(),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedCollapseButton() {
    return InkWell(
      onTap: _toggleSidebar,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chevron_left, size: 20, color: Colors.grey),
            SizedBox(width: 4),
            Text(
              "Thu gọn",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedCollapseButton() {
    return Tooltip(
      message: "Mở rộng",
      preferBelow: false,
      child: InkWell(
        onTap: _toggleSidebar,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildExpandedProfile() {
    return const Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Color(0xff1a90ff),
          child: Icon(Icons.person, color: Colors.white, size: 16),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "TS. Sarah Mitchell",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                "Mentor",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedProfile() {
    return Tooltip(
      message: "TS. Sarah Mitchell\nMentor",
      preferBelow: false,
      child: const CircleAvatar(
        radius: 18,
        backgroundColor: Color(0xff1a90ff),
        child: Icon(Icons.person, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _menuItem(
    BuildContext context,
    IconData icon,
    String title,
    int index,
  ) {
    final bool isSelected = widget.selectedIndex == index;
    final bool shouldExpand = _isExpanded || _isHovered;

    if (shouldExpand) {
      // Expanded mode - show full menu item
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 1),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xffeef3ff) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          dense: true,
          minLeadingWidth: 20,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: Icon(
            icon,
            size: 22,
            color: isSelected ? const Color(0xff1a90ff) : Colors.grey[700],
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isSelected ? const Color(0xff1a90ff) : Colors.black,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          onTap: () {
            widget.onItemSelected?.call(index);
          },
        ),
      );
    } else {
      // Collapsed mode - show icon only with tooltip
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 1),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xffeef3ff) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Tooltip(
          message: title,
          preferBelow: false,
          child: ListTile(
            dense: true,
            minLeadingWidth: 20,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: Icon(
              icon,
              size: 22,
              color: isSelected ? const Color(0xff1a90ff) : Colors.grey[700],
            ),
            onTap: () {
              widget.onItemSelected?.call(index);
            },
          ),
        ),
      );
    }
  }
}
