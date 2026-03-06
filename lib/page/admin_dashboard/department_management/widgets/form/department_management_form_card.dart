import 'package:flutter/material.dart';

class DepartmentManagementFormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final bool isUpdateMode;
  final TextEditingController nameController;
  final TextEditingController codeController;
  final TextEditingController managerController;
  final bool isActive;
  final List<String> selectedEmployees;
  final VoidCallback onPickManager;
  final VoidCallback onPickEmployees;
  final ValueChanged<bool> onActiveChanged;
  final ValueChanged<String> onRemoveEmployee;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const DepartmentManagementFormCard({
    super.key,
    required this.formKey,
    required this.isUpdateMode,
    required this.nameController,
    required this.codeController,
    required this.managerController,
    required this.isActive,
    required this.selectedEmployees,
    required this.onPickManager,
    required this.onPickEmployees,
    required this.onActiveChanged,
    required this.onRemoveEmployee,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Form(
        key: formKey,
        child: Center(
          child: SizedBox(
            width: 560,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14),
                    children: [
                      const TextSpan(
                        text: 'Danh sách bộ phận',
                        style: TextStyle(
                          color: Color(0xFF137FEC),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text:
                            isUpdateMode
                                ? ' / Cập nhật bộ phận'
                                : ' / Tạo bộ phận',
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: '* Tên bộ phận',
                    hintText: 'Tên bộ phận',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: inputBorder,
                    enabledBorder: inputBorder,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên bộ phận';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: codeController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: '* Mã bộ phận',
                    hintText: 'Mã bộ phận',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: inputBorder,
                    enabledBorder: inputBorder,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập mã bộ phận';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: managerController,
                        readOnly: true,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Người quản lý',
                          hintText: 'Chọn người quản lý',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          border: inputBorder,
                          enabledBorder: inputBorder,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 40,
                      child: OutlinedButton(
                        onPressed: onPickManager,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF137FEC),
                          side: const BorderSide(color: Color(0xFF137FEC)),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('CHỌN NGƯỜI QUẢN LÝ'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Trạng thái hoạt động',
                  style: TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: isActive,
                      onChanged: (value) {
                        if (value != null) onActiveChanged(value);
                      },
                    ),
                    const Text('Bật', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Radio<bool>(
                      value: false,
                      groupValue: isActive,
                      onChanged: (value) {
                        if (value != null) onActiveChanged(value);
                      },
                    ),
                    const Text('Tắt', style: TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          selectedEmployees.isEmpty
                              ? 'Nhân viên trực thuộc'
                              : '${selectedEmployees.length} nhân viên đã chọn',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                selectedEmployees.isEmpty
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 40,
                      child: OutlinedButton(
                        onPressed: onPickEmployees,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF137FEC),
                          side: const BorderSide(color: Color(0xFF137FEC)),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('THÊM NHÂN VIÊN'),
                      ),
                    ),
                  ],
                ),
                if (selectedEmployees.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        selectedEmployees
                            .map(
                              (e) => Chip(
                                label: Text(
                                  e,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                onDeleted: () => onRemoveEmployee(e),
                              ),
                            )
                            .toList(),
                  ),
                ],
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 38,
                      child: OutlinedButton(
                        onPressed: onCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF137FEC),
                          side: const BorderSide(color: Color(0xFF137FEC)),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('HỦY'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 38,
                      child: ElevatedButton(
                        onPressed: onSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF137FEC),
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: Text(isUpdateMode ? 'CẬP NHẬT' : 'XÁC NHẬN'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
