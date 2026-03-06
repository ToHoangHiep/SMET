import 'package:flutter/material.dart';

class DepartmentManagementPageHeader extends StatelessWidget {
  final VoidCallback onCreateDepartment;

  const DepartmentManagementPageHeader({
    super.key,
    required this.onCreateDepartment,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'DANH SÁCH BỘ PHẬN',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B7280),
          ),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: onCreateDepartment,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF137FEC),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Tạo bộ phận'),
        ),
      ],
    );
  }
}
