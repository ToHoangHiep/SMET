import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminSidebar extends StatefulWidget {
  final Color primaryColor;
  final String? userDisplayName;
  final VoidCallback onLogout;
  final VoidCallback? onProfileTap;
  final String activeRoute;

  const AdminSidebar({
    super.key,
    required this.primaryColor,
    this.userDisplayName,
    required this.onLogout,
    this.onProfileTap,
    required this.activeRoute,
  });

  @override
  State<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _isHoveringEdge = false;
  bool _isExpanded = true; // Mặc định mở rộng khi vào trang

  static const double _edgeHoverWidth = 30.0;
  static const double _sidebarExpandedWidth = 280.0;
  static const double _sidebarCollapsedWidth = 72.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward(); // Sidebar luôn hiển thị ngay khi load
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHoverEdge(bool isHovering) {
    if (_isHoveringEdge != isHovering) {
      setState(() {
        _isHoveringEdge = isHovering;
        _isExpanded = isHovering;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHoverEdge(true),
      onExit: (_) => _onHoverEdge(false),
      child: Row(
        children: [
          SizedBox(width: _edgeHoverWidth),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: _isExpanded ? _sidebarExpandedWidth : _sidebarCollapsedWidth,
            margin: EdgeInsets.fromLTRB(
              _isExpanded ? 12 : 8,
              12,
              0,
              12,
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.white,
                    widget.primaryColor.withValues(alpha: 0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.primaryColor.withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryColor.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: AnimatedCrossFade(
                        firstChild: _buildExpandedMenu(),
                        secondChild: _buildCollapsedMenu(),
                        crossFadeState: _isExpanded
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        duration: const Duration(milliseconds: 200),
                      ),
                    ),
                  ),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: AnimatedCrossFade(
        firstChild: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.primaryColor,
                    widget.primaryColor.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.school,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quản trị SMETS',
                    style: TextStyle(
                      color: widget.primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Hệ thống quản lý',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        secondChild: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.primaryColor,
                widget.primaryColor.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: widget.primaryColor.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.school,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
        crossFadeState: _isExpanded
            ? CrossFadeState.showFirst
            : CrossFadeState.showSecond,
        duration: const Duration(milliseconds: 200),
      ),
    );
  }

  Widget _buildExpandedMenu() {
    return Column(
      children: [
        _SidebarItem(
          icon: Icons.people_outline_rounded,
          title: 'Quản lý nhân viên',
          route: '/user_management',
          isActive: widget.activeRoute == '/user_management',
          primaryColor: widget.primaryColor,
        ),
        _SidebarItem(
          icon: Icons.apartment_outlined,
          title: 'Quản lý phòng ban',
          route: '/department_management',
          isActive: widget.activeRoute == '/department_management',
          primaryColor: widget.primaryColor,
        ),
        _SidebarItem(
          icon: Icons.assignment_ind_outlined,
          title: 'Gán khóa học',
          route: '/assignment_management',
          isActive: widget.activeRoute == '/assignment_management',
          primaryColor: widget.primaryColor,
        ),
        _SidebarItem(
          icon: Icons.description_rounded,
          title: 'Báo cáo',
          route: '/reports',
          isActive: widget.activeRoute == '/reports',
          primaryColor: widget.primaryColor,
        ),
      ],
    );
  }

  Widget _buildCollapsedMenu() {
    return Column(
      children: [
        _CollapsedSidebarItem(
          icon: Icons.people_outline_rounded,
          route: '/user_management',
          isActive: widget.activeRoute == '/user_management',
          primaryColor: widget.primaryColor,
          tooltip: 'Quản lý nhân viên',
        ),
        _CollapsedSidebarItem(
          icon: Icons.apartment_outlined,
          route: '/department_management',
          isActive: widget.activeRoute == '/department_management',
          primaryColor: widget.primaryColor,
          tooltip: 'Quản lý phòng ban',
        ),
        _CollapsedSidebarItem(
          icon: Icons.assignment_ind_outlined,
          route: '/assignment_management',
          isActive: widget.activeRoute == '/assignment_management',
          primaryColor: widget.primaryColor,
          tooltip: 'Gán khóa học',
        ),
        _CollapsedSidebarItem(
          icon: Icons.description_rounded,
          route: '/reports',
          isActive: widget.activeRoute == '/reports',
          primaryColor: widget.primaryColor,
          tooltip: 'Báo cáo',
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return AnimatedCrossFade(
      firstChild: GestureDetector(
        onTap: widget.onProfileTap,
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFAFBFC),
                const Color(0xFFF8FAFC),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.primaryColor.withValues(alpha: 0.15),
                      widget.primaryColor.withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.person_rounded,
                    color: widget.primaryColor,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quản trị viên',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    Text(
                      widget.userDisplayName ?? 'Người dùng',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              _LogoutButton(
                primaryColor: widget.primaryColor,
                onLogout: widget.onLogout,
              ),
            ],
          ),
        ),
      ),
      secondChild: Container(
        margin: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.primaryColor.withValues(alpha: 0.15),
                    widget.primaryColor.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.person_rounded,
                  color: widget.primaryColor,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _LogoutButton(
              primaryColor: widget.primaryColor,
              onLogout: widget.onLogout,
            ),
          ],
        ),
      ),
      crossFadeState: _isExpanded
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
      duration: const Duration(milliseconds: 200),
    );
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
              gradient: widget.isActive
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
              border: widget.isActive
                  ? Border(
                      left: BorderSide(
                        color: widget.primaryColor,
                        width: 3,
                      ),
                    )
                  : null,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.isActive
                        ? widget.primaryColor.withValues(alpha: 0.15)
                        : _isHovered
                            ? Colors.grey.withValues(alpha: 0.08)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 20,
                    color: widget.isActive
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
                    color: widget.isActive
                        ? widget.primaryColor
                        : _isHovered
                            ? const Color(0xFF374151)
                            : Colors.grey[600],
                    fontWeight:
                        widget.isActive ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
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

class _CollapsedSidebarItem extends StatefulWidget {
  final IconData icon;
  final String route;
  final bool isActive;
  final Color primaryColor;
  final String tooltip;

  const _CollapsedSidebarItem({
    required this.icon,
    required this.route,
    this.isActive = false,
    required this.primaryColor,
    required this.tooltip,
  });

  @override
  State<_CollapsedSidebarItem> createState() => _CollapsedSidebarItemState();
}

class _CollapsedSidebarItemState extends State<_CollapsedSidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: () => context.go(widget.route),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: widget.isActive
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
              border: widget.isActive
                  ? Border(
                      left: BorderSide(
                        color: widget.primaryColor,
                        width: 3,
                      ),
                    )
                  : null,
            ),
            child: Icon(
              widget.icon,
              size: 24,
              color: widget.isActive
                  ? widget.primaryColor
                  : _isHovered
                      ? Colors.grey[700]
                      : Colors.grey[500],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatefulWidget {
  final Color primaryColor;
  final VoidCallback onLogout;

  const _LogoutButton({
    required this.primaryColor,
    required this.onLogout,
  });

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isHovered
              ? const Color(0xFFFEF2F2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          onTap: widget.onLogout,
          borderRadius: BorderRadius.circular(10),
          child: Icon(
            Icons.logout_rounded,
            size: 20,
            color: _isHovered
                ? const Color(0xFFEF4444)
                : widget.primaryColor, // Màu tím như login
          ),
        ),
      ),
    );
  }
}