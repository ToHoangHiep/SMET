import 'package:flutter/material.dart';

enum CourseFilter {
  all,
  inProgress,
  completed,
  overdue;

  String get label {
    switch (this) {
      case CourseFilter.all:
        return 'Tất cả';
      case CourseFilter.inProgress:
        return 'Đang học';
      case CourseFilter.completed:
        return 'Hoàn thành';
      case CourseFilter.overdue:
        return 'Quá hạn';
    }
  }
}

class FilterTabs extends StatelessWidget {
  final CourseFilter selected;
  final ValueChanged<CourseFilter> onChanged;

  const FilterTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: CourseFilter.values.map((filter) {
          final isActive = filter == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FilterChip(
              label: filter.label,
              isActive: isActive,
              onTap: () => onChanged(filter),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FilterChip extends StatefulWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isActive
                ? const Color(0xFF137FEC)
                : (_isHovered
                    ? const Color(0xFFEFF6FF)
                    : Colors.white),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isActive
                  ? const Color(0xFF137FEC)
                  : (_isHovered
                      ? const Color(0xFF137FEC).withValues(alpha: 0.4)
                      : const Color(0xFFF1F5F9)), // Softer border
            ),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF137FEC).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: widget.isActive
                  ? Colors.white
                  : (_isHovered
                      ? const Color(0xFF137FEC)
                      : const Color(0xFF64748B)),
            ),
          ),
        ),
      ),
    );
  }
}
