import 'package:flutter/material.dart';
import 'package:smet/model/user_model.dart';

class UserManagementFormCard extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final Color primaryColor;
  final bool isUpdateMode;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final UserRole selectedRole;
  final ValueChanged<UserRole> onRoleChanged;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const UserManagementFormCard({
    super.key,
    required this.formKey,
    required this.primaryColor,
    required this.isUpdateMode,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.phoneController,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  State<UserManagementFormCard> createState() => _UserManagementFormCardState();
}

class _UserManagementFormCardState extends State<UserManagementFormCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
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
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: widget.primaryColor.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Form(
            key: widget.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 28),
                _buildPersonalInfoSection(),
                const SizedBox(height: 20),
                _buildContactSection(),
                const SizedBox(height: 20),
                _buildRoleSection(),
                const SizedBox(height: 32),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
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
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            widget.isUpdateMode ? Icons.edit_note_rounded : Icons.person_add_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isUpdateMode ? 'Cập nhật nhân viên' : 'Tạo nhân viên mới',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.isUpdateMode
                    ? 'Cập nhật thông tin nhân viên trong hệ thống'
                    : 'Thêm nhân viên mới vào hệ thống',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        _AnimatedCloseButton(
          primaryColor: widget.primaryColor,
          onPressed: widget.onCancel,
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: widget.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Thông tin cá nhân',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _AnimatedTextField(
                  controller: widget.firstNameController,
                  label: 'Tên',
                  icon: Icons.badge_outlined,
                  primaryColor: widget.primaryColor,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _AnimatedTextField(
                  controller: widget.lastNameController,
                  label: 'Họ',
                  icon: Icons.badge_outlined,
                  primaryColor: widget.primaryColor,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập họ';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.contact_mail_outlined,
                  color: widget.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Thông tin liên lạc',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _AnimatedTextField(
            controller: widget.emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            primaryColor: widget.primaryColor,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập email';
              }
              if (!value.contains('@')) {
                return 'Email không hợp lệ';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _AnimatedTextField(
            controller: widget.phoneController,
            label: 'Số điện thoại',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            primaryColor: widget.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSection() {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.admin_panel_settings_outlined,
                  color: widget.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Phân quyền',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _AnimatedDropdown(
            value: widget.selectedRole,
            primaryColor: widget.primaryColor,
            onChanged: (value) {
              if (value == null) return;
              widget.onRoleChanged(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _AnimatedOutlinedButton(
          onPressed: widget.onCancel,
          label: 'Hủy',
          icon: Icons.close_rounded,
          primaryColor: widget.primaryColor,
        ),
        const SizedBox(width: 12),
        _AnimatedElevatedButton(
          onPressed: widget.onSubmit,
          label: widget.isUpdateMode ? 'Cập nhật' : 'Tạo nhân viên',
          icon: widget.isUpdateMode ? Icons.save_rounded : Icons.add_rounded,
          primaryColor: widget.primaryColor,
        ),
      ],
    );
  }
}

class _AnimatedCloseButton extends StatefulWidget {
  final Color primaryColor;
  final VoidCallback onPressed;

  const _AnimatedCloseButton({
    required this.primaryColor,
    required this.onPressed,
  });

  @override
  State<_AnimatedCloseButton> createState() => _AnimatedCloseButtonState();
}

class _AnimatedCloseButtonState extends State<_AnimatedCloseButton> {
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
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Icon(
            Icons.close_rounded,
            color: _isHovered
                ? const Color(0xFFEF4444)
                : Colors.grey[400],
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _AnimatedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Color primaryColor;

  const _AnimatedTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
    required this.primaryColor,
  });

  @override
  State<_AnimatedTextField> createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<_AnimatedTextField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: widget.primaryColor.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        onTap: () => setState(() => _isFocused = true),
        onEditingComplete: () => setState(() => _isFocused = false),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(
            color: _isFocused ? widget.primaryColor : Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            widget.icon,
            size: 20,
            color: _isFocused ? widget.primaryColor : Colors.grey[400],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: widget.primaryColor, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEF4444)),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

class _AnimatedDropdown extends StatefulWidget {
  final UserRole value;
  final Color primaryColor;
  final ValueChanged<UserRole?> onChanged;

  const _AnimatedDropdown({
    required this.value,
    required this.primaryColor,
    required this.onChanged,
  });

  @override
  State<_AnimatedDropdown> createState() => _AnimatedDropdownState();
}

class _AnimatedDropdownState extends State<_AnimatedDropdown> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: widget.primaryColor.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: DropdownButtonFormField<UserRole>(
        initialValue: widget.value,
        onTap: () => setState(() => _isFocused = true),
        onChanged: (val) {
          setState(() => _isFocused = false);
          widget.onChanged(val);
        },
        decoration: InputDecoration(
          labelText: 'Vai trò',
          labelStyle: TextStyle(
            color: _isFocused ? widget.primaryColor : Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            Icons.badge_outlined,
            size: 20,
            color: _isFocused ? widget.primaryColor : Colors.grey[400],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: widget.primaryColor, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: const [
          DropdownMenuItem(
            value: UserRole.ADMIN,
            child: Text('Quản trị viên'),
          ),
          DropdownMenuItem(
            value: UserRole.PROJECT_MANAGER,
            child: Text('Quản lý dự án'),
          ),
          DropdownMenuItem(
            value: UserRole.MENTOR,
            child: Text('Người hướng dẫn'),
          ),
          DropdownMenuItem(
            value: UserRole.USER,
            child: Text('Nhân viên'),
          ),
        ],
      ),
    );
  }
}

class _AnimatedOutlinedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final Color primaryColor;

  const _AnimatedOutlinedButton({
    required this.onPressed,
    required this.label,
    required this.icon,
    required this.primaryColor,
  });

  @override
  State<_AnimatedOutlinedButton> createState() => _AnimatedOutlinedButtonState();
}

class _AnimatedOutlinedButtonState extends State<_AnimatedOutlinedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
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
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: _isHovered
                  ? const Color(0xFFF9FAFB)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHovered
                    ? widget.primaryColor.withValues(alpha: 0.5)
                    : const Color(0xFFD1D5DB),
              ),
            ),
            child: InkWell(
              onTap: widget.onPressed,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    size: 20,
                    color: _isHovered
                        ? widget.primaryColor
                        : const Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: _isHovered
                          ? widget.primaryColor
                          : const Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedElevatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final Color primaryColor;

  const _AnimatedElevatedButton({
    required this.onPressed,
    required this.label,
    required this.icon,
    required this.primaryColor,
  });

  @override
  State<_AnimatedElevatedButton> createState() => _AnimatedElevatedButtonState();
}

class _AnimatedElevatedButtonState extends State<_AnimatedElevatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
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
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isHovered
                    ? [
                        widget.primaryColor,
                        widget.primaryColor.withValues(alpha: 0.85),
                      ]
                    : [
                        widget.primaryColor,
                        widget.primaryColor,
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: widget.primaryColor.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: widget.primaryColor.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: InkWell(
              onTap: widget.onPressed,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    size: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
