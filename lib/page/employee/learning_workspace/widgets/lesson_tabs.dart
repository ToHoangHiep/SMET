import 'package:flutter/material.dart';
import 'package:smet/model/learning_model.dart';

class LessonTabs extends StatelessWidget {
  final LessonTab selectedTab;
  final ValueChanged<LessonTab> onTabChanged;
  final int discussionCount;

  const LessonTabs({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
    this.discussionCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: LessonTab.values.map((tab) {
          final isSelected = tab == selectedTab;
          return _buildTabItem(tab, isSelected);
        }).toList(),
      ),
    );
  }

  Widget _buildTabItem(LessonTab tab, bool isSelected) {
    return InkWell(
      onTap: () => onTabChanged(tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF137FEC) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getIconData(tab.icon),
              size: 18,
              color: isSelected ? const Color(0xFF137FEC) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF137FEC) : const Color(0xFF64748B),
              ),
            ),
            if (tab == LessonTab.discussion && discussionCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF137FEC).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$discussionCount',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF137FEC),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'description':
        return Icons.description_outlined;
      case 'folder_zip':
        return Icons.folder_zip_outlined;
      case 'forum':
        return Icons.forum_outlined;
      case 'history':
        return Icons.history;
      default:
        return Icons.circle_outlined;
    }
  }
}
