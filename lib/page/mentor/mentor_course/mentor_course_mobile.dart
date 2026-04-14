import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/service/mentor/course_service.dart';
import 'package:smet/service/common/auth_service.dart';
import 'package:smet/service/common/global_notification_service.dart';

/// Mentor Course - Mobile Layout (Danh sách khóa học)
/// UI mềm mại, hiện đại với gradient cards và animations.
class MentorCourseMobile extends StatefulWidget {
  const MentorCourseMobile({super.key});

  @override
  State<MentorCourseMobile> createState() => _MentorCourseMobileState();
}

class _MentorCourseMobileState extends State<MentorCourseMobile>
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

  List<CourseResponse> _courses = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedFilter = 'ALL';
  String _listScope = 'DEPT_ALL';

  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  final int _pageSize = 10;
  bool _isLoadingMore = false;

  final _searchController = TextEditingController();

  int? get _currentUserId => AuthService.currentUserCached?.id;
  bool? get _isMineQueryParam => _listScope == 'MINE' ? true : null;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses({int page = 0}) async {
    setState(() {
      if (page == 0) {
        _isLoading = true;
        _error = null;
      }
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
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMoreCourses() async {
    if (_isLoadingMore || _currentPage >= _totalPages - 1) return;

    setState(() => _isLoadingMore = true);

    try {
      String? status;
      if (_selectedFilter == 'PUBLISHED') status = 'PUBLISHED';
      else if (_selectedFilter == 'DRAFT') status = 'DRAFT';
      else if (_selectedFilter == 'ARCHIVED') status = 'ARCHIVED';

      final result = await _service.listCourses(
        keyword: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: status,
        isMine: _isMineQueryParam,
        page: _currentPage + 1,
        size: _pageSize,
      );

      setState(() {
        _courses = [..._courses, ...result.content];
        _currentPage = result.number;
        _totalPages = result.totalPages;
        _totalElements = result.totalElements;
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint('Error loading more courses: $e');
      setState(() => _isLoadingMore = false);
    }
  }

  void _onFilterChanged(String filter) {
    setState(() => _selectedFilter = filter);
    _loadCourses(page: 0);
  }

  void _onListScopeChanged(String scope) {
    setState(() => _listScope = scope);
    _loadCourses(page: 0);
  }

  Future<void> _deleteCourse(CourseResponse course) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: _danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.delete_outline, color: _danger, size: 20),
            ),
            const SizedBox(width: 12),
            const Text("Xóa khóa học"),
          ],
        ),
        content: Text("Bạn có chắc muốn xóa \"${course.title}\"? Hành động này không thể hoàn tác."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy bỏ")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _danger, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteCourse(course.id);
        final targetPage = _courses.length == 1 && _currentPage > 0 ? _currentPage - 1 : _currentPage;
        _loadCourses(page: targetPage);
        GlobalNotificationService.show(context: context, message: 'Xóa khóa học thành công', type: NotificationType.success);
      } catch (e) {
        GlobalNotificationService.show(context: context, message: e.toString(), type: NotificationType.error);
      }
    }
  }

  Future<void> _publishCourse(CourseResponse course) async {
    try {
      await _service.publishCourse(course.id);
      _loadCourses(page: _currentPage);
      GlobalNotificationService.show(context: context, message: 'Xuất bản thành công', type: NotificationType.success);
    } catch (e) {
      GlobalNotificationService.show(context: context, message: e.toString(), type: NotificationType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          "Quản lý khóa học",
          style: TextStyle(color: _textDark, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.3),
        ),
        iconTheme: const IconThemeData(color: _textDark),
        actions: [
          IconButton(
            icon: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.add, color: _primary, size: 20),
            ),
            onPressed: () => context.go('/mentor/courses/create'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _cardBorder),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: (q) => setState(() { _searchQuery = q; _loadCourses(page: 0); }),
                decoration: InputDecoration(
                  hintText: "Tìm kiếm khóa học...",
                  hintStyle: TextStyle(color: _textMedium.withValues(alpha: 0.85)),
                  prefixIcon: Icon(Icons.search, color: _textMedium),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // Scope chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Phạm vi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textDark)),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              children: [
                _mobileScopeChip('DEPT_ALL', 'Tất cả'),
                _mobileScopeChip('MINE', 'Khóa của tôi'),
              ],
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Trạng thái', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textDark)),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              children: [
                _mobileFilterChip('ALL', 'Tất cả'),
                _mobileFilterChip('PUBLISHED', 'Đã xuất bản'),
                _mobileFilterChip('DRAFT', 'Bản nháp'),
                _mobileFilterChip('ARCHIVED', 'Đã lưu trữ'),
              ],
            ),
          ),

          Expanded(child: _buildContent()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/mentor/courses/create'),
        backgroundColor: _primary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _mobileScopeChip(String value, String label) {
    final isSelected = _listScope == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        showCheckmark: true,
        checkmarkColor: _primary,
        onSelected: (_) => _onListScopeChanged(value),
        backgroundColor: Colors.white,
        selectedColor: _primary.withValues(alpha: 0.12),
        labelStyle: TextStyle(
          color: isSelected ? _primary : _textMedium,
          fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
        side: BorderSide(color: isSelected ? _primary.withValues(alpha: 0.35) : _cardBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _mobileFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        showCheckmark: true,
        checkmarkColor: _primary,
        onSelected: (_) => _onFilterChanged(value),
        backgroundColor: Colors.white,
        selectedColor: _primary.withValues(alpha: 0.12),
        labelStyle: TextStyle(
          color: isSelected ? _primary : _textMedium,
          fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
        side: BorderSide(color: isSelected ? _primary.withValues(alpha: 0.35) : _cardBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: _primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: _danger.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: const Icon(Icons.error_outline, size: 32, color: _danger),
            ),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: _danger, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCourses,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary, foregroundColor: Colors.white,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200 &&
            !_isLoadingMore &&
            _currentPage < _totalPages - 1) {
          _loadMoreCourses();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () => _loadCourses(),
        color: _primary,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          itemCount: _courses.length + 1,
          itemBuilder: (context, index) {
            if (index == _courses.length) {
              if (_isLoadingMore) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                );
              }
              if (_currentPage >= _totalPages - 1) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('$_totalElements khóa học', style: TextStyle(fontSize: 12, color: _textMedium))),
                );
              }
              return const SizedBox.shrink();
            }
            return _MobileCourseCard(
              course: _courses[index],
              primary: _primary,
              primaryLight: _primaryLight,
              textDark: _textDark,
              textMedium: _textMedium,
              cardBorder: _cardBorder,
              success: _success,
              warning: _warning,
              danger: _danger,
              isOwner: _isOwner(_courses[index]),
              onTap: () => context.go('/mentor/courses/${_courses[index].id.value}?title=${Uri.encodeComponent(_courses[index].title)}'),
              onEdit: () => context.go('/mentor/courses/${_courses[index].id.value}?title=${Uri.encodeComponent(_courses[index].title)}'),
              onPublish: () => _publishCourse(_courses[index]),
              onDelete: () => _deleteCourse(_courses[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasFilters = _searchQuery.isNotEmpty || _selectedFilter != 'ALL';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [_primary.withValues(alpha: 0.12), _primaryLight.withValues(alpha: 0.06)],
                ),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.08), blurRadius: 24, spreadRadius: 4)],
              ),
              child: Icon(
                hasFilters ? Icons.search_off_rounded : Icons.menu_book_rounded,
                size: 40, color: _primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasFilters ? "Không tìm thấy khóa học" : "Chưa có khóa học nào",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textDark, letterSpacing: -0.3),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 280,
              child: Text(
                hasFilters
                    ? "Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm."
                    : "Nhấn + để tạo khóa học đầu tiên.",
                style: TextStyle(fontSize: 14, color: _textMedium, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isOwner(CourseResponse course) =>
      _currentUserId != null && course.mentorId.value == _currentUserId;
}

/// ─────────────────────────────────────────────────────────────
/// Mobile Course Card với gradient header đẹp mắt
/// ─────────────────────────────────────────────────────────────
class _MobileCourseCard extends StatefulWidget {
  final CourseResponse course;
  final Color primary;
  final Color primaryLight;
  final Color textDark;
  final Color textMedium;
  final Color cardBorder;
  final Color success;
  final Color warning;
  final Color danger;
  final bool isOwner;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onPublish;
  final VoidCallback onDelete;

  const _MobileCourseCard({
    required this.course,
    required this.primary,
    required this.primaryLight,
    required this.textDark,
    required this.textMedium,
    required this.cardBorder,
    required this.success,
    required this.warning,
    required this.danger,
    required this.isOwner,
    required this.onTap,
    required this.onEdit,
    required this.onPublish,
    required this.onDelete,
  });

  @override
  State<_MobileCourseCard> createState() => _MobileCourseCardState();
}

class _MobileCourseCardState extends State<_MobileCourseCard> {
  bool _isPressed = false;

  List<double> _gradientFor(int seed) {
    final grads = [
      [0.5, 0.3],
      [0.45, 0.25],
      [0.55, 0.35],
      [0.4, 0.2],
    ];
    return grads[seed % grads.length];
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final grad = _gradientFor(course.id.value);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: widget.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: _isPressed
                      ? widget.primary.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: _isPressed ? 16 : 12,
                  offset: Offset(0, _isPressed ? 6 : 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gradient banner
                Container(
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.primary.withValues(alpha: grad[0]),
                        widget.primaryLight.withValues(alpha: grad[1]),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -8, bottom: -8,
                        child: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 8, top: 8,
                        child: Container(
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status row
                      Row(
                        children: [
                          _statusBadge(course.status),
                          const SizedBox(width: 6),
                          _ownershipBadge(course),
                          const Spacer(),
                          if (widget.isOwner) _buildPopupMenu(course),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Title
                      Text(
                        course.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16,
                          color: widget.textDark, height: 1.3,
                        ),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Description
                      Text(
                        (course.description ?? '').isEmpty ? "Không có mô tả" : course.description!,
                        style: TextStyle(fontSize: 13, color: widget.textMedium, height: 1.4),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),

                      // Stats
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color, bgColor;
    String label;
    IconData icon;

    switch (status.toUpperCase()) {
      case 'PUBLISHED':
        color = widget.success; bgColor = widget.success.withValues(alpha: 0.1);
        label = 'Đã xuất bản'; icon = Icons.check_circle_outline;
        break;
      case 'ARCHIVED':
        color = widget.textMedium; bgColor = widget.textMedium.withValues(alpha: 0.1);
        label = 'Đã lưu trữ'; icon = Icons.archive_outlined;
        break;
      default:
        color = widget.warning; bgColor = widget.warning.withValues(alpha: 0.1);
        label = 'Bản nháp'; icon = Icons.edit_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _ownershipBadge(CourseResponse course) {
    final isOwner = widget.isOwner;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isOwner ? widget.primary.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isOwner ? Icons.person : Icons.people, size: 11, color: isOwner ? widget.primary : Colors.grey),
          const SizedBox(width: 3),
          Text(
            isOwner ? 'Của bạn' : 'Mentor khác',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isOwner ? widget.primary : Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu(CourseResponse course) {
    return PopupMenuButton<String>(
      icon: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
        child: Icon(Icons.more_horiz, color: widget.textMedium, size: 18),
      ),
      onSelected: (value) async {
        if (value == 'edit') widget.onEdit();
        else if (value == 'publish') widget.onPublish();
        else if (value == 'delete') widget.onDelete();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: widget.textMedium),
              const SizedBox(width: 10),
              Text("Chỉnh sửa", style: TextStyle(color: widget.textDark, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        if (!course.isPublished)
          PopupMenuItem(
            value: 'publish',
            child: Row(
              children: [
                Icon(Icons.publish, size: 18, color: widget.success),
                const SizedBox(width: 10),
                Text("Xuất bản", style: TextStyle(color: widget.success, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: widget.danger),
              const SizedBox(width: 10),
              Text("Xóa", style: TextStyle(color: widget.danger, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
    );
  }

  Widget _statItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: widget.textMedium),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: widget.textMedium, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
