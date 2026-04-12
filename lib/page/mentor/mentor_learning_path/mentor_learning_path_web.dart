import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/core/theme/app_colors.dart';
import 'package:smet/core/utils/animations.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/model/learning_path_model.dart';
import 'package:smet/service/mentor/learning_path_service.dart';
import 'package:smet/service/common/global_notification_service.dart';

/// Mentor Learning Path - Web Layout
/// Nâng cấp UI: Hero banner, animations, hover effects, filter chips, modern table.
class MentorLearningPathWeb extends StatefulWidget {
  const MentorLearningPathWeb({super.key});

  @override
  State<MentorLearningPathWeb> createState() => _MentorLearningPathWebState();
}

class _MentorLearningPathWebState extends State<MentorLearningPathWeb>
    with SingleTickerProviderStateMixin {
  final LearningPathService _service = LearningPathService();
  String? _lastRefresh;
  List<LearningPathResponse> _paths = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _filterStatus = 'all';
  bool _showMyPaths = false;

  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  static const int _pageSize = 10;

  late AnimationController _headerAnimController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _headerAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _headerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerAnimController, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _headerAnimController, curve: Curves.easeOutCubic),
    );
    _headerAnimController.forward();
    _loadLearningPaths();
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final refresh = GoRouterState.of(context).uri.queryParameters['refresh'];
    if (refresh != null && refresh != _lastRefresh) {
      _lastRefresh = refresh;
      _loadLearningPaths(page: 0);
    }
  }

  Future<void> _loadLearningPaths({int page = 0}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = page;
    });

    try {
      final result = await _service.getAllLearningPaths(
        keyword: _searchQuery.isEmpty ? null : _searchQuery,
        page: page,
        size: _pageSize,
        assignedToMe: _showMyPaths ? true : null,
      );
      setState(() {
        _paths = result.content;
        _totalPages = result.totalPages;
        _totalElements = result.totalElements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearch(String value) {
    setState(() => _searchQuery = value);
    _loadLearningPaths(page: 0);
  }

  void _goToPage(int page) {
    if (page < 0 || page >= _totalPages) return;
    _loadLearningPaths(page: page);
  }

  List<LearningPathResponse> get _displayPaths {
    if (_filterStatus == 'many') {
      return _paths.where((p) => p.courseCount >= 3).toList();
    } else if (_filterStatus == 'few') {
      return _paths.where((p) => p.courseCount < 3).toList();
    }
    return _paths;
  }

  Future<void> _deletePath(Long pathId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.badgeRedBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 12),
            const Text("Xóa lộ trình",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Bạn có chắc chắn muốn xóa lộ trình học tập này không?\nHành động này không thể hoàn tác.",
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteLearningPath(pathId);
        _loadLearningPaths(page: _currentPage);
        GlobalNotificationService.show(
          context: context,
          message: 'Xóa lộ trình thành công',
          type: NotificationType.success,
        );
      } catch (e) {
        GlobalNotificationService.show(
          context: context,
          message: e.toString(),
          type: NotificationType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Column(
        children: [
          /// Animated Page Header
          FadeTransition(
            opacity: _headerFade,
            child: SlideTransition(
              position: _headerSlide,
              child: Container(
                margin: const EdgeInsets.fromLTRB(30, 30, 30, 0),
                child: _buildPageHeader(),
              ),
            ),
          ),

          /// Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Hero Stats Banner
                  FadeTransition(
                    opacity: _headerFade,
                    child: SlideTransition(
                      position: _headerSlide,
                      child: _buildHeroBanner(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// Search + Filter Bar
                  _buildSearchFilterBar(),

                  const SizedBox(height: 20),

                  /// Table / Content
                  Expanded(child: _buildContent()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.route_rounded,
                color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SharedBreadcrumb(
                  items: const [
                    BreadcrumbItem(label: "Mentor", route: "/mentor/dashboard"),
                    BreadcrumbItem(label: "Lộ trình học tập"),
                  ],
                  primaryColor: AppColors.primary,
                  fontSize: 13,
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Quản lý lộ trình học tập',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => context.go('/mentor/learning-paths/create'),
            icon: const Icon(Icons.add, size: 20),
            label: const Text("Tạo lộ trình mới"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    final totalCourses = _paths.fold(0, (sum, p) => sum + p.courseCount);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.route_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lộ trình học tập',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Theo dõi và quản lý lộ trình học tập của bạn',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _StatCard(
                      icon: Icons.layers_rounded,
                      value: '$_totalElements',
                      label: 'Tổng lộ trình',
                      bgColor: Colors.white.withValues(alpha: 0.15),
                    ),
                    const SizedBox(width: 14),
                    _StatCard(
                      icon: Icons.menu_book_rounded,
                      value: '$totalCourses',
                      label: 'Khóa học đã thêm',
                      bgColor: Colors.white.withValues(alpha: 0.15),
                    ),
                    const SizedBox(width: 14),
                    _StatCard(
                      icon: Icons.play_circle_rounded,
                      value: '${_paths.where((p) => p.courseCount > 0).length}',
                      label: 'Đang hoạt động',
                      bgColor: const Color(0xFF22C55E).withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const SizedBox(
              width: 56,
              height: 56,
              child: Icon(
                Icons.school_rounded,
                color: Colors.white70,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          /// Search field
          Expanded(
            child: SizedBox(
              height: 46,
              child: TextField(
                controller: _searchController,
                onSubmitted: _onSearch,
                onChanged: _onSearch,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Tìm kiếm lộ trình học tập...",
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  prefixIcon:
                      Icon(Icons.search, color: AppColors.textMuted, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              size: 18, color: AppColors.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.bgSlateLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          /// Filter chips
          Row(
            children: [
              _WebFilterChip(
                label: 'Tất cả',
                value: 'all',
                selected: _filterStatus == 'all' && !_showMyPaths,
                onTap: () {
                  setState(() {
                    _filterStatus = 'all';
                    _showMyPaths = false;
                  });
                  _loadLearningPaths(page: 0);
                },
              ),
              const SizedBox(width: 8),
              _WebFilterChip(
                label: 'Của tôi',
                value: 'mine',
                selected: _showMyPaths,
                onTap: () {
                  setState(() {
                    _filterStatus = 'all';
                    _showMyPaths = true;
                  });
                  _loadLearningPaths(page: 0);
                },
              ),
              const SizedBox(width: 8),
              _WebFilterChip(
                label: 'Nhiều khóa học',
                value: 'many',
                selected: _filterStatus == 'many',
                onTap: () {
                  setState(() {
                    _filterStatus = 'many';
                    _showMyPaths = false;
                  });
                  _loadLearningPaths(page: 0);
                },
              ),
              const SizedBox(width: 8),
              _WebFilterChip(
                label: 'Ít khóa học',
                value: 'few',
                selected: _filterStatus == 'few',
                onTap: () {
                  setState(() {
                    _filterStatus = 'few';
                    _showMyPaths = false;
                  });
                  _loadLearningPaths(page: 0);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoading();
    }

    if (_error != null) {
      return _buildError();
    }

    if (_displayPaths.isEmpty) {
      return _buildEmpty();
    }

    return Column(
      children: [
        Expanded(child: _buildTable()),
        const SizedBox(height: 16),
        _buildPagination(),
      ],
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) => _SkeletonRow(index: index),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.badgeRedBg,
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.error_outline_rounded, size: 36, color: AppColors.error),
          ),
          const SizedBox(height: 20),
          const Text(
            'Đã xảy ra lỗi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? '',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _loadLearningPaths(page: _currentPage),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.primary.withValues(alpha: 0.04),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.route_rounded,
                size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty || _filterStatus != 'all' || _showMyPaths
                ? 'Không tìm thấy lộ trình phù hợp'
                : 'Chưa có lộ trình học tập nào',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 340,
            child: Text(
              _searchQuery.isNotEmpty || _filterStatus != 'all' || _showMyPaths
                  ? 'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm'
                  : 'Tạo lộ trình học tập đầu tiên để bắt đầu',
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ),
          if (_searchQuery.isEmpty && _filterStatus == 'all' && !_showMyPaths) ...[
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => context.go('/mentor/learning-paths/create'),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Tạo lộ trình đầu tiên'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          /// Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.04),
                  AppColors.primary.withValues(alpha: 0.02),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: const [
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      Icon(Icons.route_rounded,
                          size: 16, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        "Lộ trình",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.textDark),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Icon(Icons.description_outlined,
                          size: 16, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        "Mô tả",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.textDark),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    "Khóa học",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textDark),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    "Bài học",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textDark),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Hành động",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textDark),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          /// Table Rows
          Expanded(
            child: ListView.separated(
              itemCount: _displayPaths.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: AppColors.borderLight),
              itemBuilder: (context, index) {
                final path = _displayPaths[index];
                return AnimatedFadeSlide(
                  index: index,
                  duration: AppAnimations.standard,
                  slideOffset: const Offset(0, 8),
                  child: _buildRow(path),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(LearningPathResponse path) {
    return _TableRow(
      path: path,
      onEdit: () =>
          context.go('/mentor/learning-paths/create?edit=${path.id.value}'),
      onDelete: () => _deletePath(path.id),
    );
  }

  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed:
              _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
          icon: const Icon(Icons.chevron_left),
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        ...List.generate(_totalPages > 5 ? 5 : _totalPages, (index) {
          int pageNum;
          if (_totalPages > 5) {
            if (_currentPage < 3) {
              pageNum = index;
            } else if (_currentPage > _totalPages - 3) {
              pageNum = _totalPages - 5 + index;
            } else {
              pageNum = _currentPage - 2 + index;
            }
          } else {
            pageNum = index;
          }
          final isCurrent = pageNum == _currentPage;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              onTap: () => _goToPage(pageNum),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCurrent
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
                child: Text(
                  "${pageNum + 1}",
                  style: TextStyle(
                    color: isCurrent ? Colors.white : AppColors.textSecondary,
                    fontWeight:
                        isCurrent ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 4),
        IconButton(
          onPressed: _currentPage < _totalPages - 1
              ? () => _goToPage(_currentPage + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 16),
        Text(
          "$_totalElements lộ trình",
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

// ─── Table Row ───────────────────────────────────────────────────────────────

class _TableRow extends StatefulWidget {
  final LearningPathResponse path;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TableRow({
    required this.path,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        color: _isHovered
            ? AppColors.primary.withValues(alpha: 0.03)
            : Colors.transparent,
        child: Row(
          children: [
            /// TITLE + COURSE PREVIEW
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.route_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.path.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (widget.path.courses.isNotEmpty)
                          SizedBox(
                            width: 200,
                            child: Text(
                              widget.path.courses
                                  .take(2)
                                  .map((c) => c.courseTitle)
                                  .join(' · '),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// DESCRIPTION
            Expanded(
              flex: 3,
              child: Text(
                widget.path.description.isEmpty
                    ? "—"
                    : widget.path.description,
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            /// COURSE COUNT
            Expanded(
              flex: 1,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${widget.path.courseCount}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),

            /// MODULE COUNT
            Expanded(
              flex: 1,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${widget.path.totalModules}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.accentPurple,
                    ),
                  ),
                ),
              ),
            ),

            /// ACTIONS
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionButton(
                    icon: Icons.edit_outlined,
                    tooltip: "Chỉnh sửa",
                    color: AppColors.primary,
                    hoveredColor: AppColors.primary.withValues(alpha: 0.1),
                    onTap: widget.onEdit,
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.delete_outline,
                    tooltip: "Xóa",
                    color: AppColors.error,
                    hoveredColor: AppColors.badgeRedBg,
                    onTap: widget.onDelete,
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

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final Color hoveredColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.hoveredColor,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: AppAnimations.fast,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isHovered ? widget.hoveredColor : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isHovered
                    ? widget.color.withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
            ),
            child: Icon(widget.icon, size: 18, color: widget.color),
          ),
        ),
      ),
    );
  }
}

// ─── Sub-widgets ────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color bgColor;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 6),
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

class _WebFilterChip extends StatefulWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _WebFilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_WebFilterChip> createState() => _WebFilterChipState();
}

class _WebFilterChipState extends State<_WebFilterChip> {
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
              color: widget.selected
                  ? Colors.white
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonRow extends StatefulWidget {
  final int index;

  const _SkeletonRow({required this.index});

  @override
  State<_SkeletonRow> createState() => _SkeletonRowState();
}

class _SkeletonRowState extends State<_SkeletonRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.borderLight)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: _animation.value),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 12,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: _animation.value),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 10,
                            width: 120,
                            decoration: BoxDecoration(
                              color:
                                  Colors.grey.withValues(alpha: _animation.value * 0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: _animation.value * 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const Expanded(child: SizedBox(width: 20)),
              const Expanded(child: SizedBox(width: 20)),
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: _animation.value * 0.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: _animation.value * 0.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
