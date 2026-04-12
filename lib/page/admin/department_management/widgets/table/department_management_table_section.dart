import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:smet/model/department_model.dart';

class DepartmentManagementTableSection extends StatefulWidget {
  final Color primaryColor;
  final List<DepartmentModel> paginatedDepartments;
  final List<DepartmentModel> filteredDepartments;
  final Map<int, bool> departmentActiveMap;
  final String statusFilter;
  final int currentPage;
  final int rowsPerPage;
  final ValueChanged<String> onCodeChanged;
  final ValueChanged<String> onManagerChanged;
  final ValueChanged<String> onStatusChanged;
  final void Function(DepartmentModel department, bool active) onToggleActive;
  final ValueChanged<DepartmentModel> onDelete;
  final ValueChanged<DepartmentModel> onShowDetail;
  final VoidCallback? onPrevPage;
  final VoidCallback? onNextPage;

  const DepartmentManagementTableSection({
    super.key,
    required this.primaryColor,
    required this.paginatedDepartments,
    required this.filteredDepartments,
    required this.departmentActiveMap,
    required this.statusFilter,
    required this.currentPage,
    required this.rowsPerPage,
    required this.onCodeChanged,
    required this.onManagerChanged,
    required this.onStatusChanged,
    required this.onToggleActive,
    required this.onDelete,
    required this.onShowDetail,
    required this.onPrevPage,
    required this.onNextPage,
  });

  @override
  State<DepartmentManagementTableSection> createState() =>
      _DepartmentManagementTableSectionState();
}

class _DepartmentManagementTableSectionState
    extends State<DepartmentManagementTableSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _codeSearchController = TextEditingController();
  final TextEditingController _managerSearchController =
      TextEditingController();

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
  void dispose() {
    _animationController.dispose();
    _codeSearchController.dispose();
    _managerSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.filteredDepartments.length;
    final pageStartIndex = (widget.currentPage - 1) * widget.rowsPerPage;
    final itemCountOnPage = widget.paginatedDepartments.length;

    int start;
    int end;
    if (total == 0) {
      start = 0;
      end = 0;
    } else {
      start = pageStartIndex + 1;
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildFilterSection(),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            _buildTableSection(),
            _buildPaginationSection(start, end, total),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _SearchField(
              primaryColor: widget.primaryColor,
              controller: _codeSearchController,
              hintText: 'Tìm kiếm theo mã phòng ban...',
              onChanged: widget.onCodeChanged,
              icon: Icons.tag,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _SearchField(
              primaryColor: widget.primaryColor,
              controller: _managerSearchController,
              hintText: 'Tìm kiếm theo người quản lý...',
              onChanged: widget.onManagerChanged,
              icon: Icons.person_outline,
            ),
          ),
          const SizedBox(width: 16),
          _StatusFilter(
            primaryColor: widget.primaryColor,
            selectedStatus: widget.statusFilter,
            onChanged: widget.onStatusChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildTableSection() {
    if (widget.paginatedDepartments.isEmpty) {
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm',
                style: TextStyle(fontSize: 14, color: Colors.grey[400]),
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
            size: ColumnSize.M,
            label: _TableHeaderLabel(text: 'MÃ PHÒNG BAN'),
          ),
          DataColumn2(
            size: ColumnSize.L,
            label: _TableHeaderLabel(text: 'TÊN PHÒNG BAN'),
          ),
          DataColumn2(
            size: ColumnSize.M,
            label: _TableHeaderLabel(text: 'NGƯỜI QUẢN LÝ'),
          ),
          DataColumn2(
            size: ColumnSize.S,
            label: _TableHeaderLabel(text: 'TRẠNG THÁI'),
          ),
          DataColumn2(
            size: ColumnSize.M,
            label: _TableHeaderLabel(text: 'NGÀY CẬP NHẬT'),
          ),
          DataColumn2(size: ColumnSize.M, label: Text('')),
        ],
        rows: List<DataRow>.generate(
          widget.paginatedDepartments.length,
          (index) => _buildDataRow(widget.paginatedDepartments[index], index),
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
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Hiển thị $start - $end trong số $total kết quả',
            style: TextStyle(
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

  DataRow _buildDataRow(DepartmentModel dept, int index) {
    final isActive = widget.departmentActiveMap[dept.id] ?? true;

    return DataRow(
      color: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.hovered)) {
          return widget.primaryColor.withValues(alpha: 0.04);
        }
        return index.isEven ? Colors.white : const Color(0xFFFAFBFC);
      }),
      cells: [
        DataCell(
          _DepartmentCodeBadge(
            primaryColor: widget.primaryColor,
            code: dept.code,
          ),
        ),
        DataCell(
          _DepartmentNameCell(
            primaryColor: widget.primaryColor,
            name: dept.name,
            onTap: () => widget.onShowDetail(dept),
          ),
        ),
        DataCell(_ManagerCell(managerName: dept.projectManagerName)),
        DataCell(
          _StatusToggle(
            primaryColor: widget.primaryColor,
            isActive: isActive,
            onToggle: (val) => widget.onToggleActive(dept, val),
          ),
        ),
        DataCell(
          Text(
            '16/07/2021',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
        DataCell(
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _ActionButton(
                icon: Icons.delete_outline,
                onPressed: () => widget.onDelete(dept),
                tooltip: 'Xóa',
                isDelete: true,
                primaryColor: widget.primaryColor,
              ),
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
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: Color(0xFF6B7280),
        fontSize: 12,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  final Color primaryColor;
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final IconData icon;

  const _SearchField({
    required this.primaryColor,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.icon,
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
          hintText: widget.hintText,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(
            widget.icon,
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

class _StatusFilter extends StatelessWidget {
  final Color primaryColor;
  final String selectedStatus;
  final ValueChanged<String> onChanged;

  const _StatusFilter({
    required this.primaryColor,
    required this.selectedStatus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final statusOptions = [
      {'value': 'Tất cả', 'label': 'Tất cả trạng thái'},
      {'value': 'Đang hoạt động', 'label': 'Đang hoạt động'},
      {'value': 'Tạm dừng', 'label': 'Tạm dừng'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedStatus,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey[600],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          borderRadius: BorderRadius.circular(12),
          items:
              statusOptions
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

class _DepartmentCodeBadge extends StatelessWidget {
  final Color primaryColor;
  final String code;

  const _DepartmentCodeBadge({required this.primaryColor, required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        code,
        style: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _DepartmentNameCell extends StatelessWidget {
  final Color primaryColor;
  final String name;
  final VoidCallback onTap;

  const _DepartmentNameCell({
    required this.primaryColor,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          name,
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _ManagerCell extends StatelessWidget {
  final String? managerName;

  const _ManagerCell({this.managerName});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.person_outline, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            managerName ?? 'Chưa phân công',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color:
                  managerName != null
                      ? const Color(0xFF374151)
                      : Colors.grey[400],
              fontSize: 13,
            ),
          ),
        ),
      ],
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
  final Color primaryColor;
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final bool isDelete;

  const _ActionButton({
    required this.primaryColor,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.isDelete = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        widget.isDelete
            ? (_isHovered ? const Color(0xFFEF4444) : Colors.grey[500])
            : (_isHovered ? const Color(0xFF4F46E5) : Colors.grey[500]);

    final bgColor =
        widget.isDelete
            ? (_isHovered ? const Color(0xFFFEF2F2) : Colors.transparent)
            : (_isHovered ? const Color(0xFFEEF2FF) : Colors.transparent);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Icon(widget.icon, size: 18, color: iconColor),
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
