import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/core/theme/app_colors.dart';
import 'package:smet/core/utils/animations.dart';
import 'package:smet/model/learning_path_model.dart';
import 'package:smet/service/employee/lms_service.dart';

/// ─── Learning Path Page – Mobile Layout ────────────────────────────────────
///
/// Mobile-first design with bottom sheet filters, swipeable cards,
/// and full-screen tap interactions.
class EmployeeLearningPathMobile extends StatefulWidget {
  final List<LearningPathInfo> paths;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onRetry;

  const EmployeeLearningPathMobile({
    super.key,
    required this.paths,
    required this.isLoading,
    this.error,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onRetry,
  });

  @override
  State<EmployeeLearningPathMobile> createState() =>
      _EmployeeLearningPathMobileState();
}

class _EmployeeLearningPathMobileState extends State<EmployeeLearningPathMobile>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'all';
  int? _expandedIndex;
  late AnimationController _fabAnimController;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;
    _fabAnimController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fabAnimController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimController.dispose();
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
      if (mounted) {
        context.go(
          '/employee/learn/${path.id}?learningPathId=${path.id}&from=learning_path',
        );
      }
    } catch (e) {
      debugPrint('Error navigating: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────────────────────
            SliverAppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              pinned: true,
              expandedHeight: 140,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                onPressed: () => context.pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.route_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Lộ trình học tập',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Phát triển kỹ năng chuyên sâu',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Stats mini
                              _MobileMiniStats(
                                completed: widget.paths
                                    .where((p) => p.progressPercent >= 100)
                                    .length,
                                total: widget.paths.length,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Search Bar ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                    controller: _searchController,
                    onChanged: widget.onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm lộ trình...',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: AppColors.textMuted,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                widget.onSearchChanged('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Filter Chips ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _MobileFilterChip(
                        label: 'Tất cả',
                        selected: _filterStatus == 'all',
                        onTap: () => setState(() => _filterStatus = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _MobileFilterChip(
                        label: 'Đang học',
                        selected: _filterStatus == 'in_progress',
                        onTap: () => setState(() => _filterStatus = 'in_progress'),
                      ),
                      const SizedBox(width: 8),
                      _MobileFilterChip(
                        label: 'Hoàn thành',
                        selected: _filterStatus == 'completed',
                        onTap: () => setState(() => _filterStatus = 'completed'),
                      ),
                      const SizedBox(width: 8),
                      _MobileFilterChip(
                        label: 'Chưa bắt đầu',
                        selected: _filterStatus == 'not_started',
                        onTap: () => setState(() => _filterStatus = 'not_started'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Content ─────────────────────────────────────────────
            if (widget.isLoading)
              SliverFillRemaining(
                child: _buildLoading(),
              )
            else if (widget.error != null)
              SliverFillRemaining(
                child: _buildError(),
              )
            else if (_filteredPaths.isEmpty)
              SliverFillRemaining(
                child: _buildEmpty(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final path = _filteredPaths[i];
                      return _MobilePathCard(
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
                    },
                    childCount: _filteredPaths.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
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
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
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
              _filterStatus != 'all' || widget.searchQuery.isNotEmpty
                  ? 'Không có kết quả'
                  : 'Chưa có lộ trình nào',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Các lộ trình học tập sẽ xuất hiện ở đây',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _MobileMiniStats extends StatelessWidget {
  final int completed;
  final int total;

  const _MobileMiniStats({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            '$completed/$total',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MobileFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _MobilePathCard extends StatefulWidget {
  final LearningPathInfo path;
  final int index;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onToggleExpand;

  const _MobilePathCard({
    required this.path,
    required this.index,
    required this.isExpanded,
    required this.onTap,
    required this.onToggleExpand,
  });

  @override
  State<_MobilePathCard> createState() => _MobilePathCardState();
}

class _MobilePathCardState extends State<_MobilePathCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: (widget.path.progressPercent / 100).clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));
    Future.delayed(Duration(milliseconds: 100 + widget.index * 60), () {
      if (mounted) _progressController.forward();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.path;
    final progress = path.progressPercent;
    final isCompleted = progress >= 100;
    final isStarted = progress > 0;

    final statusColor = isCompleted
        ? AppColors.success
        : isStarted
            ? AppColors.primary
            : AppColors.textMuted;

    final statusBg = isCompleted
        ? AppColors.badgeGreenBg
        : isStarted
            ? AppColors.badgeBlueBg
            : AppColors.badgeGrayBg;

    final statusLabel = isCompleted
        ? 'Hoàn thành'
        : isStarted
            ? 'Đang học'
            : 'Chưa bắt đầu';

    return AnimatedFadeSlide(
      index: widget.index,
      duration: AppAnimations.standard,
      slideOffset: const Offset(0, 10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header tap area
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: isCompleted
                                ? const LinearGradient(
                                    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                                  )
                                : AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: (isCompleted
                                        ? AppColors.success
                                        : AppColors.primary)
                                    .withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.route_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Title
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                path.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${path.courseCount} khóa học · ${path.totalModules} module',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Status
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (path.description.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        path.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: widget.isExpanded ? 10 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Expand toggle
                    if (path.courses.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: widget.onToggleExpand,
                        child: Row(
                          children: [
                            AnimatedRotation(
                              turns: widget.isExpanded ? 0.5 : 0,
                              duration: AppAnimations.standard,
                              child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.isExpanded
                                  ? 'Thu gọn'
                                  : 'Xem ${path.courseCount} khóa học',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Course list (expanded)
            if (widget.isExpanded && path.courses.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgSlateLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.playlist_play_rounded,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Danh sách khóa học (${path.courses.length})',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...path.courses.asMap().entries.map((e) {
                      final i = e.key;
                      final course = e.value;
                      return _MobileTimelineItem(
                        course: course,
                        index: i,
                        isLast: i == path.courses.length - 1,
                      );
                    }),
                  ],
                ),
              ),
            ],

            // Progress bar
            Container(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Tiến độ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, _) {
                          return Text(
                            '${(_progressAnimation.value * 100).round()}%',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, _) {
                      return Stack(
                        children: [
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: _progressAnimation.value,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: isCompleted
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF22C55E),
                                          Color(0xFF16A34A),
                                        ],
                                      )
                                    : AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCompleted
                            ? AppColors.success
                            : AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isCompleted
                                ? 'Xem lại'
                                : isStarted
                                    ? 'Tiếp tục học'
                                    : 'Bắt đầu',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            isCompleted
                                ? Icons.replay_rounded
                                : isStarted
                                    ? Icons.arrow_forward_rounded
                                    : Icons.play_arrow_rounded,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileTimelineItem extends StatelessWidget {
  final CourseItemResponse course;
  final int index;
  final bool isLast;

  const _MobileTimelineItem({
    required this.course,
    required this.index,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 1.5,
                height: 28,
                color: AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.courseTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (course.mentorName != null || course.moduleCount != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (course.mentorName != null) course.mentorName,
                      if (course.moduleCount != null) '${course.moduleCount} module',
                    ].join(' · '),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
