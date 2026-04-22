import 'package:flutter/material.dart';
import 'package:smet/model/pm_dashboard_models.dart';
import 'package:smet/service/pm/pm_dashboard_service.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';

// ============================================================
// TEAM PERFORMANCE SCREEN
// GET /api/pm/dashboard/team?courseId=&minScore=&page=&size=
// ============================================================
class TeamPerformanceScreen extends StatefulWidget {
  const TeamPerformanceScreen({super.key});

  @override
  State<TeamPerformanceScreen> createState() => _TeamPerformanceScreenState();
}

class _TeamPerformanceScreenState extends State<TeamPerformanceScreen> {
  static const _primary = Color(0xFF137FEC);
  static const _bgPage = Color(0xFFF3F6FC);
  static const _bgCard = Color(0xFFFFFFFF);
  static const _border = Color(0xFFE5E7EB);
  static const _textDark = Color(0xFF0F172A);
  static const _textMedium = Color(0xFF64748B);
  static const _textMuted = Color(0xFF94A3B8);
  static const _success = Color(0xFF22C55E);
  static const _warning = Color(0xFFF59E0B);
  static const _error = Color(0xFFEF4444);
  static const _info = Color(0xFF3B82F6);

  final _svc = PmDashboardService();

  // Filter state
  int? _selectedCourseId;
  double? _minScore;
  List<CourseOption> _courses = [];

  // Pagination
  int _page = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  final _size = 10;

  List<UserCourseReview> _items = [];
  bool _isLoading = true;
  bool _isLoadingCourses = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoadingCourses = true);
    try {
      final courses = await _svc.getCourses();
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _isLoadingCourses = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCourses = false);
    }
  }

  Future<void> _loadTeamProgress({int page = 0}) async {
    if (_selectedCourseId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Vui lòng chọn khóa học để xem tiến độ.';
        _items = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _page = page;
    });

    try {
      final result = await _svc.getTeamProgress(
        courseId: _selectedCourseId!,
        minScore: _minScore,
        page: page,
        size: _size,
      );
      if (!mounted) return;
      setState(() {
        _items = result.data;
        _totalPages = result.totalPages;
        _totalElements = result.totalElements;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể tải dữ liệu.';
        _isLoading = false;
      });
    }
  }

  Widget _buildPageHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SharedBreadcrumb(
            items: const [
              BreadcrumbItem(label: 'PM', route: '/pm/dashboard'),
              BreadcrumbItem(label: 'Tiến độ nhóm', route: '/pm/team'),
            ],
            primaryColor: _primary,
            fontSize: 13,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.people_rounded, color: _primary, size: 22),
              ),
              const SizedBox(width: 14),
              const Flexible(
                child: Text(
                  'Tiến độ nhóm',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _textDark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bộ lọc',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textDark),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return Column(
                  children: [
                    _buildCourseDropdown(),
                    const SizedBox(height: 12),
                    _buildScoreSlider(),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: _buildCourseDropdown()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildScoreSlider()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCourseDropdown() {
    final selected = _courses.isEmpty
        ? null
        : _courses.where((c) => c.id == _selectedCourseId).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Khóa học', style: TextStyle(fontSize: 12, color: _textMedium)),
        const SizedBox(height: 6),
        if (_isLoadingCourses)
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          )
        else
          PopupMenuButton<int>(
            onSelected: (v) {
              setState(() => _selectedCourseId = v);
              _loadTeamProgress();
            },
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selected?.title ?? 'Chọn khóa học',
                      style: TextStyle(
                        fontSize: 14,
                        color: selected != null ? _textDark : _textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: _textMuted),
                ],
              ),
            ),
            itemBuilder: (context) => _courses.map((c) {
              return PopupMenuItem<int>(
                value: c.id,
                child: Text(c.title, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildScoreSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Điểm tối thiểu: ${_minScore?.toStringAsFixed(1) ?? "Không giới hạn"}',
          style: const TextStyle(fontSize: 12, color: _textMedium),
        ),
        const SizedBox(height: 6),
        Slider(
          value: _minScore ?? 0,
          min: 0,
          max: 10,
          divisions: 20,
          label: _minScore?.toStringAsFixed(1) ?? 'Không giới hạn',
          onChanged: (v) => setState(() => _minScore = v == 0 ? null : v),
          onChangeEnd: (_) => _loadTeamProgress(),
        ),
      ],
    );
  }

  Widget _buildTable() {
    if (_selectedCourseId == null) {
      return _buildEmptyState(
        icon: Icons.menu_book_rounded,
        message: 'Vui lòng chọn khóa học để xem tiến độ nhóm.',
      );
    }

    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline_rounded,
        message: 'Chưa có dữ liệu tiến độ cho khóa học này.',
      );
    }

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      const Expanded(flex: 2, child: Text('Học viên', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textMedium))),
                      const Expanded(flex: 1, child: Text('Điểm TB', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textMedium), textAlign: TextAlign.center)),
                      const Expanded(flex: 1, child: Text('Bài quiz', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textMedium), textAlign: TextAlign.center)),
                      const Expanded(flex: 1, child: Text('Trạng thái', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textMedium), textAlign: TextAlign.center)),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
              ..._items.asMap().entries.map((e) => _buildUserRow(e.value, e.key.isEven)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildPagination(),
      ],
    );
  }

  Widget _buildUserRow(UserCourseReview user, bool even) {
    final avgScore = user.avgScore ?? 0;
    final quizCount = user.quizzes.length;
    final completedCount = user.quizzes.where((q) => q.status == 'COMPLETED').length;
    final scoreColor = avgScore >= 8 ? _success : avgScore >= 5 ? _warning : _error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: even ? const Color(0xFFF8FAFC) : _bgCard,
        border: const Border(top: BorderSide(color: _border, width: 0.5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.userName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'ID: ${user.userId}',
                    style: const TextStyle(fontSize: 11, color: _textMuted),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  avgScore > 0 ? avgScore.toStringAsFixed(1) : '-',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: scoreColor),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '$completedCount / $quizCount',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textDark),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 1,
              child: _buildStatusBadge(user.quizzes),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(List<QuizItem> quizzes) {
    if (quizzes.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: _textMuted.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
        child: const Text('Chưa làm', style: TextStyle(fontSize: 12, color: _textMuted), textAlign: TextAlign.center),
      );
    }

    final completed = quizzes.where((q) => q.status == 'COMPLETED').length;
    if (completed == quizzes.length) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: _success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
        child: const Text('Hoàn thành', style: TextStyle(fontSize: 12, color: _success), textAlign: TextAlign.center),
      );
    }

    final inProgress = quizzes.where((q) => q.status == 'IN_PROGRESS').length;
    if (inProgress > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: _warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
        child: const Text('Đang học', style: TextStyle(fontSize: 12, color: _warning), textAlign: TextAlign.center),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: _info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: const Text('Đã bắt đầu', style: TextStyle(fontSize: 12, color: _info), textAlign: TextAlign.center),
    );
  }

  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: _page > 0 ? () => _loadTeamProgress(page: _page - 1) : null,
          color: _primary,
        ),
        Text(
          'Trang ${_page + 1} / $_totalPages',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textMedium),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: _page < _totalPages - 1 ? () => _loadTeamProgress(page: _page + 1) : null,
          color: _primary,
        ),
      ],
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: _textMuted),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(fontSize: 14, color: _textMuted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(),
            const SizedBox(height: 20),
            _buildFilters(),
            const SizedBox(height: 20),
            _buildTable(),
          ],
        ),
      ),
    );
  }
}
