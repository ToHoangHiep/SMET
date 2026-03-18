import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UserManagementSidebar extends StatefulWidget {
  final Color primaryColor;
  final String? userDisplayName;
  final VoidCallback onLogout;
  final VoidCallback? onProfileTap;

  const UserManagementSidebar({
    super.key,
    required this.primaryColor,
    this.userDisplayName,
    required this.onLogout,
    this.onProfileTap,
  });

  @override
  State<UserManagementSidebar> createState() => _UserManagementSidebarState();
}

class _UserManagementSidebarState extends State<UserManagementSidebar>
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

  @override
  Widget build(BuildContext context) {
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
                child: Column(
                  children: [
                    _SidebarItem(
                      icon: Icons.people_outline_rounded,
                      title: 'Quản lý nhân viên',
                      route: '/user_management',
                      isActive: true,
                      primaryColor: widget.primaryColor,
                    ),
                    _SidebarItem(
                      icon: Icons.apartment_outlined,
                      title: 'Quản lý phòng ban',
                      route: '/department_management',
                      primaryColor: widget.primaryColor,
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
            child: const Center(
              child: Text(
                'S',
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
    );
  }

  Widget _buildFooter() {
    return GestureDetector(
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
                : Colors.grey[400],
          ),
        ),
      ),
    );
  }
}
