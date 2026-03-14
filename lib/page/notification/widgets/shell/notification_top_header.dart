import 'package:flutter/material.dart';

class NotificationTopHeader extends StatelessWidget {
  final Color primaryColor;
  final List<Map<String, String>> filterOptions;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onMarkAllRead;

  const NotificationTopHeader({
    super.key,
    required this.primaryColor,
    required this.filterOptions,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Text(
            'Thông báo',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedFilter,
                icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                items: filterOptions.map((option) {
                  return DropdownMenuItem<String>(
                    value: option['value'],
                    child: Text(
                      option['label']!,
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) onFilterChanged(value);
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: onMarkAllRead,
            icon: Icon(Icons.done_all, color: primaryColor, size: 20),
            label: Text(
              'Đánh dấu tất cả',
              style: TextStyle(color: primaryColor, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
