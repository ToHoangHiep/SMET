import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/model/mentor_enrollment_model.dart';
import 'package:smet/service/mentor/mentor_student_service.dart';
import 'package:smet/service/mentor/course_service.dart';

/// Mentor Students - Web Layout
/// Hiển thị danh sách học viên của tất cả các khóa học của mentor
class MentorStudentsWeb extends StatefulWidget {
  const MentorStudentsWeb({super.key});

  @override
  State<MentorStudentsWeb> createState() => _MentorStudentsWebState();
}

class _MentorStudentsWebState extends State<MentorStudentsWeb> {
  final _studentService = MentorStudentService();
  final _courseService = MentorCourseService();

  List<CourseResponse> _courses = [];
  CourseResponse? _selectedCourse;
  List<MentorEnrollmentInfo> _enrollments = [];
  bool _isLoadingCourses = true;
  bool _isLoadingEnrollments = false;
  String? _error;
  String _searchQuery = '';
  String _statusFilter = 'ALL';
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  final int _pageSize = 15;

  // Extend deadline dialog
  MentorEnrollmentInfo? _selectedEnrollment;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoadingCourses = true);
    try {
      final result = await _courseService.listCourses(page: 0, size: 50);
      if (!mounted) return;
      setState(() {
        _courses = result.content;
        _isLoadingCourses = false;
      });
      // Auto-select first course
      if (_courses.isNotEmpty && _selectedCourse == null) {
        _selectCourse(_courses.first);
      }
    } catch (e) {
      log("[Students] loadCourses failed: $e");
      if (!mounted) return;
      setState(() {
        _isLoadingCourses = false;
        _error = 'Không thể tải danh sách khóa học';
      });
    }
  }

  Future<void> _selectCourse(CourseResponse course) async {
    setState(() => _selectedCourse = course);
    _loadEnrollments();
  }

  Future<void> _loadEnrollments({int page = 0}) async {
    if (_selectedCourse == null) return;
    setState(() {
      _isLoadingEnrollments = true;
      _error = null;
      _currentPage = page;
    });
    try {
      final result = await _studentService.getEnrollmentsByCourse(
        _selectedCourse!.id,
        page: page,
        size: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _enrollments = result.content;
        _totalPages = result.totalPages;
        _totalElements = result.totalElements;
        _isLoadingEnrollments = false;
      });
    } catch (e) {
      log("[Students] loadEnrollments failed: $e");
      if (!mounted) return;
      setState(() {
        _isLoadingEnrollments = false;
        _error = 'Không thể tải danh sách học viên';
      });
    }
  }

  void _onSearch(String value) {
    setState(() => _searchQuery = value);
  }

  void _onStatusFilter(String status) {
    setState(() => _statusFilter = status);
  }

  List<MentorEnrollmentInfo> get _filteredEnrollments {
    var list = _enrollments;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((e) =>
        e.userName.toLowerCase().contains(q) ||
        e.userEmail.toLowerCase().contains(q)
      ).toList();
    }
    if (_statusFilter != 'ALL') {
      list = list.where((e) {
        if (_statusFilter == 'NOT_STARTED') return e.status == EnrollmentStatus.NOT_STARTED;
        if (_statusFilter == 'IN_PROGRESS') return e.status == EnrollmentStatus.IN_PROGRESS;
        if (_statusFilter == 'COMPLETED') return e.status == EnrollmentStatus.COMPLETED;
        if (_statusFilter == 'OVERDUE') return e.isOverdue;
        return true;
      }).toList();
    }
    return list;
  }

  void _goToPage(int page) {
    if (page >= 0 && page < _totalPages) {
      _loadEnrollments(page: page);
    }
  }

  Future<void> _showExtendDeadlineDialog(MentorEnrollmentInfo enrollment) async {
    final daysController = TextEditingController(text: '7');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.timer_outlined, color: Color(0xFF6366F1), size: 20),
            ),
            const SizedBox(width: 12),
            const Text("Gia hạn deadline"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gia hạn deadline cho "${enrollment.userName}"',
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: daysController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Số ngày gia hạn',
                      prefixIcon: const Icon(Icons.add),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('ngày'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: const Text("Gia hạn"),
          ),
        ],
      ),
    );

    if (result == true) {
      final days = int.tryParse(daysController.text) ?? 7;
      try {
        await _studentService.extendDeadline(enrollment.enrollmentId, days);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Đã gia hạn thêm $days ngày cho ${enrollment.userName}"),
            backgroundColor: Colors.green,
          ),
        );
        _loadEnrollments(page: _currentPage);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gia hạn thất bại: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(30, 30, 30, 0),
            child: BreadcrumbPageHeader(
              pageTitle: "Quản lý học viên",
              pageIcon: Icons.people_rounded,
              breadcrumbs: const [
                BreadcrumbItem(label: "Mentor", route: "/mentor/dashboard"),
                BreadcrumbItem(label: "Học viên"),
              ],
              primaryColor: const Color(0xFF6366F1),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  _buildTopBar(),
                  const SizedBox(height: 20),
                  // Stats row
                  _buildStatsRow(),
                  const SizedBox(height: 20),
                  // Table
                  Expanded(child: _buildContent()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        // Course selector
        SizedBox(
          width: 300,
          child: _isLoadingCourses
              ? const LinearProgressIndicator()
              : DropdownButtonFormField<CourseResponse>(
                  value: _selectedCourse,
                  decoration: InputDecoration(
                    hintText: 'Chọn khóa học',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  isExpanded: true,
                  items: _courses.map((course) {
                    return DropdownMenuItem(
                      value: course,
                      child: Text(
                        course.title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (course) {
                    if (course != null) _selectCourse(course);
                  },
                ),
        ),
        const SizedBox(width: 16),
        // Search
        SizedBox(
          width: 280,
          child: TextField(
            onChanged: _onSearch,
            decoration: InputDecoration(
              hintText: "Tìm kiếm học viên...",
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Status filters
        _filterChip("ALL", "Tất cả"),
        _filterChip("IN_PROGRESS", "Đang học"),
        _filterChip("COMPLETED", "Hoàn thành"),
        _filterChip("OVERDUE", "Quá hạn"),
        const Spacer(),
        Text(
          "$_totalElements học viên",
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _filterChip(String value, String label) {
    final isSelected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (_) => _onStatusFilter(value),
      ),
    );
  }

  Widget _buildStatsRow() {
    final total = _enrollments.length;
    final completed = _enrollments.where((e) => e.status == EnrollmentStatus.COMPLETED).length;
    final inProgress = _enrollments.where((e) => e.status == EnrollmentStatus.IN_PROGRESS).length;
    final overdue = _enrollments.where((e) => e.isOverdue).length;

    return Row(
      children: [
        _statCard("Tổng học viên", "$total", Icons.people_outline, const Color(0xFF6366F1)),
        const SizedBox(width: 16),
        _statCard("Đang học", "$inProgress", Icons.school_outlined, const Color(0xFF3B82F6)),
        const SizedBox(width: 16),
        _statCard("Hoàn thành", "$completed", Icons.check_circle_outline, const Color(0xFF22C55E)),
        const SizedBox(width: 16),
        _statCard("Quá hạn", "$overdue", Icons.warning_amber_outlined, const Color(0xFFEF4444)),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoadingEnrollments) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEnrollments,
              child: const Text("Thử lại"),
            ),
          ],
        ),
      );
    }

    final filtered = _filteredEnrollments;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _statusFilter != 'ALL'
                  ? "Không tìm thấy học viên phù hợp"
                  : "Chưa có học viên nào",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(child: _buildTable(filtered)),
        const SizedBox(height: 12),
        _buildPagination(),
      ],
    );
  }

  Widget _buildTable(List<MentorEnrollmentInfo> enrollments) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FC),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text("Học viên", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                Expanded(flex: 2, child: Text("Email", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                Expanded(flex: 1, child: Text("Trạng thái", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text("Tiến độ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center)),
                Expanded(flex: 1, child: Text("Deadline", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center)),
                Expanded(flex: 1, child: Text("Hành động", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center)),
              ],
            ),
          ),
          // Rows
          Expanded(
            child: ListView.separated(
              itemCount: enrollments.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) => _buildRow(enrollments[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(MentorEnrollmentInfo enrollment) {
    Color statusColor;
    String statusLabel;
    switch (enrollment.status) {
      case EnrollmentStatus.COMPLETED:
        statusColor = const Color(0xFF22C55E);
        statusLabel = 'Hoàn thành';
        break;
      case EnrollmentStatus.IN_PROGRESS:
        statusColor = const Color(0xFF3B82F6);
        statusLabel = 'Đang học';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = 'Chưa bắt đầu';
    }

    if (enrollment.isOverdue && enrollment.status != EnrollmentStatus.COMPLETED) {
      statusColor = const Color(0xFFEF4444);
      statusLabel = 'Quá hạn';
    }

    final effectiveDeadline = enrollment.extendedDeadline ?? enrollment.deadline;
    String deadlineText = '-';
    if (effectiveDeadline != null) {
      final diff = effectiveDeadline.difference(DateTime.now()).inDays;
      if (diff < 0) {
        deadlineText = 'Quá ${-diff} ngày';
      } else if (diff == 0) {
        deadlineText = 'Hết hôm nay';
      } else {
        deadlineText = '$diff ngày';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // Student info
          Expanded(flex: 2, child: _studentCell(enrollment)),
          // Email
          Expanded(
            flex: 2,
            child: Text(
              enrollment.userEmail,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Status
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                ),
              ),
            ),
          ),
          // Progress
          Expanded(
            flex: 2,
            child: Center(
              child: SizedBox(
                width: 120,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: enrollment.progress / 100,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation(
                          enrollment.status == EnrollmentStatus.COMPLETED
                              ? const Color(0xFF22C55E)
                              : enrollment.isOverdue
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF6366F1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${enrollment.progress}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: enrollment.status == EnrollmentStatus.COMPLETED
                            ? const Color(0xFF22C55E)
                            : enrollment.isOverdue
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Deadline
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                deadlineText,
                style: TextStyle(
                  fontSize: 12,
                  color: enrollment.isOverdue ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                  fontWeight: enrollment.isOverdue ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
          // Actions
          Expanded(
            flex: 1,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: 'Gia hạn deadline',
                    child: InkWell(
                      onTap: () => _showExtendDeadlineDialog(enrollment),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F3FD),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF6366F1)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentCell(MentorEnrollmentInfo enrollment) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              enrollment.initials,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6366F1),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                enrollment.userName,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              if (enrollment.extendedDeadline != null)
                Row(
                  children: [
                    Icon(Icons.update, size: 10, color: Colors.grey[400]),
                    const SizedBox(width: 2),
                    Text(
                      'Đã gia hạn',
                      style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        ...List.generate(_totalPages > 5 ? 5 : _totalPages, (index) {
          int pageNum;
          if (_totalPages > 5) {
            if (_currentPage < 3) pageNum = index;
            else if (_currentPage > _totalPages - 3) pageNum = _totalPages - 5 + index;
            else pageNum = _currentPage - 2 + index;
          } else {
            pageNum = index;
          }
          final isCurrent = pageNum == _currentPage;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              onTap: () => _goToPage(pageNum),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isCurrent ? const Color(0xFF6366F1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "${pageNum + 1}",
                  style: TextStyle(
                    color: isCurrent ? Colors.white : Colors.grey[700],
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }),
        IconButton(
          onPressed: _currentPage < _totalPages - 1 ? () => _goToPage(_currentPage + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
