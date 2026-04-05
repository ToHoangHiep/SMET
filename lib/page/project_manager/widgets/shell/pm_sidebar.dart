import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PmSidebar extends StatefulWidget {
  final VoidCallback onLogout;
  final String userDisplayName;
  final VoidCallback? onProfileTap;

  const PmSidebar({
    super.key,
    required this.onLogout,
    this.userDisplayName = 'Quản lý dự án',
    this.onProfileTap,
  });

  @override
  State<PmSidebar> createState() => _PmSidebarState();
}

class _PmSidebarState extends State<PmSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _collapsed = false;

  static const _primary = Color(0xFF137FEC);
  static const _expandedWidth = 280.0;
  static const _collapsedWidth = 72.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCollapse() {
    setState(() => _collapsed = !_collapsed);
  }

  @override
  Widget build(BuildContext context) {
    final width = _collapsed ? _collapsedWidth : _expandedWidth;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            right: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    _SidebarItem(
                      icon: Icons.dashboard_rounded,
                      title: 'Bảng điều khiển',
                      route: '/pm/dashboard',
                      isActive: _isCurrentRoute('/pm/dashboard', context),
                      primaryColor: _primary,
                      collapsed: _collapsed,
                    ),
                    _SidebarItem(
                      icon: Icons.folder_rounded,
                      title: 'Dự án',
                      route: '/pm/projects',
                      isActive: _isCurrentRoute('/pm/projects', context),
                      primaryColor: _primary,
                      collapsed: _collapsed,
                    ),
                    _SidebarItem(
                      icon: Icons.people_rounded,
                      title: 'Thành viên',
                      route: '/pm/project_members',
                      isActive: _isCurrentRoute('/pm/project_members', context),
                      primaryColor: _primary,
                      collapsed: _collapsed,
                    ),
                    _SidebarItem(
                      icon: Icons.trending_up_rounded,
                      title: 'Tiến độ',
                      route: '/pm/project_progress',
                      isActive: _isCurrentRoute('/pm/project_progress', context),
                      primaryColor: _primary,
                      collapsed: _collapsed,
                    ),
                    _SidebarItem(
                      icon: Icons.menu_book_rounded,
                      title: 'Lộ trình học',
                      route: '/pm/learning_path',
                      isActive: _isCurrentRoute('/pm/learning_path', context),
                      primaryColor: _primary,
                      collapsed: _collapsed,
                    ),
                    _SidebarItem(
                      icon: Icons.assignment_ind_rounded,
                      title: 'Gán khóa học',
                      route: '/pm/assign',
                      isActive: _isCurrentRoute('/pm/assign', context),
                      primaryColor: _primary,
                      collapsed: _collapsed,
                    ),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: _collapsed
          ? const EdgeInsets.symmetric(vertical: 16)
          : const EdgeInsets.fromLTRB(20, 20, 12, 20),
      child: _collapsed
          ? Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 22),
              ),
            )
          : Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.school, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SMETS',
                        style: TextStyle(
                          color: _primary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'QUẢN LÝ DỰ ÁN',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFooter() {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          if (!_collapsed)
            GestureDetector(
              onTap: widget.onProfileTap,
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: _primary.withValues(alpha: 0.1),
                      child: Icon(Icons.person, color: _primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quản lý dự án',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            widget.userDisplayName,
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Tooltip(
                      message: 'Đăng xuất',
                      child: InkWell(
                        onTap: widget.onLogout,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.logout_rounded,
                            color: Colors.grey[400],
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Collapse toggle
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleCollapse,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  mainAxisAlignment:
                      _collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: [
                    Icon(
                      _collapsed ? Icons.chevron_right : Icons.chevron_left,
                      color: Colors.grey[500],
                      size: 20,
                    ),
                    if (!_collapsed) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Thu gọn',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isCurrentRoute(String route, BuildContext context) {
    return GoRouterState.of(context).uri.path == route;
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String route;
  final bool isActive;
  final Color primaryColor;
  final bool collapsed;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.route,
    this.isActive = false,
    required this.primaryColor,
    this.collapsed = false,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    if (widget.collapsed) {
      return Tooltip(
        message: widget.title,
        preferBelow: false,
        child: InkWell(
          onTap: () => context.go(widget.route),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? widget.primaryColor.withValues(alpha: 0.12)
                  : (_isHovered ? Colors.grey.shade100 : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
              border: widget.isActive
                  ? Border(left: BorderSide(color: widget.primaryColor, width: 3))
                  : null,
            ),
            child: Icon(
              widget.icon,
              size: 22,
              color:
                  widget.isActive ? widget.primaryColor : Colors.grey[600],
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: () => context.go(widget.route),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isActive
                ? widget.primaryColor.withValues(alpha: 0.12)
                : (_isHovered ? Colors.grey.shade100 : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            border: widget.isActive
                ? Border(left: BorderSide(color: widget.primaryColor, width: 3))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: widget.isActive
                    ? widget.primaryColor
                    : (_isHovered ? Colors.grey[700] : Colors.grey[500]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        widget.isActive ? FontWeight.w600 : FontWeight.w500,
                    color: widget.isActive
                        ? widget.primaryColor
                        : (_isHovered ? Colors.grey[800] : Colors.grey[600]),
                  ),
                ),
              ),
              if (widget.isActive)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: widget.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
