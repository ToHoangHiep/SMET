import 'package:flutter/material.dart';
import 'package:smet/model/user_model.dart';

class DepartmentManagementFormCard extends StatefulWidget {
  final Color primaryColor;
  final GlobalKey<FormState> formKey;
  final bool isUpdateMode;
  final TextEditingController nameController;
  final TextEditingController codeController;
  final UserModel? selectedManager;
  final String managerFallbackText;
  final bool isActive;
  final List<UserModel> selectedEmployees;
  final VoidCallback onPickManager;
  final VoidCallback? onRemoveManager;
  final VoidCallback onPickEmployees;
  final ValueChanged<bool> onActiveChanged;
  final ValueChanged<UserModel> onRemoveEmployee;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const DepartmentManagementFormCard({
    super.key,
    this.primaryColor = const Color(0xFF137FEC), // Indigo như login
    required this.formKey,
    required this.isUpdateMode,
    required this.nameController,
    required this.codeController,
    this.selectedManager,
    this.managerFallbackText = '',
    required this.isActive,
    required this.selectedEmployees,
    required this.onPickManager,
    this.onRemoveManager,
    required this.onPickEmployees,
    required this.onActiveChanged,
    required this.onRemoveEmployee,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  State<DepartmentManagementFormCard> createState() =>
      _DepartmentManagementFormCardState();
}

class _DepartmentManagementFormCardState
    extends State<DepartmentManagementFormCard> {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.grey.shade200.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withValues(alpha: 0.06),
            blurRadius: 36,
            spreadRadius: 4,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: widget.formKey,
        child: Center(
          child: SizedBox(
            width: 560,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFormHeader(),
                const SizedBox(height: 28),
                _buildNameField(),
                const SizedBox(height: 20),
                _buildCodeField(),
                const SizedBox(height: 20),
                _buildManagerField(),
                const SizedBox(height: 20),
                _buildStatusField(),
                const SizedBox(height: 20),
                _buildEmployeesField(),
                const SizedBox(height: 28),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: widget.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            widget.isUpdateMode
                ? Icons.edit_outlined
                : Icons.add_business_outlined,
            color: widget.primaryColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14),
              children: [
                TextSpan(
                  text: 'Quản lý phòng ban',
                  style: TextStyle(
                    color: widget.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text:
                      widget.isUpdateMode
                          ? ' / Cập nhật phòng ban'
                          : ' / Tạo mới phòng ban',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),
        _buildCloseButton(),
      ],
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tên phòng ban',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF137FEC),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.nameController,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Nhập tên phòng ban',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: const Color(0xFFFAFBFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: widget.primaryColor, width: 1.5),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập tên phòng ban';
            }
            if (value.trim().length < 3) {
              return 'Tên phòng ban phải có ít nhất 3 ký tự';
            }
            if (value.trim().length > 100) {
              return 'Tên phòng ban không được vượt quá 100 ký tự';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mã phòng ban',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF137FEC),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.codeController,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Nhập mã phòng ban',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: const Color(0xFFFAFBFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: widget.primaryColor, width: 1.5),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập mã phòng ban';
            }
            if (value.trim().length < 2) {
              return 'Mã phòng ban phải có ít nhất 2 ký tự';
            }
            if (value.trim().length > 20) {
              return 'Mã phòng ban không được vượt quá 20 ký tự';
            }
            if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value.trim())) {
              return 'Mã phòng ban chỉ chứa chữ, số, gạch dưới và gạch ngang';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildManagerField() {
    final hasManager =
        widget.selectedManager != null || widget.managerFallbackText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Người quản lý',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF137FEC),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: widget.onPickManager,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFBFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        color: widget.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.selectedManager != null
                              ? '${widget.selectedManager!.fullName} (${widget.selectedManager!.role.displayName})${widget.selectedManager!.department != null ? ' - ${widget.selectedManager!.department}' : ' - Chưa có'}'
                              : widget.managerFallbackText.isEmpty
                              ? 'Có thể chọn PM quản lý'
                              : widget.managerFallbackText,
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                (widget.selectedManager != null ||
                                        widget.managerFallbackText.isNotEmpty)
                                    ? const Color(0xFF0F172A)
                                    : Colors.grey[400],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (hasManager && widget.onRemoveManager != null) ...[
              ElevatedButton(
                onPressed: widget.onPickManager,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(hasManager ? 'ĐỔI' : 'CHỌN'),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStatusField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trạng thái hoạt động',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF137FEC),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStatusOption(true, 'Hoạt động'),
            const SizedBox(width: 16),
            _buildStatusOption(false, 'Không hoạt động'),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusOption(bool value, String label) {
    final isSelected = widget.isActive == value;
    return InkWell(
      onTap: () => widget.onActiveChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? widget.primaryColor.withValues(alpha: 0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? widget.primaryColor : const Color(0xFFE5E7EB),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
              color: isSelected ? widget.primaryColor : Colors.grey[400],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color:
                    isSelected ? widget.primaryColor : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Thành viên',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF137FEC),
              ),
            ),
            const SizedBox(width: 8),
            if (widget.selectedEmployees.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.selectedEmployees.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.primaryColor,
                  ),
                ),
              ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: widget.onPickEmployees,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Thêm thành viên'),
              style: OutlinedButton.styleFrom(
                foregroundColor: widget.primaryColor,
                side: BorderSide(
                  color: widget.primaryColor.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
        if (widget.selectedEmployees.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                widget.selectedEmployees
                    .map((e) => _buildEmployeeChip(e))
                    .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildEmployeeChip(UserModel employee) {
    return Chip(
      label: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: Color(0xFF137FEC)),
          children: [
            TextSpan(text: employee.fullName),
            TextSpan(text: ' (${employee.role.displayName})'),
            TextSpan(
              text:
                  employee.department != null
                      ? ' - ${employee.department}'
                      : ' - Chưa có',
              style: const TextStyle(color: Color(0xFF137FEC)),
            ),
          ],
        ),
      ),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: () => widget.onRemoveEmployee(employee),
      backgroundColor: const Color(0xFFFAFBFC),
      side: const BorderSide(color: Color(0xFFE5E7EB)),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: widget.onCancel,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF6B7280),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('HỦY BỎ'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: widget.onSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Text(widget.isUpdateMode ? 'CẬP NHẬT' : 'TẠO MỚI'),
        ),
      ],
    );
  }

  Widget _buildCloseButton() {
    return IconButton(
      onPressed: widget.onCancel,
      icon: const Icon(Icons.close),
      color: Colors.grey[400],
    );
  }
}
