import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:smet/model/department_model.dart';

class DepartmentManagementTableSection extends StatelessWidget {
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
  final ValueChanged<DepartmentModel> onEdit;
  final ValueChanged<DepartmentModel> onDelete;
  final ValueChanged<DepartmentModel> onShowDetail;
  final VoidCallback? onPrevPage;
  final VoidCallback? onNextPage;

  const DepartmentManagementTableSection({
    super.key,
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
    required this.onEdit,
    required this.onDelete,
    required this.onShowDetail,
    required this.onPrevPage,
    required this.onNextPage,
  });

  @override
  Widget build(BuildContext context) {
    final total = filteredDepartments.length;
    final start = total == 0 ? 0 : (currentPage - 1) * rowsPerPage + 1;
    final end =
        total == 0
            ? 0
            : (currentPage * rowsPerPage > total
                ? total
                : currentPage * rowsPerPage);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          _buildFiltersRow(),
          const SizedBox(height: 12),
          _buildDepartmentTable(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hiển thị $start - $end trong số $total kết quả',
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: onPrevPage,
                    child: const Text('Trước'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onNextPage,
                    child: const Text('Sau'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersRow() {
    return Row(
      children: [
        SizedBox(
          width: 220,
          child: TextField(
            decoration: _filterInputDecoration('Mã bộ phận'),
            onChanged: onCodeChanged,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 220,
          child: TextField(
            decoration: _filterInputDecoration('Người quản lý'),
            onChanged: onManagerChanged,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 210,
          child: DropdownButtonFormField<String>(
            value: statusFilter,
            decoration: _filterInputDecoration('Trạng thái hoạt động'),
            items: const [
              DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả')),
              DropdownMenuItem(
                value: 'Đang hoạt động',
                child: Text('Đang hoạt động'),
              ),
              DropdownMenuItem(value: 'Tạm dừng', child: Text('Tạm dừng')),
            ],
            onChanged: (value) {
              if (value == null) return;
              onStatusChanged(value);
            },
          ),
        ),
      ],
    );
  }

  InputDecoration _filterInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      suffixIcon: const Icon(Icons.search, size: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
    );
  }

  Widget _buildDepartmentTable() {
    return SizedBox(
      width: double.infinity,
      height: 420,
      child: DataTable2(
        minWidth: 920,
        columnSpacing: 18,
        horizontalMargin: 14,
        dataRowHeight: 64,
        headingRowHeight: 50,
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
        empty: const Center(child: Text('Không có dữ liệu')),
        columns: const [
          DataColumn2(size: ColumnSize.S, label: Text('MÃ PHÒNG BAN')),
          DataColumn2(size: ColumnSize.L, label: Text('TÊN PHÒNG BAN')),
          DataColumn2(size: ColumnSize.M, label: Text('NGƯỜI QUẢN LÝ')),
          DataColumn2(size: ColumnSize.S, label: Text('HOẠT ĐỘNG')),
          DataColumn2(size: ColumnSize.M, label: Text('NGÀY CẬP NHẬT')),
          DataColumn2(size: ColumnSize.S, label: Text('THAO TÁC')),
        ],
        rows: List.generate(paginatedDepartments.length, (index) {
          final dept = paginatedDepartments[index];
          final isActive = departmentActiveMap[dept.id] ?? true;

          return DataRow(
            cells: [
              DataCell(Text(dept.code)),
              DataCell(
                InkWell(
                  onTap: () => onShowDetail(dept),
                  child: Text(
                    dept.name,
                    style: const TextStyle(
                      color: Color(0xFF137FEC),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              DataCell(Text(dept.projectManagerName ?? '')),
              DataCell(
                Switch(
                  value: isActive,
                  activeColor: const Color(0xFF137FEC),
                  onChanged: (value) => onToggleActive(dept, value),
                ),
              ),
              const DataCell(Text('16/07/2021')),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      onPressed: () => onEdit(dept),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                    ),
                    IconButton(
                      onPressed: () => onDelete(dept),
                      icon: const Icon(Icons.delete_outline, size: 18),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
