import 'package:flutter/material.dart';

/// Stats row hiển thị chi tiết: video hours, resources, certificate.
/// Nằm ngay bên dưới HeroSection.
/// Coursera-style: icon + value large + label small, divided by subtle dividers.
class CourseStatsSection extends StatelessWidget {
  final int videoHours;
  final int resources;
  final bool hasCertificate;

  const CourseStatsSection({
    super.key,
    required this.videoHours,
    required this.resources,
    required this.hasCertificate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.play_circle_outline,
              iconColor: const Color(0xFF137FEC),
              iconBg: const Color(0xFFDBEAFE),
              label: 'Video bài giảng',
              value: '$videoHours giờ',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: const Color(0xFFE5E7EB),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.folder_outlined,
              iconColor: const Color(0xFFF59E0B),
              iconBg: const Color(0xFFFEF3C7),
              label: 'Tài liệu',
              value: '$resources tài liệu',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: const Color(0xFFE5E7EB),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.workspace_premium_outlined,
              iconColor: const Color(0xFF22C55E),
              iconBg: const Color(0xFFDCFCE7),
              label: 'Chứng chỉ',
              value: hasCertificate ? 'Có chứng chỉ' : 'Không có',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 22, color: iconColor),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
