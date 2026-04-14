import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserManagementPageHeader extends StatefulWidget {
  final Color primaryColor;
  final VoidCallback onImportExcel;
  final VoidCallback onDownloadTemplate;
  final VoidCallback onCreateUser;

  const UserManagementPageHeader({
    super.key,
    required this.primaryColor,
    required this.onImportExcel,
    required this.onDownloadTemplate,
    required this.onCreateUser,
  });

  @override
  State<UserManagementPageHeader> createState() =>
      _UserManagementPageHeaderState();
}

class _UserManagementPageHeaderState extends State<UserManagementPageHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isHoveredCreate = false;
  bool _isHoveredImport = false;
  bool _isHoveredTemplate = false;

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
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
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
              color: widget.primaryColor.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.primaryColor.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildHeaderContent(),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.primaryColor,
                    widget.primaryColor.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.people_outline,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quản lý nhân viên',
                  style: GoogleFonts.notoSans(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quản lý toàn bộ nhân viên và quyền truy cập hệ thống',
                  style: GoogleFonts.notoSans(
                    color: const Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        _AnimatedButton(
          onPressed: widget.onDownloadTemplate,
          isHovered: _isHoveredTemplate,
          onHover: (value) => setState(() => _isHoveredTemplate = value),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF374151),
          borderColor: const Color(0xFFE5E7EB),
          hoverBorderColor: widget.primaryColor.withValues(alpha: 0.5),
          primaryColor: widget.primaryColor,
          icon: Icons.download_outlined,
          label: 'Tải template',
        ),
        const SizedBox(width: 12),
        _AnimatedButton(
          onPressed: widget.onImportExcel,
          isHovered: _isHoveredImport,
          onHover: (value) => setState(() => _isHoveredImport = value),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF374151),
          borderColor: const Color(0xFFE5E7EB),
          hoverBorderColor: widget.primaryColor.withValues(alpha: 0.5),
          primaryColor: widget.primaryColor,
          icon: Icons.upload_file_outlined,
          label: 'Nhập Excel',
        ),
        const SizedBox(width: 12),
        _AnimatedButton(
          onPressed: widget.onCreateUser,
          isHovered: _isHoveredCreate,
          onHover: (value) => setState(() => _isHoveredCreate = value),
          backgroundColor: widget.primaryColor,
          foregroundColor: Colors.white,
          borderColor: widget.primaryColor,
          hoverBorderColor: widget.primaryColor,
          primaryColor: widget.primaryColor,
          icon: Icons.person_add_outlined,
          label: 'Tạo nhân viên',
          isPrimary: true,
        ),
      ],
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isHovered;
  final ValueChanged<bool> onHover;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final Color hoverBorderColor;
  final Color primaryColor;
  final IconData icon;
  final String label;
  final bool isPrimary;

  const _AnimatedButton({
    required this.onPressed,
    required this.isHovered,
    required this.onHover,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.hoverBorderColor,
    required this.primaryColor,
    required this.icon,
    required this.label,
    this.isPrimary = false,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _btnController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _btnController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _btnController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _btnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => widget.onHover(true),
      onExit: (_) => widget.onHover(false),
      child: GestureDetector(
        onTapDown: (_) => _btnController.forward(),
        onTapUp: (_) => _btnController.reverse(),
        onTapCancel: () => _btnController.reverse(),
        onTap: widget.onPressed,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: widget.isHovered
                  ? (widget.isPrimary
                      ? widget.backgroundColor.withValues(alpha: 0.9)
                      : widget.backgroundColor)
                  : widget.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isHovered ? widget.hoverBorderColor : widget.borderColor,
                width: widget.isHovered ? 1.5 : 1,
              ),
              boxShadow: widget.isHovered
                  ? [
                      BoxShadow(
                        color: widget.primaryColor.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 20,
                  color: widget.isHovered
                      ? widget.foregroundColor
                      : widget.foregroundColor.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: GoogleFonts.notoSans(
                    color: widget.isHovered
                        ? widget.foregroundColor
                        : widget.foregroundColor.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
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
