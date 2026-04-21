import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/service/mentor/course_service.dart';
import 'package:smet/service/common/auth_service.dart';

/// Mentor Course - Web Layout (Danh sách khóa học) — Giao diện mềm mại, hiện đại.
class MentorCourseWeb extends StatefulWidget {
  const MentorCourseWeb({super.key});

  @override
  State<MentorCourseWeb> createState() => _MentorCourseWebState();
}

class _MentorCourseWebState extends State<MentorCourseWeb>
    with SingleTickerProviderStateMixin {
  static const _primary = Color(0xFF6366F1);
  static const _primaryLight = Color(0xFF818CF8);
  static const _bgLight = Color(0xFFF3F6FC);
  static const _cardBorder = Color(0xFFE8ECF4);
  static const _textDark = Color(0xFF0F172A);
  static const _textMedium = Color(0xFF64748B);
  static const _success = Color(0xFF22C55E);
  static const _warning = Color(0xFFF59E0B);
  static const _danger = Color(0xFFEF4444);

  final MentorCourseService _service = MentorCourseService();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<CourseResponse> _courses = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedFilter = 'ALL';
  String _listScope = 'DEPT_ALL';

  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  final int _pageSize = 9;

  final _searchController = TextEditingController();

  int? get _currentUserId => AuthService.currentUserCached?.id;
  bool? get _isMineQueryParam => _listScope == 'MINE' ? true : null;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadCourses();
    _fadeController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uri = GoRouterState.of(context).uri;
      if (uri.queryParameters.containsKey('refresh')) {
        _loadCourses(page: _currentPage);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses({int page = 0}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = page;
    });

    try {
      String? status;
      if (_selectedFilter == 'PUBLISHED') {
        status = 'PUBLISHED';
      } else if (_selectedFilter == 'DRAFT') {
        status = 'DRAFT';
      } else if (_selectedFilter == 'ARCHIVED') {
        status = 'ARCHIVED';
      }

      final result = await _service.listCourses(
        keyword: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: status,
        isMine: _isMineQueryParam,
        page: page,
        size: _pageSize,
      );

      setState(() {
        _courses = result.content;
        _totalPages = result.totalPages;
        _totalElements = result.totalElements;
        _isLoading = false;
      });
      _fadeController.forward(from: 0);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onFilterChanged(String filter) {
    setState(() => _selectedFilter = filter);
    _loadCourses();
  }

  void _onListScopeChanged(String scope) {
    setState(() => _listScope = scope);
    _loadCourses();
  }

  void _onSearch(String query) {
    _searchQuery = query;
    _loadCourses();
  }

  void _goToPage(int page) {
    if (page >= 0 && page < _totalPages) {
      _loadCourses(page: page);
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    int crossAxisCount = 3;
    if (width > 1600) {
      crossAxisCount = 4;
    } else if (width < 1200) {
      crossAxisCount = 2;
    }

    return Scaffold(
      backgroundColor: _bgLight,
      body: Column(
        children: [
          // ─── PAGE HEADER ───
          Container(
            margin: const EdgeInsets.fromLTRB(30, 30, 30, 0),
            child: BreadcrumbPageHeader(
              pageTitle: "Quản lý khóa học",
              pageIcon: Icons.menu_book_rounded,
              breadcrumbs: const [
                BreadcrumbItem(label: "Mentor", route: "/mentor/dashboard"),
                BreadcrumbItem(label: "Khóa học"),
              ],
              primaryColor: _primary,
              actions: [
                ElevatedButton.icon(
                  onPressed: () => context.go('/mentor/courses/create'),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text("Tạo khóa học mới"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
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
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── FILTER BAR ───
                  _buildFilterBar(),
                  const SizedBox(height: 24),

                  // ─── COURSE GRID ───
                  Expanded(child: _buildContent(crossAxisCount)),
                  const SizedBox(height: 10),

                  // ─── PAGINATION ───
                  if (!_isLoading) _buildPagination(),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _scopeChip("DEPT_ALL", "Tất cả khóa học"),
              _scopeChip("MINE", "Khóa của tôi"),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: _cardBorder.withValues(alpha: 0.6)),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _searchController,
                  onSubmitted: _onSearch,
                  decoration: InputDecoration(
                    hintText: "Tìm kiếm khóa học...",
                    hintStyle: TextStyle(color: _textMedium.withValues(alpha: 0.8)),
                    prefixIcon: Icon(Icons.search, color: _textMedium, size: 22),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _filterChip("ALL"),
              _filterChip("PUBLISHED"),
              _filterChip("DRAFT"),
              _filterChip("ARCHIVED"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scopeChip(String value, String title) {
    final selected = _listScope == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(title),
        selected: selected,
        showCheckmark: true,
        checkmarkColor: _primary,
        selectedColor: _primary.withValues(alpha: 0.12),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: selected ? _primary.withValues(alpha: 0.35) : _cardBorder,
        ),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? _primary : _textMedium,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        onSelected: (v) {
          if (v) _onListScopeChanged(value);
        },
      ),
    );
  }

  Widget _filterChip(String label) {
    final selected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(_filterLabel(label)),
        selected: selected,
        showCheckmark: true,
        checkmarkColor: _primary,
        selectedColor: _primary.withValues(alpha: 0.12),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: selected ? _primary.withValues(alpha: 0.35) : _cardBorder,
        ),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? _primary : _textMedium,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        onSelected: (value) {
          if (value) _onFilterChanged(label);
        },
      ),
    );
  }

  String _filterLabel(String label) {
    switch (label) {
      case 'ALL': return 'Tất cả';
      case 'PUBLISHED': return 'Đã xuất bản';
      case 'DRAFT': return 'Bản nháp';
      case 'ARCHIVED': return 'Đã lưu trữ';
      default: return label;
    }
  }

  Widget _buildContent(int crossAxisCount) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: _primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _danger.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, size: 36, color: _danger),
            ),
            const SizedBox(height: 20),
            Text(_error!, style: const TextStyle(color: _danger, fontSize: 14)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _loadCourses(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text("Thử lại"),
            ),
          ],
        ),
      );
    }

    if (_courses.isEmpty) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 1.3,
        ),
        itemCount: _courses.length,
        itemBuilder: (context, index) => _buildCourseCard(_courses[index], index),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasFilters = _searchQuery.isNotEmpty || _selectedFilter != 'ALL';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated illustration
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _primary.withValues(alpha: 0.12),
                  _primaryLight.withValues(alpha: 0.06),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _primary.withValues(alpha: 0.08),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(
              hasFilters ? Icons.search_off_rounded : Icons.menu_book_rounded,
              size: 44,
              color: _primary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            hasFilters ? "Không tìm thấy khóa học" : "Chưa có khóa học nào",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 340,
            child: Text(
              hasFilters
                  ? "Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm để xem kết quả khác."
                  : "Bắt đầu tạo khóa học đầu tiên để chia sẻ kiến thức với học viên.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: _textMedium, height: 1.5),
            ),
          ),
          const SizedBox(height: 32),
          if (!hasFilters)
            ElevatedButton.icon(
              onPressed: () => context.go('/mentor/courses/create'),
              icon: const Icon(Icons.add, size: 20),
              label: const Text("Tạo khóa học đầu tiên"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(CourseResponse course, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 60).clamp(0, 300)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        );
      },
      child: _CourseCardContent(
        course: course,
        primary: _primary,
        primaryLight: _primaryLight,
        textDark: _textDark,
        textMedium: _textMedium,
        cardBorder: _cardBorder,
        success: _success,
        warning: _warning,
        danger: _danger,
        onTap: () => context.go(
          '/mentor/courses/${course.id.value}?title=${Uri.encodeComponent(course.title)}',
        ),
        isOwner: _isOwner(course),
      ),
    );
  }

  bool _isOwner(CourseResponse course) =>
      _currentUserId != null && course.mentorId.value == _currentUserId;

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _pageButton(
          icon: Icons.chevron_left,
          onPressed: _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
        ),
        const SizedBox(width: 8),
        ...List.generate(
          _totalPages > 5 ? 5 : _totalPages,
          (index) {
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
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isCurrent ? _primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "${pageNum + 1}",
                    style: TextStyle(
                      color: isCurrent ? Colors.white : _textMedium,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        _pageButton(
          icon: Icons.chevron_right,
          onPressed: _currentPage < _totalPages - 1 ? () => _goToPage(_currentPage + 1) : null,
        ),
        const SizedBox(width: 16),
        Text(
          "$_totalElements khóa học",
          style: const TextStyle(fontSize: 12, color: _textMedium),
        ),
      ],
    );
  }

  Widget _pageButton({required IconData icon, VoidCallback? onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onPressed != null ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _cardBorder),
        ),
        child: Icon(
          icon,
          size: 20,
          color: onPressed != null ? _textMedium : _cardBorder,
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// Nội dung card khóa học — được tách riêng để code gọn hơn
/// ─────────────────────────────────────────────────────────────
class _CourseCardContent extends StatefulWidget {
  final CourseResponse course;
  final Color primary;
  final Color primaryLight;
  final Color textDark;
  final Color textMedium;
  final Color cardBorder;
  final Color success;
  final Color warning;
  final Color danger;
  final VoidCallback onTap;
  final bool isOwner;

  const _CourseCardContent({
    required this.course,
    required this.primary,
    required this.primaryLight,
    required this.textDark,
    required this.textMedium,
    required this.cardBorder,
    required this.success,
    required this.warning,
    required this.danger,
    required this.onTap,
    required this.isOwner,
  });

  @override
  State<_CourseCardContent> createState() => _CourseCardContentState();
}

class _CourseCardContentState extends State<_CourseCardContent> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final course = widget.course;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered
                ? widget.primary.withValues(alpha: 0.25)
                : widget.cardBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? widget.primary.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: _isHovered ? 20 : 14,
              offset: Offset(0, _isHovered ? 8 : 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── HEADER ROW ──
                  Row(
                    children: [
                      _statusBadge(course.status),
                      const SizedBox(width: 6),
                      _ownershipBadge(course),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── COURSE IMAGE PLACEHOLDER (gradient) ──
                  Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.primary.withValues(alpha: _randomGradient(course.id.value)[0]),
                          widget.primaryLight.withValues(alpha: _randomGradient(course.id.value)[1]),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Decorative circles
                        Positioned(
                          right: -10,
                          bottom: -10,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 10,
                          top: 10,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                        ),
                        // Icon
                        Center(
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── TITLE ──
                  Text(
                    course.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: widget.textDark,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // ── DESCRIPTION ──
                  Expanded(
                    child: Text(
                      (course.description ?? '').isEmpty
                          ? "Không có mô tả"
                          : course.description!,
                      style: TextStyle(fontSize: 12, color: widget.textMedium, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // ── STATS BAR ──
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        _statItem(Icons.folder_outlined, "${course.moduleCount} chương"),
                        const SizedBox(width: 12),
                        _statItem(Icons.play_lesson_outlined, "${course.lessonCount} bài"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<double> _randomGradient(int seed) {
    final gradients = [
      [0.5, 0.3],
      [0.45, 0.25],
      [0.55, 0.35],
      [0.4, 0.2],
    ];
    return gradients[seed % gradients.length];
  }

  Widget _statusBadge(String status) {
    Color color;
    Color bgColor;
    String label;
    IconData icon;

    switch (status.toUpperCase()) {
      case 'PUBLISHED':
        color = widget.success;
        bgColor = widget.success.withValues(alpha: 0.1);
        label = 'Đã xuất bản';
        icon = Icons.check_circle_outline;
        break;
      case 'ARCHIVED':
        color = widget.textMedium;
        bgColor = widget.textMedium.withValues(alpha: 0.1);
        label = 'Đã lưu trữ';
        icon = Icons.archive_outlined;
        break;
      default:
        color = widget.warning;
        bgColor = widget.warning.withValues(alpha: 0.1);
        label = 'Bản nháp';
        icon = Icons.edit_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ownershipBadge(CourseResponse course) {
    final isOwner = widget.isOwner;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isOwner
            ? widget.primary.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOwner ? Icons.person : Icons.people,
            size: 11,
            color: isOwner ? widget.primary : Colors.grey,
          ),
          const SizedBox(width: 3),
          Text(
            isOwner ? 'Của bạn' : 'Mentor khác',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isOwner ? widget.primary : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: widget.textMedium),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: widget.textMedium, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
