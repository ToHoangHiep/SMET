import 'package:flutter/material.dart';

/// Widget mới — Hiển thị thông tin đơn vị tổ chức.
/// Tương tự phần "Offered by" trên Coursera.
class OfferedBySection extends StatelessWidget {
  final String? departmentName;
  final String? mentorName;

  const OfferedBySection({
    super.key,
    this.departmentName,
    this.mentorName,
  });

  @override
  Widget build(BuildContext context) {
    if (departmentName == null && mentorName == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.business_outlined,
                size: 18,
                color: Color(0xFF137FEC),
              ),
              SizedBox(width: 8),
              Text(
                'Đơn vị tổ chức',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (departmentName != null)
            Text(
              departmentName!,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          if (mentorName != null) ...[
            if (departmentName != null) const SizedBox(height: 4),
            Text(
              mentorName!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
