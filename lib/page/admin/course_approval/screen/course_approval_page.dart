import 'package:flutter/material.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/page/admin/course_approval/widgets/course_detail_preview_dialog.dart';
import 'package:smet/service/admin/course_approval/course_approval_service.dart';
import 'package:smet/service/common/global_notification_service.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';

class CourseApprovalPage extends StatefulWidget {
  const CourseApprovalPage({super.key});

  @override
  State<CourseApprovalPage> createState() => _CourseApprovalPageState();
}

class _CourseApprovalPageState extends State<CourseApprovalPage> {
  static const Color primary = Color(0xFF6366F1);
  static const Color background = Color(0xFFF3F6FC);
  static const Color cardBorder = Color(0xFFE8ECF4);
  static const Color textMedium = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);
  static const Color textDark = Color(0xFF0F172A);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  String _selectedStatus = 'PENDING';
  int _currentPage = 0;
  final int _pageSize = 10;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<CourseResponse> _courses = [];
  int _totalElements = 0;
  int _totalPages = 0;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isApproving = false;

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

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await CourseApprovalService.getPendingCourses(
        page: _currentPage,
        size: _pageSize,
        status: _selectedStatus == 'ALL' ? null : _selectedStatus,
        q: _searchQuery.isEmpty ? null : _searchQuery,
      );

      setState(() {
        _courses = response.content;
        _totalElements = response.totalElements;
        _totalPages = response.totalPages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onStatusChanged(String status) {
    setState(() {
      _selectedStatus = status;
      _currentPage = 0;
    });
    _loadCourses();
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 0;
    });
    _loadCourses();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadCourses();
  }

  Future<void> _showApproveConfirmation(CourseResponse course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: success, size: 28),
            const SizedBox(width: 12),
            const Text('Xác nhận phê duyệt'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc chắn muốn phê duyệt khóa học này?',
              style: TextStyle(color: textMedium, fontSize: 15),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textDark,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                      'Mentor: ${course.mentorName}',
                      style: TextStyle(color: textMedium, fontSize: 13),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: TextStyle(color: textMedium)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Phê duyệt'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _approveCourse(course);
    }
  }

  Future<void> _approveCourse(CourseResponse course) async {
    setState(() => _isApproving = true);

    try {
      await CourseApprovalService.approveCourse(course.id.toString());
      
      if (mounted) {
        GlobalNotificationService.show(
          context: context,
          message: 'Phê duyệt thành công',
          type: NotificationType.success,
        );
        _loadCourses();
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Lỗi không xác định';
        final msg = e.toString().toLowerCase();
        if (msg.contains('at least 10 questions') ||
            msg.contains('quiz must have') ||
            msg.contains('10 câu hỏi')) {
          errorMsg = 'Bài quiz phải có ít nhất 10 câu hỏi';
        } else if (msg.contains('not found')) {
          errorMsg = 'Không tìm thấy tài nguyên';
        } else if (msg.contains('exceeds')) {
          errorMsg = 'Số lượng câu hỏi vượt quá giới hạn cho phép';
        } else if (msg.contains('exception') || msg.contains('error')) {
          final parts = e.toString().split(':');
          if (parts.length > 1) {
            errorMsg = parts.last.trim();
          }
        }
        GlobalNotificationService.show(
          context: context,
          message: errorMsg,
          type: NotificationType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isApproving = false);
      }
    }
  }

  void _showCourseDetail(CourseResponse course) {
    showDialog(
      context: context,
      builder: (context) => CourseDetailPreviewDialog(
        courseId: course.id.toString(),
        onApproved: _loadCourses,
        onRejected: _loadCourses,
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return warning;
      case 'PUBLISHED':
        return success;
      case 'REJECTED':
        return danger;
      case 'DRAFT':
        return textMedium;
      default:
        return textLight;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return 'Chờ duyệt';
      case 'PUBLISHED':
        return 'Đã duyệt';
      case 'REJECTED':
        return 'Từ chối';
      case 'DRAFT':
        return 'Nháp';
      default:
        return status ?? 'N/A';
    }
  }

  String _getLevelLabel(int? level) {
    switch (level) {
      case 1:
        return 'Sơ cấp';
      case 2:
        return 'Trung cấp';
      case 3:
        return 'Nâng cao';
      default:
        return 'N/A';
    }
  }

  Color _getLevelColor(int? level) {
    switch (level) {
      case 1:
        return const Color(0xFF22C55E);
      case 2:
        return const Color(0xFF3B82F6);
      case 3:
        return const Color(0xFF8B5CF6);
      default:
        return textMedium;
    }
  }

  String _formatDuration(int? minutes) {
    if (minutes == null) return 'N/A';
    if (minutes < 60) return '$minutes phút';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '$hours giờ';
    return '$hours giờ $mins phút';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: cardBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SharedBreadcrumb(
            items: const [
              BreadcrumbItem(label: 'Trang chủ', route: '/'),
              BreadcrumbItem(label: 'Quản lý'),
              BreadcrumbItem(label: 'Phê duyệt khóa học'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.school_outlined, color: primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phê duyệt khóa học',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Quản lý và phê duyệt các khóa học mới',
                      style: TextStyle(
                        fontSize: 14,
                        color: textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildFilters(),
          const SizedBox(height: 20),
          _buildCourseList(),
          if (_totalPages > 1) ...[
            const SizedBox(height: 20),
            _buildPagination(),
          ],
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm khóa học...',
                    hintStyle: TextStyle(color: textLight),
                    prefixIcon: Icon(Icons.search, color: textMedium),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: textMedium),
                            onPressed: () {
                              _searchController.clear();
                              _onSearch('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: _onSearch,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _onSearch(_searchController.text),
                  icon: const Icon(Icons.search, size: 20),
                  label: const Text('Tìm kiếm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Trạng thái:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: textDark,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildStatusChip('PENDING', 'Chờ duyệt', warning),
              _buildStatusChip('PUBLISHED', 'Đã duyệt', success),
              _buildStatusChip('ALL', 'Tất cả', textMedium),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String value, String label, Color color) {
    final isSelected = _selectedStatus == value;
    return GestureDetector(
      onTap: () => _onStatusChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : cardBorder,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : textMedium,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildCourseList() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(60),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
        ),
        child: const Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang tải dữ liệu...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: danger.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.error_outline, color: danger, size: 48),
              const SizedBox(height: 16),
              Text(
                'Đã xảy ra lỗi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(color: textMedium),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadCourses,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_courses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(60),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, color: textLight, size: 64),
              const SizedBox(height: 16),
              Text(
                'Không có khóa học nào',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Không tìm thấy khóa học nào với bộ lọc hiện tại',
                style: TextStyle(color: textMedium),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: background,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Danh sách khóa học',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textDark,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_totalElements khóa học',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _courses.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: cardBorder),
            itemBuilder: (context, index) {
              final course = _courses[index];
              return _buildCourseCard(course);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(CourseResponse course) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.school, color: primary, size: 36),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        if (course.departmentName != null)
                          _buildInfoTag(Icons.person_outline, course.mentorName),
                        if (course.departmentName != null)
                          _buildInfoTag(Icons.business_outlined, course.departmentName!),
                        _buildInfoTag(Icons.access_time, _formatDuration(course.durationMinutes)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(course.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusLabel(course.status),
                      style: TextStyle(
                        color: _getStatusColor(course.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(course.createdAt),
                    style: TextStyle(
                      color: textLight,
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
              if (course.level != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getLevelColor(course.level).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.signal_cellular_alt,
                        size: 14,
                        color: _getLevelColor(course.level),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getLevelLabel(course.level),
                        style: TextStyle(
                          color: _getLevelColor(course.level),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              _buildActionButton(
                icon: Icons.visibility_outlined,
                label: 'Xem chi tiết',
                color: primary,
                onPressed: () => _showCourseDetail(course),
              ),
              if (course.status.toUpperCase() == 'PENDING') ...[
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: Icons.check_circle_outline,
                  label: 'Phê duyệt',
                  color: success,
                  onPressed: _isApproving ? null : () => _showApproveConfirmation(course),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: textMedium),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: textMedium,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        elevation: 0,
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 0 ? () => _onPageChanged(_currentPage - 1) : null,
            icon: const Icon(Icons.chevron_left),
            style: IconButton.styleFrom(
              backgroundColor: background,
              disabledBackgroundColor: background.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Trang ${_currentPage + 1} / $_totalPages',
            style: TextStyle(
              color: textDark,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _currentPage < _totalPages - 1 ? () => _onPageChanged(_currentPage + 1) : null,
            icon: const Icon(Icons.chevron_right),
            style: IconButton.styleFrom(
              backgroundColor: background,
              disabledBackgroundColor: background.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
