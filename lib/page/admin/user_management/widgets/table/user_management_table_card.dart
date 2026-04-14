import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smet/model/user_model.dart';
import 'package:smet/model/department_model.dart';
import 'user_management_role_badge.dart';

class UserManagementTableCard extends StatefulWidget {
  final Color primaryColor;
  final List<UserModel> paginatedUsers;
  final List<UserModel> filteredUsers;
  final List<Map<String, String>> roleOptions;
  final bool isLoading;
  final String selectedRole;
  final bool? selectedIsActive;
  final List<DepartmentModel> departments;
  final int? selectedDepartmentId;
  final int currentPage;
  final int rowsPerPage;
  final int? totalElements;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<bool?> onIsActiveChanged;
  final ValueChanged<int?> onDepartmentChanged;
  final VoidCallback? onPrevPage;
  final VoidCallback? onNextPage;
  final ValueChanged<UserModel> onEditUser;
  final ValueChanged<UserModel> onViewUser;
  final ValueChanged<UserModel> onToggleActive;
  final ValueChanged<UserModel>? onReassignDepartment;

  const UserManagementTableCard({
    super.key,
    required this.primaryColor,
    required this.paginatedUsers,
    required this.filteredUsers,
    required this.roleOptions,
    required this.isLoading,
    required this.selectedRole,
    this.selectedIsActive,
    required this.departments,
    this.selectedDepartmentId,
    required this.currentPage,
    required this.rowsPerPage,
    this.totalElements,
    required this.onSearchChanged,
    required this.onRoleChanged,
    required this.onIsActiveChanged,
    required this.onDepartmentChanged,
    required this.onPrevPage,
    required this.onNextPage,
    required this.onEditUser,
    required this.onViewUser,
    required this.onToggleActive,
    this.onReassignDepartment,
  });

  @override
  State<UserManagementTableCard> createState() =>
      _UserManagementTableCardState();
}

class _UserManagementTableCardState extends State<UserManagementTableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(covariant UserManagementTableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading != widget.isLoading && !widget.isLoading) {
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ưu tiên total từ backend; fallback chỉ khi không có phân trang phía server
    final total = widget.totalElements ?? widget.filteredUsers.length;
    final pageStartIndex = (widget.currentPage - 1) * widget.rowsPerPage;
    final itemCountOnPage = widget.paginatedUsers.length;

    int start;
    int end;
    if (total == 0) {
      start = 0;
      end = 0;
    } else {
      start = pageStartIndex + 1;
      // End = vị trí item cuối trên trang (theo số item thực tế), không vượt quá total
      end = pageStartIndex + itemCountOnPage;
      if (end > total) end = total;
      if (start > total) {
        start = 0;
        end = 0;
      } else if (start > end) {
        end = start;
      }
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildFilterSection(),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            _buildTableSection(start, end, total),
            _buildPaginationSection(start, end, total),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SearchField(
                  primaryColor: widget.primaryColor,
                  controller: _searchController,
                  onChanged: widget.onSearchChanged,
                ),
              ),
              const SizedBox(width: 16),
              _RoleFilter(
                primaryColor: widget.primaryColor,
                selectedRole: widget.selectedRole,
                roleOptions: widget.roleOptions,
                onChanged: widget.onRoleChanged,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _IsActiveFilter(
                primaryColor: widget.primaryColor,
                selectedIsActive: widget.selectedIsActive,
                onChanged: widget.onIsActiveChanged,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _DepartmentFilter(
                  primaryColor: widget.primaryColor,
                  departments: widget.departments,
                  selectedDepartmentId: widget.selectedDepartmentId,
                  onChanged: widget.onDepartmentChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableSection(int start, int end, int total) {
    if (widget.isLoading) {
      return Container(
        height: 350,
        padding: const EdgeInsets.all(40),
        child: Center(
          child: _LoadingIndicator(primaryColor: widget.primaryColor),
        ),
      );
    }

    if (widget.paginatedUsers.isEmpty) {
      return Container(
        height: 350,
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'Không tìm thấy dữ liệu',
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm',
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 420,
      child: DataTable2(
        columnSpacing: 20,
        horizontalMargin: 20,
        minWidth: 1100,
        headingRowHeight: 56,
        dataRowHeight: 72,
        headingRowColor: WidgetStateProperty.all(const Color(0xFFFAFBFC)),
        dividerThickness: 0,
        border: TableBorder.symmetric(
          inside: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
        empty: Center(child: Text('Không có dữ liệu')),
        columns: const [
          DataColumn2(
            size: ColumnSize.L,
            label: _TableHeaderLabel(text: 'NHÂN VIÊN'),
          ),
          DataColumn2(
            size: ColumnSize.M,
            label: _TableHeaderLabel(text: 'PHÒNG BAN'),
          ),
          DataColumn2(
            size: ColumnSize.M,
            label: _TableHeaderLabel(text: 'VAI TRÒ'),
          ),
          DataColumn2(
            size: ColumnSize.S,
            label: _TableHeaderLabel(text: 'TRẠNG THÁI'),
          ),
          DataColumn2(
            size: ColumnSize.M,
            label: _TableHeaderLabel(text: 'NGÀY TẠO'),
          ),
          DataColumn2(
            size: ColumnSize.M,
            label: _TableHeaderLabel(text: 'CẬP NHẬT'),
          ),
          DataColumn2(size: ColumnSize.S, label: Text('')),
        ],
        rows: List<DataRow>.generate(
          widget.paginatedUsers.length,
          (index) => _buildDataRow(widget.paginatedUsers[index], index),
        ),
      ),
    );
  }

  Widget _buildPaginationSection(int start, int end, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Hiển thị $start - $end trong số $total kết quả',
            style: GoogleFonts.notoSans(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              _PaginationButton(
                icon: Icons.chevron_left_rounded,
                onPressed: widget.onPrevPage,
                isEnabled: widget.onPrevPage != null,
                primaryColor: widget.primaryColor,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: widget.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.currentPage}',
                  style: TextStyle(
                    color: widget.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _PaginationButton(
                icon: Icons.chevron_right_rounded,
                onPressed: widget.onNextPage,
                isEnabled: widget.onNextPage != null,
                primaryColor: widget.primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(UserModel user, int index) {
    return DataRow(
      color: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.hovered)) {
          return widget.primaryColor.withValues(alpha: 0.08);
        }
        return index.isEven ? Colors.white : const Color(0xFFFAFBFC);
      }),
      cells: [
        DataCell(
          Row(
            children: [
              _UserAvatar(
                primaryColor: widget.primaryColor,
                firstName: user.firstName,
                lastName: user.lastName,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.fullName,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: GoogleFonts.notoSans(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Row(
            children: [
              Icon(Icons.business_outlined, size: 16, color: Colors.grey[400]),
              const SizedBox(width: 8),
              Text(
                user.department ?? 'Chưa có',
                style: GoogleFonts.notoSans(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        DataCell(UserManagementRoleBadge(role: user.role)),
        DataCell(
          _StatusToggle(
            primaryColor: widget.primaryColor,
            isActive: user.isActive,
            onToggle: (val) {
              user.isActive = val;
              widget.onToggleActive(user);
            },
          ),
        ),
        DataCell(
          Text(
            (user.createdAt ?? user.lastUpdated).toString().split(' ')[0],
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
        DataCell(
          Text(
            user.lastUpdated.toString().split(' ')[0],
            style: GoogleFonts.notoSans(color: Colors.grey[600], fontSize: 13),
          ),
        ),
        DataCell(
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _ActionButton(
                icon: Icons.visibility_outlined,
                onPressed: () => widget.onViewUser(user),
                tooltip: 'Xem chi tiết',
              ),
              const SizedBox(width: 4),
              _ActionButton(
                icon: Icons.edit_outlined,
                onPressed: () => widget.onEditUser(user),
                tooltip: 'Chỉnh sửa',
              ),
              if (user.role != UserRole.ADMIN) ...[
                const SizedBox(width: 4),
                _ActionButton(
                  icon: Icons.swap_horiz_rounded,
                  onPressed:
                      widget.onReassignDepartment != null
                          ? () => widget.onReassignDepartment!(user)
                          : null,
                  tooltip: 'Đổi phòng ban',
                  color: Colors.orange,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TableHeaderLabel extends StatelessWidget {
  final String text;

  const _TableHeaderLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.notoSans(
        fontWeight: FontWeight.w700,
        color: const Color(0xFF6B7280),
        fontSize: 12,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  final Color primaryColor;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.primaryColor,
    required this.controller,
    required this.onChanged,
  });

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow:
            _isFocused
                ? [
                  BoxShadow(
                    color: widget.primaryColor.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                : [],
      ),
      child: TextField(
        controller: widget.controller,
        onChanged: widget.onChanged,
        onTap: () => setState(() => _isFocused = true),
        onEditingComplete: () => setState(() => _isFocused = false),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm theo tên hoặc email...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: _isFocused ? widget.primaryColor : Colors.grey[400],
          ),
          suffixIcon:
              widget.controller.text.isNotEmpty
                  ? IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: Colors.grey[400],
                      size: 18,
                    ),
                    onPressed: () {
                      widget.controller.clear();
                      widget.onChanged('');
                    },
                  )
                  : null,
          filled: true,
          fillColor: const Color(0xFFFAFBFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: widget.primaryColor, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class _RoleFilter extends StatelessWidget {
  final Color primaryColor;
  final String selectedRole;
  final List<Map<String, String>> roleOptions;
  final ValueChanged<String> onChanged;

  const _RoleFilter({
    required this.primaryColor,
    required this.selectedRole,
    required this.roleOptions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedRole,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey[600],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          borderRadius: BorderRadius.circular(12),
          items:
              roleOptions
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item['value'],
                      child: Text(
                        item['label']!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  )
                  .toList(),
          onChanged: (val) {
            if (val == null) return;
            onChanged(val);
          },
        ),
      ),
    );
  }
}

enum _StatusOption { all, active, inactive }

class _IsActiveFilter extends StatefulWidget {
  final Color primaryColor;
  final bool? selectedIsActive;
  final ValueChanged<bool?> onChanged;

  const _IsActiveFilter({
    required this.primaryColor,
    required this.selectedIsActive,
    required this.onChanged,
  });

  @override
  State<_IsActiveFilter> createState() => _IsActiveFilterState();
}

class _IsActiveFilterState extends State<_IsActiveFilter> {
  late _StatusOption _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = _toOption(widget.selectedIsActive);
  }

  @override
  void didUpdateWidget(covariant _IsActiveFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIsActive != widget.selectedIsActive) {
      _currentValue = _toOption(widget.selectedIsActive);
    }
  }

  _StatusOption _toOption(bool? v) {
    if (v == null) return _StatusOption.all;
    return v ? _StatusOption.active : _StatusOption.inactive;
  }

  bool? _toBool(_StatusOption opt) {
    switch (opt) {
      case _StatusOption.all: return null;
      case _StatusOption.active: return true;
      case _StatusOption.inactive: return false;
    }
  }

  String get _label {
    switch (_currentValue) {
      case _StatusOption.all: return 'Tất cả trạng thái';
      case _StatusOption.active: return 'Hoạt động';
      case _StatusOption.inactive: return 'Không hoạt động';
    }
  }

  Color get _bgColor {
    switch (_currentValue) {
      case _StatusOption.all: return const Color(0xFFFAFBFC);
      case _StatusOption.active: return const Color(0xFFDCFCE7);
      case _StatusOption.inactive: return const Color(0xFFF3F4F6);
    }
  }

  Color get _borderColor {
    switch (_currentValue) {
      case _StatusOption.all: return Colors.grey.shade200;
      case _StatusOption.active: return const Color(0xFF86EFAC);
      case _StatusOption.inactive: return const Color(0xFFE5E7EB);
    }
  }

  Color get _textColor {
    switch (_currentValue) {
      case _StatusOption.all: return Colors.grey[600]!;
      case _StatusOption.active: return const Color(0xFF16A34A);
      case _StatusOption.inactive: return const Color(0xFF6B7280);
    }
  }

  IconData get _icon {
    switch (_currentValue) {
      case _StatusOption.all: return Icons.filter_list_rounded;
      case _StatusOption.active: return Icons.check_circle_outline;
      case _StatusOption.inactive: return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await showMenu<_StatusOption>(
          context: context,
          position: const RelativeRect.fromLTRB(0, 45, 0, 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          items: [
            PopupMenuItem<_StatusOption>(
              value: _StatusOption.all,
              child: Row(
                children: [
                  Icon(Icons.filter_list_rounded, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 10),
                  const Text('Tất cả trạng thái', style: TextStyle(fontSize: 14)),
                  if (_currentValue == _StatusOption.all)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.check, size: 16, color: Colors.grey),
                    ),
                ],
              ),
            ),
            PopupMenuItem<_StatusOption>(
              value: _StatusOption.active,
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF16A34A)),
                  const SizedBox(width: 10),
                  const Text('Hoạt động', style: TextStyle(fontSize: 14)),
                  if (_currentValue == _StatusOption.active)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.check, size: 16, color: Color(0xFF16A34A)),
                    ),
                ],
              ),
            ),
            PopupMenuItem<_StatusOption>(
              value: _StatusOption.inactive,
              child: Row(
                children: [
                  const Icon(Icons.cancel_outlined, size: 18, color: Color(0xFF6B7280)),
                  const SizedBox(width: 10),
                  const Text('Không hoạt động', style: TextStyle(fontSize: 14)),
                  if (_currentValue == _StatusOption.inactive)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.check, size: 16, color: Color(0xFF6B7280)),
                    ),
                ],
              ),
            ),
          ],
        );
        if (result != null) {
          setState(() => _currentValue = result);
          widget.onChanged(_toBool(result));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 18, color: _textColor),
            const SizedBox(width: 8),
            Text(
              _label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _textColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: _textColor),
          ],
        ),
      ),
    );
  }
}

class _DepartmentFilter extends StatelessWidget {
  final Color primaryColor;
  final List<DepartmentModel> departments;
  final int? selectedDepartmentId;
  final ValueChanged<int?> onChanged;

  const _DepartmentFilter({
    required this.primaryColor,
    required this.departments,
    required this.selectedDepartmentId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: selectedDepartmentId,
          isExpanded: true,
          hint: Row(
            children: [
              Icon(Icons.business_outlined, size: 18, color: Colors.grey[500]),
              const SizedBox(width: 8),
              Text(
                'Tất cả phòng ban',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey[600],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          borderRadius: BorderRadius.circular(12),
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Row(
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 18,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Tất cả phòng ban',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            ...departments.map(
              (dept) => DropdownMenuItem<int?>(
                value: dept.id,
                child: Row(
                  children: [
                    Icon(Icons.business, size: 18, color: primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dept.name,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (dept.code != null && dept.code.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          dept.code,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _LoadingIndicator extends StatefulWidget {
  final Color primaryColor;

  const _LoadingIndicator({required this.primaryColor});

  @override
  State<_LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<_LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * 3.14159,
          child: child,
        );
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [
              widget.primaryColor.withValues(alpha: 0.0),
              widget.primaryColor.withValues(alpha: 0.5),
              widget.primaryColor,
            ],
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final Color primaryColor;
  final String firstName;
  final String? lastName;

  const _UserAvatar({
    required this.primaryColor,
    required this.firstName,
    this.lastName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withValues(alpha: 0.15),
            primaryColor.withValues(alpha: 0.05),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          '${firstName.isNotEmpty ? firstName[0] : ''}'
          '${(lastName ?? '').isNotEmpty ? lastName![0] : ''}',
          style: TextStyle(
            color: primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _StatusToggle extends StatefulWidget {
  final Color primaryColor;
  final bool isActive;
  final ValueChanged<bool> onToggle;

  const _StatusToggle({
    required this.primaryColor,
    required this.isActive,
    required this.onToggle,
  });

  @override
  State<_StatusToggle> createState() => _StatusToggleState();
}

class _StatusToggleState extends State<_StatusToggle> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onToggle(!widget.isActive),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color:
              widget.isActive
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                widget.isActive
                    ? const Color(0xFF86EFAC)
                    : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    widget.isActive
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              widget.isActive ? 'Hoạt động' : 'Tắt',
              style: TextStyle(
                color:
                    widget.isActive
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF6B7280),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.color,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                _isHovered && !isDisabled
                    ? const Color(0xFFEEF2FF)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: isDisabled ? null : widget.onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Icon(
              widget.icon,
              size: 18,
              color:
                  isDisabled
                      ? Colors.grey[300]
                      : (_isHovered
                          ? (widget.color ?? const Color(0xFF4F46E5))
                          : (widget.color ?? Colors.grey[500])),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaginationButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final Color primaryColor;

  const _PaginationButton({
    required this.icon,
    required this.onPressed,
    required this.isEnabled,
    required this.primaryColor,
  });

  @override
  State<_PaginationButton> createState() => _PaginationButtonState();
}

class _PaginationButtonState extends State<_PaginationButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (widget.isEnabled) setState(() => _isHovered = true);
      },
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              _isHovered && widget.isEnabled
                  ? widget.primaryColor.withValues(alpha: 0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                widget.isEnabled ? Colors.grey.shade300 : Colors.grey.shade200,
          ),
        ),
        child: InkWell(
          onTap: widget.isEnabled ? widget.onPressed : null,
          borderRadius: BorderRadius.circular(8),
          child: Icon(
            widget.icon,
            size: 20,
            color:
                widget.isEnabled
                    ? (_isHovered ? widget.primaryColor : Colors.grey[600])
                    : Colors.grey[300],
          ),
        ),
      ),
    );
  }
}
