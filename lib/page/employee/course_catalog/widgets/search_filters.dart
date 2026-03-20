import 'package:flutter/material.dart';
import 'package:smet/page/employee/course_catalog/widgets/course_card.dart';

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
        // Search input
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm khóa học kỹ thuật, kỹ năng mềm, hoặc lãnh đạo...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Category chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CourseCategory.values.map((category) {
            final isSelected = (selectedCategory == 'all' && category == CourseCategory.all) ||
                selectedCategory == category.name;
            return _buildCategoryChip(
              category: category,
              isSelected: isSelected,
              onTap: () => onCategoryChanged(category),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryChip({
    required CourseCategory category,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? category.color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? category.color : const Color(0xFFE5E7EB),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: category.color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category.icon.isNotEmpty) ...[
              Icon(
                _getIconData(category.icon),
                size: 16,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              category.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'code':
        return Icons.code;
      case 'forum':
        return Icons.forum;
      case 'leaderboard':
        return Icons.leaderboard;
      default:
        return Icons.category;
    }
  }
}
