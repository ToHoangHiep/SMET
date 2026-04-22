import 'package:flutter/material.dart';
import 'package:smet/model/Employee_learning_model.dart';

/// Lesson Tabs — modern elevated design:
/// - Animated pill background indicator
/// - Icon + label per tab
/// - Discussion count badge
/// - Smooth sliding indicator animation
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
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: LessonTab.values.map((tab) {
          final isSelected = tab == selectedTab;
          return Expanded(
            child: _TabItem(
              tab: tab,
              isSelected: isSelected,
              onTap: () => onTabChanged(tab),
              discussionCount: discussionCount,
            ),
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

class _TabItemState extends State<_TabItem> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    if (widget.isSelected) _animController.value = 1.0;
  }

  @override
  void didUpdateWidget(_TabItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _animController.forward();
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _animController.reverse();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  IconData get _icon {
    switch (widget.tab.icon) {
      case 'description':
        return Icons.description_outlined;
      case 'forum':
        return Icons.forum_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  Color _tabColor(BuildContext context) {
    if (widget.isSelected) return const Color(0xFF137FEC);
    if (_isHovered) return const Color(0xFF475569);
    return const Color(0xFF64748B);
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
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? const Color(0xFF137FEC).withValues(alpha: 0.1)
                : (_isHovered
                    ? const Color(0xFFF1F5F9)
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    _icon,
                    size: 18,
                    color: _tabColor(context),
                  ),
                  if (widget.tab == LessonTab.discussion && widget.discussionCount > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: widget.isSelected ? 1.0 : _scaleAnimation.value,
                            child: child,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(minWidth: 16),
                          child: Text(
                            '${widget.discussionCount}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Text(
                widget.tab.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: _tabColor(context),
                  letterSpacing: widget.isSelected ? 0.2 : 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
