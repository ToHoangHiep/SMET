import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sidebar_menu_item.dart';

class SharedSidebar extends StatefulWidget {
  final Color primaryColor;
  final IconData logoIcon;
  final String logoText;
  final String subtitle;
  final List<SidebarMenuItem> menuItems;
  final String activeRoute;
  final String userDisplayName;
  final String userRole;
  final VoidCallback onLogout;
  final VoidCallback? onProfileTap;

  const SharedSidebar({
    super.key,
    required this.primaryColor,
    required this.logoIcon,
    required this.logoText,
    required this.subtitle,
    required this.menuItems,
    required this.activeRoute,
    required this.userDisplayName,
    required this.userRole,
    required this.onLogout,
    this.onProfileTap,
  });

  @override
  State<SharedSidebar> createState() => _SharedSidebarState();
}

class _SharedSidebarState extends State<SharedSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _isHoveringEdge = false;
  bool _isExpanded = true;

  static const double _edgeHoverWidth = 30.0;
  static const double _sidebarExpandedWidth = 280.0;
  static const double _sidebarCollapsedWidth = 72.0;

  // Responsive breakpoints
  static const double _desktopBreakpoint = 1024.0;
  static const double _tabletBreakpoint = 768.0;

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
    _controller.forward();
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
    final width = MediaQuery.of(context).size.width;

    // Desktop (>1024px): Sidebar với hover expand/collapse
    if (width > _desktopBreakpoint) {
      return _buildDesktopSidebar();
    }
    // Tablet (768-1024px): Mini rail cố định
    else if (width > _tabletBreakpoint) {
      return _buildMiniRailSidebar();
    }
    // Mobile (<768px): Drawer
    else {
      return _buildMobileDrawer(context);
    }
  }

  Widget _buildDesktopSidebar() {
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
                      widget.primaryColor.withValues(alpha: 0.12),
                      Colors.purpleAccent.withValues(alpha: 0.04),
                      Colors.white.withValues(alpha: 0.6),
                      Colors.cyanAccent.withValues(alpha: 0.04),
                    ],
                    stops: const [0.0, 0.4, 0.7, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.primaryColor.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.primaryColor.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildHeader(isExpanded: _isExpanded),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: _isExpanded ? _sidebarExpandedWidth : _sidebarCollapsedWidth,
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _isExpanded
                              ? _buildExpandedMenu()
                              : _buildCollapsedMenu(),
                        ),
                      ),
                    ),
                    _buildFooter(isExpanded: _isExpanded),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniRailSidebar() {
    return Container(
      width: _sidebarCollapsedWidth,
      margin: const EdgeInsets.fromLTRB(8, 12, 0, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.primaryColor.withValues(alpha: 0.12),
            Colors.purpleAccent.withValues(alpha: 0.04),
            Colors.white.withValues(alpha: 0.6),
            Colors.cyanAccent.withValues(alpha: 0.04),
          ],
          stops: const [0.0, 0.4, 0.7, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.primaryColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMiniRailHeader(),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _buildMiniRailMenu(),
            ),
          ),
          _buildMiniRailFooter(),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.primaryColor.withValues(alpha: 0.12),
              Colors.purpleAccent.withValues(alpha: 0.04),
              Colors.white.withValues(alpha: 0.6),
              Colors.cyanAccent.withValues(alpha: 0.04),
            ],
            stops: const [0.0, 0.4, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isExpanded: true),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildExpandedMenu(),
                ),
              ),
              _buildFooter(isExpanded: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({required bool isExpanded}) {
    final headerContent = Row(
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
              widget.logoIcon,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.logoText,
                  style: GoogleFonts.notoSans(
                    color: widget.primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  widget.subtitle,
                  style: GoogleFonts.notoSans(
                    color: const Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );

    if (!isExpanded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Container(
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
              widget.logoIcon,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: headerContent,
    );
  }

  Widget _buildMiniRailHeader() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Container(
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
            widget.logoIcon,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedMenu() {
    return Column(
      children: widget.menuItems.map((item) {
        return _SidebarItem(
          icon: item.icon,
          title: item.title,
          route: item.route,
          isActive: widget.activeRoute == item.route,
          primaryColor: widget.primaryColor,
        );
      }).toList(),
    );
  }

  Widget _buildCollapsedMenu() {
    return Column(
      children: widget.menuItems.map((item) {
        return _CollapsedSidebarItem(
          icon: item.icon,
          route: item.route,
          isActive: widget.activeRoute == item.route,
          primaryColor: widget.primaryColor,
          tooltip: item.tooltip,
        );
      }).toList(),
    );
  }

  Widget _buildMiniRailMenu() {
    return Column(
      children: widget.menuItems.map((item) {
        return _CollapsedSidebarItem(
          icon: item.icon,
          route: item.route,
          isActive: widget.activeRoute == item.route,
          primaryColor: widget.primaryColor,
          tooltip: item.tooltip,
        );
      }).toList(),
    );
  }

  Widget _buildFooter({required bool isExpanded}) {
    if (isExpanded) {
      return _buildExpandedFooter();
    } else {
      return _buildCollapsedFooter();
    }
  }

  Widget _buildMiniRailFooter() {
    return Container(
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
    );
  }

  Widget _buildExpandedFooter() {
    return GestureDetector(
      onTap: widget.onProfileTap,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: const [
              Color(0xFFFAFBFC),
              Color(0xFFF8FAFC),
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
                  Text(
                    widget.userRole,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  Text(
                    widget.userDisplayName,
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
    );
  }

  Widget _buildCollapsedFooter() {
    return Container(
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
                        Colors.white.withValues(alpha: 0.9),
                        Colors.white.withValues(alpha: 0.95),
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
            ),
            child: Row(
              children: [
                if (widget.isActive)
                  Container(
                    width: 4,
                    height: 24,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: widget.primaryColor,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: widget.primaryColor.withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
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
                            ? const Color(0xFF1E293B)
                            : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: GoogleFonts.notoSans(
                      color: widget.isActive
                          ? widget.primaryColor
                          : _isHovered
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF1E293B),
                      fontWeight:
                          widget.isActive ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 14,
                    ),
                    child: Text(widget.title),
                  ),
                ),
                const Spacer(),
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
                        Colors.white.withValues(alpha: 0.9),
                        Colors.white.withValues(alpha: 0.95),
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
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (widget.isActive)
                  Positioned(
                    left: -8,
                    child: Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: widget.primaryColor,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: widget.primaryColor.withValues(alpha: 0.6),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                Icon(
                  widget.icon,
                  size: 24,
                  color: widget.isActive
                      ? widget.primaryColor
                      : _isHovered
                          ? const Color(0xFF1E293B)
                          : const Color(0xFF475569),
                ),
              ],
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
                : widget.primaryColor,
          ),
        ),
      ),
    );
  }
}
