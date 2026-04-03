import 'package:flutter/material.dart';

/// Enrollment filter — lọc khóa học theo trạng thái đăng ký của user
enum EnrollmentFilter { all, inProgress, completed }

extension EnrollmentFilterExtension on EnrollmentFilter {
  String get label {
    switch (this) {
      case EnrollmentFilter.all:
        return 'Tất cả';
      case EnrollmentFilter.inProgress:
        return 'Đang học';
      case EnrollmentFilter.completed:
        return 'Đã hoàn thành';
    }
  }

  String? get apiValue {
    switch (this) {
      case EnrollmentFilter.all:
        return null;
      case EnrollmentFilter.inProgress:
        return 'IN_PROGRESS';
      case EnrollmentFilter.completed:
        return 'COMPLETED';
    }
  }
}

/// Search Filters — Coursera-style:
/// - Rounded search bar with icon + clear button
/// - Pill-style enrollment filter row
class SearchFilters extends StatelessWidget {
  final String searchQuery;
  final EnrollmentFilter selectedEnrollment;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<EnrollmentFilter> onEnrollmentChanged;

  const SearchFilters({
    super.key,
    required this.searchQuery,
    required this.selectedEnrollment,
    required this.onSearchChanged,
    required this.onEnrollmentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search input — rounded, full-featured
        _CourseraSearchBar(
          initialValue: searchQuery,
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 14),

        // Enrollment filter pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: EnrollmentFilter.values.map((filter) {
              final isSelected = selectedEnrollment == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _EnrollmentPill(
                  filter: filter,
                  isSelected: isSelected,
                  onTap: () => onEnrollmentChanged(filter),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Rounded search bar with Coursera styling.
class _CourseraSearchBar extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _CourseraSearchBar({
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_CourseraSearchBar> createState() => _CourseraSearchBarState();
}

class _CourseraSearchBarState extends State<_CourseraSearchBar> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _hasText = widget.initialValue.isNotEmpty;
    _controller.addListener(() {
      final hasText = _controller.text.isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm khóa học...',
          hintStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF94A3B8),
            size: 20,
          ),
          suffixIcon: _hasText
              ? IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFF94A3B8),
                    size: 18,
                  ),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

/// Pill-style enrollment filter chip with animated state.
class _EnrollmentPill extends StatefulWidget {
  final EnrollmentFilter filter;
  final bool isSelected;
  final VoidCallback onTap;

  const _EnrollmentPill({
    required this.filter,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_EnrollmentPill> createState() => _EnrollmentPillState();
}

class _EnrollmentPillState extends State<_EnrollmentPill> {
  bool _isHovered = false;

  Color get _activeColor {
    switch (widget.filter) {
      case EnrollmentFilter.inProgress:
        return const Color(0xFFF59E0B);
      case EnrollmentFilter.completed:
        return const Color(0xFF22C55E);
      case EnrollmentFilter.all:
        return const Color(0xFF137FEC);
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? _activeColor
                : (_isHovered
                    ? const Color(0xFFF8FAFC)
                    : Colors.white),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isSelected
                  ? _activeColor
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Text(
            widget.filter.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w600,
              color: widget.isSelected
                  ? Colors.white
                  : (_isHovered
                      ? _activeColor
                      : const Color(0xFF64748B)),
            ),
          ),
        ),
      ),
    );
  }
}
