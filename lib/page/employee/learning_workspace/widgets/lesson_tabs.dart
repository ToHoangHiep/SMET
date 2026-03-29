import 'package:flutter/material.dart';
import 'package:smet/model/Employee_learning_model.dart';

/// Lesson Tabs — modern Coursera-style:
/// - Icon + label per tab
/// - Animated underline indicator
/// - Discussion count badge
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
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        children: LessonTab.values.map((tab) {
          final isSelected = tab == selectedTab;
          return _TabItem(
            tab: tab,
            isSelected: isSelected,
            onTap: () => onTabChanged(tab),
            discussionCount: discussionCount,
          );
        }).toList(),
      ),
    );
  }
}

class _TabItem extends StatefulWidget {
  final LessonTab tab;
  final bool isSelected;
  final VoidCallback onTap;
  final int discussionCount;

  const _TabItem({
    required this.tab,
    required this.isSelected,
    required this.onTap,
    required this.discussionCount,
  });

  @override
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem> {
  bool _isHovered = false;

  IconData get _icon {
    switch (widget.tab.icon) {
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

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: widget.isSelected
                    ? const Color(0xFF137FEC)
                    : (_isHovered
                        ? const Color(0xFFE5E7EB)
                        : Colors.transparent),
                width: widget.isSelected ? 2.5 : 1.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _icon,
                size: 18,
                color: widget.isSelected
                    ? const Color(0xFF137FEC)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Text(
                widget.tab.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      widget.isSelected ? FontWeight.bold : FontWeight.w500,
                  color: widget.isSelected
                      ? const Color(0xFF137FEC)
                      : (_isHovered
                          ? const Color(0xFF475569)
                          : const Color(0xFF64748B)),
                ),
              ),
              if (widget.tab == LessonTab.discussion &&
                  widget.discussionCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF137FEC).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.discussionCount}',
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
      ),
    );
  }
}
