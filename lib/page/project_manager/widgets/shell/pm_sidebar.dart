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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
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
    const primaryColor = Color(0xFF137FEC);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: 280,
        margin: const EdgeInsets.fromLTRB(12, 12, 0, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.white,
              primaryColor.withValues(alpha: 0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryColor.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(primaryColor),
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
                      primaryColor: primaryColor,
                    ),
                    _SidebarItem(
                      icon: Icons.folder_rounded,
                      title: 'Dự án',
                      route: '/pm/projects',
                      isActive: _isCurrentRoute('/pm/projects', context),
                      primaryColor: primaryColor,
                    ),
                    _SidebarItem(
                      icon: Icons.people_rounded,
                      title: 'Thành viên',
                      route: '/pm/project_members',
                      isActive: _isCurrentRoute('/pm/project_members', context),
                      primaryColor: primaryColor,
                    ),
                    _SidebarItem(
                      icon: Icons.trending_up_rounded,
                      title: 'Tiến độ',
                      route: '/pm/project_progress',
                      isActive: _isCurrentRoute(
                        '/pm/project_progress',
                        context,
                      ),
                      primaryColor: primaryColor,
                    ),
                    _SidebarItem(
                      icon: Icons.menu_book_rounded,
                      title: 'Lộ trình học',
                      route: '/pm/learning_path',
                      isActive: _isCurrentRoute('/pm/learning_path', context),
                      primaryColor: primaryColor,
                    ),
                  ],
                ),
              ),
            ),
            _buildFooter(primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, primaryColor.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'P',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quản lý dự án',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Hệ thống quản lý',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(Color primaryColor) {
    return GestureDetector(
      onTap: widget.onProfileTap,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: primaryColor.withValues(alpha: 0.1),
              child: Icon(Icons.person, color: primaryColor, size: 20),
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
                child: Container(
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

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.route,
    this.isActive = false,
    required this.primaryColor,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        if (!widget.isActive) {
          _controller.forward();
        }
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        if (!widget.isActive) {
          _controller.reverse();
        }
      },
      child: GestureDetector(
        onTap: () => context.go(widget.route),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient:
                  widget.isActive
                      ? LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          widget.primaryColor.withValues(alpha: 0.12),
                          widget.primaryColor.withValues(alpha: 0.04),
                        ],
                      )
                      : _isHovered
                      ? LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.grey.withValues(alpha: 0.06),
                          Colors.grey.withValues(alpha: 0.02),
                        ],
                      )
                      : null,
              borderRadius: BorderRadius.circular(14),
              border:
                  widget.isActive
                      ? Border(
                        left: BorderSide(color: widget.primaryColor, width: 3),
                      )
                      : null,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        widget.isActive
                            ? widget.primaryColor.withValues(alpha: 0.15)
                            : _isHovered
                            ? Colors.grey.withValues(alpha: 0.08)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 20,
                    color:
                        widget.isActive
                            ? widget.primaryColor
                            : _isHovered
                            ? Colors.grey[700]
                            : Colors.grey[500],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        widget.isActive ? FontWeight.w600 : FontWeight.w500,
                    color:
                        widget.isActive
                            ? widget.primaryColor
                            : _isHovered
                            ? Colors.grey[800]
                            : Colors.grey[600],
                  ),
                  child: Text(widget.title),
                ),
                const Spacer(),
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
      ),
    );
  }
}
