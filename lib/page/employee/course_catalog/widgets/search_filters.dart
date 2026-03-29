import 'package:flutter/material.dart';
import 'package:smet/page/employee/course_catalog/widgets/course_card.dart';

/// Search Filters — Coursera-style:
/// - Rounded search bar with icon + clear button
/// - Pill-style category filter tabs
class SearchFilters extends StatelessWidget {
  final String selectedCategory;
  final String searchQuery;
  final ValueChanged<CourseCategory> onCategoryChanged;
  final ValueChanged<String> onSearchChanged;

  const SearchFilters({
    super.key,
    required this.selectedCategory,
    required this.searchQuery,
    required this.onCategoryChanged,
    required this.onSearchChanged,
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

        // Category filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: CourseCategory.values.map((category) {
              final isSelected = (selectedCategory == 'all' &&
                      category == CourseCategory.all) ||
                  selectedCategory == category.name;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _CategoryPill(
                  category: category,
                  isSelected: isSelected,
                  onTap: () => onCategoryChanged(category),
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

/// Pill-style category chip with animated state.
class _CategoryPill extends StatefulWidget {
  final CourseCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CategoryPill> createState() => _CategoryPillState();
}

class _CategoryPillState extends State<_CategoryPill> {
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? const Color(0xFF137FEC)
                : (_isHovered
                    ? const Color(0xFFF8FAFC)
                    : Colors.white),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isSelected
                  ? const Color(0xFF137FEC)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Text(
            widget.category.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w600,
              color: widget.isSelected
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
