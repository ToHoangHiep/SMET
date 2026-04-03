import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/core/theme/app_colors.dart';
import 'package:smet/core/utils/animations.dart';
import 'package:smet/page/employee/widgets/shell/employee_top_header.dart';
import 'package:smet/page/employee/learning_path/widgets/learning_path_card.dart';
import 'package:smet/service/employee/lms_service.dart';

/// ─── Learning Path Page – Web Layout ─────────────────────────────────────
///
/// Responsive two-column layout: stats sidebar + scrollable path cards.
class EmployeeLearningPathWeb extends StatefulWidget {
  final List<LearningPathInfo> paths;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final List<BreadcrumbItem>? breadcrumbs;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onRetry;

  const EmployeeLearningPathWeb({
    super.key,
    required this.paths,
    required this.isLoading,
    this.error,
    required this.searchQuery,
    this.breadcrumbs,
    required this.onSearchChanged,
    required this.onRetry,
  });

  @override
  State<EmployeeLearningPathWeb> createState() =>
      _EmployeeLearningPathWebState();
}

class _EmployeeLearningPathWebState extends State<EmployeeLearningPathWeb>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'all';
  int? _expandedIndex;
  late AnimationController _headerAnimController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;
    _headerAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _headerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerAnimController, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _headerAnimController, curve: Curves.easeOutCubic),
    );
    _headerAnimController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _headerAnimController.dispose();
    super.dispose();
  }

  List<LearningPathInfo> get _filteredPaths {
    var list = widget.paths;
    if (_filterStatus == 'completed') {
      list = list.where((p) => p.progressPercent >= 100).toList();
    } else if (_filterStatus == 'in_progress') {
      list = list.where((p) => p.progressPercent > 0 && p.progressPercent < 100).toList();
    } else if (_filterStatus == 'not_started') {
      list = list.where((p) => p.progressPercent == 0).toList();
    }
    return list;
  }

  Future<void> _navigateToPath(LearningPathInfo path) async {
    try {
      final detail = await LmsService.getLearningPathDetail(path.id);
      if (detail != null && detail.courses.isNotEmpty && mounted) {
        context.go(
          '/employee/learn/${detail.courses.first.id}?learningPathId=${path.id}&from=learning_path',
        );
      }
    } catch (e) {
      debugPrint('Error navigating: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        EmployeeTopHeader(
          currentPage: 'Lộ trình học tập',
          breadcrumbs: widget.breadcrumbs,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 28, 32, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero Banner ──────────────────────────────────────
                FadeTransition(
                  opacity: _headerFade,
                  child: SlideTransition(
                    position: _headerSlide,
                    child: _HeroBanner(
                      totalPaths: widget.paths.length,
                      completedPaths: widget.paths
                          .where((p) => p.progressPercent >= 100)
                          .length,
                      inProgressPaths: widget.paths
                          .where((p) => p.progressPercent > 0)
                          .length,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Search + Filter Row ─────────────────────────────
                FadeTransition(
                  opacity: _headerFade,
                  child: SlideTransition(
                    position: _headerSlide,
                    child: _SearchAndFilterRow(
                      controller: _searchController,
                      filterStatus: _filterStatus,
                      onSearchChanged: widget.onSearchChanged,
                      onFilterChanged: (v) => setState(() => _filterStatus = v),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Content Area ────────────────────────────────────
                if (widget.isLoading)
                  _buildLoading()
                else if (widget.error != null)
                  _buildError()
                else if (_filteredPaths.isEmpty)
                  _buildEmpty()
                else
                  _buildPathsGrid(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return const SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Đang tải lộ trình học tập...',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.badgeRedBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.error ?? 'Đã xảy ra lỗi',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Vui lòng thử lại sau',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: widget.onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.badgeGrayBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.route_rounded,
                color: AppColors.textMuted,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _filterStatus != 'all'
                  ? 'Không có lộ trình nào phù hợp'
                  : widget.searchQuery.isNotEmpty
                      ? 'Không tìm thấy lộ trình'
                      : 'Chưa có lộ trình nào được giao',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _filterStatus != 'all'
                  ? 'Thử thay đổi bộ lọc hoặc tìm kiếm từ khóa khác'
                  : widget.searchQuery.isNotEmpty
                      ? 'Hãy thử từ khóa khác'
                      : 'Các lộ trình học tập sẽ xuất hiện ở đây khi được giao',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPathsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Text(
                '${_filteredPaths.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                _filterStatus != 'all' || widget.searchQuery.isNotEmpty
                    ? ' kết quả'
                    : ' lộ trình học tập',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        ...List.generate(_filteredPaths.length, (i) {
          final path = _filteredPaths[i];
          return LearningPathCard(
            key: ValueKey('path-${path.id}'),
            path: path,
            index: i,
            isExpanded: _expandedIndex == i,
            onTap: () => _navigateToPath(path),
            onToggleExpand: () {
              setState(() {
                _expandedIndex = _expandedIndex == i ? null : i;
              });
            },
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── Hero Banner ─────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final int totalPaths;
  final int completedPaths;
  final int inProgressPaths;

  const _HeroBanner({
    required this.totalPaths,
    required this.completedPaths,
    required this.inProgressPaths,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.route_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lộ trình học tập',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Theo dõi và quản lý hành trình phát triển của bạn',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _StatPill(
                      icon: Icons.layers_rounded,
                      value: '$totalPaths',
                      label: 'Tổng lộ trình',
                      bgColor: Colors.white.withValues(alpha: 0.15),
                    ),
                    const SizedBox(width: 12),
                    _StatPill(
                      icon: Icons.play_circle_rounded,
                      value: '$inProgressPaths',
                      label: 'Đang học',
                      bgColor: Colors.white.withValues(alpha: 0.15),
                    ),
                    const SizedBox(width: 12),
                    _StatPill(
                      icon: Icons.check_circle_rounded,
                      value: '$completedPaths',
                      label: 'Hoàn thành',
                      bgColor: const Color(0xFF22C55E).withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Right: illustration
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const SizedBox(
              width: 64,
              height: 64,
              child: Icon(
                Icons.school_rounded,
                color: Colors.white70,
                size: 36,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color bgColor;

  const _StatPill({
    required this.icon,
    required this.value,
    required this.label,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Search + Filter ──────────────────────────────────────────────────────────

class _SearchAndFilterRow extends StatelessWidget {
  final TextEditingController controller;
  final String filterStatus;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterChanged;

  const _SearchAndFilterRow({
    required this.controller,
    required this.filterStatus,
    required this.onSearchChanged,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Search field
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm lộ trình học tập...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () {
                          controller.clear();
                          onSearchChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Filter chips
        Row(
          children: [
            _FilterChip(
              label: 'Tất cả',
              value: 'all',
              selected: filterStatus == 'all',
              onTap: () => onFilterChanged('all'),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Đang học',
              value: 'in_progress',
              selected: filterStatus == 'in_progress',
              onTap: () => onFilterChanged('in_progress'),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Hoàn thành',
              value: 'completed',
              selected: filterStatus == 'completed',
              onTap: () => onFilterChanged('completed'),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterChip extends StatefulWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
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
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.primary
                : _isHovered
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.selected
                  ? AppColors.primary
                  : _isHovered
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : AppColors.border,
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: widget.selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
