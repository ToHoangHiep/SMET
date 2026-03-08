import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:smet/model/user_model.dart';
import 'user_management_role_badge.dart';

class UserManagementTableCard extends StatelessWidget {
  final Color primaryColor;
  final List<UserModel> paginatedUsers;
  final List<UserModel> filteredUsers;
  final List<Map<String, String>> roleOptions;
  final bool isLoading;
  final String selectedRole;
  final int currentPage;
  final int rowsPerPage;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback? onPrevPage;
  final VoidCallback? onNextPage;
  final ValueChanged<UserModel> onEditUser;
  final ValueChanged<UserModel> onViewUser;
  final ValueChanged<UserModel> onToggleActive;

  const UserManagementTableCard({
    super.key,
    required this.primaryColor,
    required this.paginatedUsers,
    required this.filteredUsers,
    required this.roleOptions,
    required this.isLoading,
    required this.selectedRole,
    required this.currentPage,
    required this.rowsPerPage,
    required this.onSearchChanged,
    required this.onRoleChanged,
    required this.onPrevPage,
    required this.onNextPage,
    required this.onEditUser,
    required this.onViewUser,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final total = filteredUsers.length;
    final start = total == 0 ? 0 : (currentPage - 1) * rowsPerPage + 1;
    final end =
        total == 0
            ? 0
            : (currentPage * rowsPerPage > total
                ? total
                : currentPage * rowsPerPage);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: 280,
                  child: TextField(
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Tìm theo tên hoặc email...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 210,
                  child: DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 15,
                      ),
                    ),
                    items:
                        roleOptions
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item['value'],
                                child: Text(item['label']!),
                              ),
                            )
                            .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      onRoleChanged(val);
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 420,
              child: DataTable2(
                columnSpacing: 20,
                horizontalMargin: 20,
                minWidth: 1100,
                headingRowHeight: 50,
                dataRowHeight: 70,
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF9FAFB),
                ),
                empty: const Center(child: Text('Không có dữ liệu')),
                columns: const [
                  DataColumn2(
                    size: ColumnSize.L,
                    label: Text(
                      'NHÂN VIÊN',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  DataColumn2(
                    size: ColumnSize.M,
                    label: Text(
                      'PHÒNG BAN',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  DataColumn2(
                    size: ColumnSize.M,
                    label: Text(
                      'VAI TRÒ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  DataColumn2(
                    size: ColumnSize.S,
                    label: Text(
                      'HOẠT ĐỘNG',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  DataColumn2(
                    size: ColumnSize.M,
                    label: Text(
                      'NGÀY TẠO',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  DataColumn2(
                    size: ColumnSize.M,
                    label: Text(
                      'CẬP NHẬT GẦN NHẤT',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  DataColumn2(size: ColumnSize.S, label: Text('')),
                ],
                rows:
                    paginatedUsers.map((user) => _buildDataRow(user)).toList(),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hiển thị $start - $end trong số ${filteredUsers.length} kết quả',
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
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(UserModel user) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              CircleAvatar(
                backgroundColor: primaryColor.withValues(alpha: 0.1),
                child: Text(
                  '${user.firstName.isNotEmpty ? user.firstName[0] : ''}'
                  '${user.lastName.isNotEmpty ? user.lastName[0] : ''}',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                // 👈 QUAN TRỌNG
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.fullName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Tooltip(
                      message: user.email,
                      child: Text(
                        user.email,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        DataCell(
          Text(
            user.department ?? 'Chưa có',
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          ),
        ),
        DataCell(UserManagementRoleBadge(role: user.role)),
        DataCell(
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: user.isActive,
              activeColor: primaryColor,
              onChanged: (val) {
                user.isActive = val;
                onToggleActive(user);
              },
            ),
          ),
        ),
        DataCell(
          Text(
            (user.createdAt ?? user.lastUpdated).toString().split(' ')[0],
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          ),
        ),
        DataCell(
          Text(
            user.lastUpdated.toString().split(' ')[0],
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          ),
        ),
        DataCell(
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.visibility,
                  size: 20,
                  color: Colors.grey,
                ),
                onPressed: () => onViewUser(user),
                tooltip: 'Xem chi tiết',
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                onPressed: () => onEditUser(user),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
