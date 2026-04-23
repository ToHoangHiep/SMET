import 'package:flutter/material.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/service/admin/course_approval/course_approval_service.dart';
import 'package:smet/service/common/global_notification_service.dart';

class CourseDetailPreviewDialog extends StatefulWidget {
  final String courseId;
  final VoidCallback? onApproved;
  final VoidCallback? onRejected;

  const CourseDetailPreviewDialog({
    super.key,
    required this.courseId,
    this.onApproved,
    this.onRejected,
  });

  @override
  State<CourseDetailPreviewDialog> createState() =>
      _CourseDetailPreviewDialogState();
}

class _CourseDetailPreviewDialogState
    extends State<CourseDetailPreviewDialog> {
  static const Color primary = Color(0xFF6366F1);
  static const Color background = Color(0xFFF3F6FC);
  static const Color cardBorder = Color(0xFFE8ECF4);
  static const Color textMedium = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);
  static const Color textDark = Color(0xFF0F172A);
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color pink = Color(0xFFEC4899);

  CourseDetailResponse? _courseDetail;
  List<CourseQuizResponse> _quizzes = [];
  bool _isLoadingQuizzes = true;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCourseDetail();
    _loadCourseQuizzes();
  }

  Future<void> _loadCourseDetail() async {
    try {
      final detail =
          await CourseApprovalService.getCourseDetail(widget.courseId);
      if (mounted) {
        setState(() {
          _courseDetail = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCourseQuizzes() async {
    try {
      final quizzes =
          await CourseApprovalService.getCourseQuizzes(widget.courseId);
      if (mounted) {
        setState(() {
          _quizzes = quizzes;
          _isLoadingQuizzes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingQuizzes = false;
        });
      }
    }
  }

  Future<void> _approveCourse() async {
    setState(() => _isSaving = true);
    try {
      await CourseApprovalService.approveCourse(widget.courseId);
      if (mounted) {
        Navigator.pop(context);
        GlobalNotificationService.show(
          context: context,
          message: 'Phê duyệt khóa học thành công',
          type: NotificationType.success,
        );
        widget.onApproved?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        GlobalNotificationService.show(
          context: context,
          message: 'Lỗi: ${e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')}',
          type: NotificationType.error,
        );
      }
    }
  }

  Future<void> _showRejectDialog() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.cancel_outlined, color: danger, size: 28),
            const SizedBox(width: 12),
            const Text('Từ chối khóa học'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vui lòng nhập lý do từ chối để mentor biết và chỉnh sửa:',
              style: TextStyle(color: textMedium, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'VD: Nội dung bài học còn thiếu, chất lượng video chưa tốt...',
                hintStyle: TextStyle(color: textLight),
                filled: true,
                fillColor: background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: primary, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hủy', style: TextStyle(color: textMedium)),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                GlobalNotificationService.show(
                  context: ctx,
                  message: 'Vui lòng nhập lý do từ chối',
                  type: NotificationType.warning,
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isSaving = true);
      try {
        // TODO: call backend reject endpoint when available
        // await CourseApprovalService.rejectCourse(widget.courseId, reasonController.text.trim());
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context);
          GlobalNotificationService.show(
            context: context,
            message: 'Đã từ chối khóa học',
            type: NotificationType.success,
          );
          widget.onRejected?.call();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          GlobalNotificationService.show(
            context: context,
            message: 'Lỗi: ${e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')}',
            type: NotificationType.error,
          );
        }
      }
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.75,
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: _isLoading
                  ? _buildLoadingState()
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _buildContent(),
            ),
            if (!_isLoading && _errorMessage == null) _buildFooterActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chi tiết khóa học',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_courseDetail != null)
                  Text(
                    _courseDetail!.title,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getStatusLabel(_courseDetail?.status),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.all(60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang tải chi tiết khóa học...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: danger, size: 48),
            const SizedBox(height: 16),
            Text(
              'Không thể tải chi tiết khóa học',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textDark),
            ),
            const SizedBox(height: 8),
            Text(_errorMessage ?? 'Unknown error',
                style: TextStyle(color: textMedium), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadCourseDetail();
              },
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

  Widget _buildContent() {
    final course = _courseDetail!;
    return Flexible(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==== Top info cards ====
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildCourseInfoCard(course)),
                const SizedBox(width: 16),
                Expanded(child: _buildMentorInfoCard(course)),
              ],
            ),
            const SizedBox(height: 20),

            // ==== Badges ====
            _buildBadgesSection(course),
            const SizedBox(height: 20),

            // ==== Description ====
            if (course.description != null &&
                course.description!.isNotEmpty) ...[
              _buildDescriptionSection(course),
              const SizedBox(height: 20),
            ],

            // ==== Module / Lesson tree ====
            _buildModulesSection(course),
            const SizedBox(height: 20),

            // ==== Quiz section ====
            _buildQuizzesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseInfoCard(CourseDetailResponse course) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.info_outline, size: 16, color: primary),
              const SizedBox(width: 6),
              Text(
                'Thông tin khóa học',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow(Icons.business_outlined, 'Phòng ban',
              course.departmentName ?? 'N/A'),
          const SizedBox(height: 10),
          _infoRow(Icons.calendar_today_outlined, 'Ngày tạo',
              _formatDate(course.createdAt)),
          const SizedBox(height: 10),
          _infoRow(Icons.update_outlined, 'Cập nhật lần cuối',
              _formatDate(course.updatedAt)),
          const SizedBox(height: 10),
          _infoRow(
              Icons.schedule_outlined,
              'Hạn nộp',
              course.deadlineType?.toUpperCase() == 'FIXED'
                  ? _formatDate(course.fixedDeadline)
                  : '${course.defaultDeadlineDays ?? 20} ngày (tương đối)'),
        ],
      ),
    );
  }

  Widget _buildMentorInfoCard(CourseDetailResponse course) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.person_outline, size: 16, color: primary),
              const SizedBox(width: 6),
              Text(
                'Mentor',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow(Icons.badge_outlined, 'Tên', course.mentorName),
          const SizedBox(height: 10),
          _infoRow(Icons.signal_cellular_alt, 'Trình độ',
              _getLevelLabel(course.level)),
          const SizedBox(height: 10),
          _infoRow(Icons.access_time, 'Tổng thời lượng',
              _formatDuration(course.durationMinutes)),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: textLight),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: textLight, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildBadgesSection(CourseDetailResponse course) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _buildBadge(
            icon: Icons.signal_cellular_alt,
            label: _getLevelLabel(course.level),
            color: _getLevelColor(course.level),
          ),
          _buildBadge(
            icon: Icons.access_time,
            label: _formatDuration(course.durationMinutes),
            color: info,
          ),
          _buildBadge(
            icon: Icons.layers_outlined,
            label: '${course.modules?.length ?? course.moduleCount} chương',
            color: purple,
          ),
          _buildBadge(
            icon: Icons.play_lesson_outlined,
            label: '${course.lessonCount} bài học',
            color: pink,
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(
      {required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(CourseDetailResponse course) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.description_outlined, color: primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Mô tả khóa học',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              course.description ?? '',
              style: TextStyle(
                color: textMedium,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModulesSection(CourseDetailResponse course) {
    final modules = course.modules;
    if (modules == null || modules.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.folder_open_outlined, color: textLight, size: 40),
              const SizedBox(height: 12),
              Text(
                'Chưa có cấu trúc chương / bài học',
                style: TextStyle(color: textMedium, fontSize: 14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.list_alt, color: primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Cấu trúc khóa học',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                  ),
                ),
                const Spacer(),
                Text(
                  '${modules.length} chương',
                  style: TextStyle(color: textMedium, fontSize: 13),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: modules.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: cardBorder),
            itemBuilder: (context, moduleIndex) {
              final module = modules[moduleIndex];
              return _buildModuleItem(module, moduleIndex);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModuleItem(CourseModuleDetail module, int moduleIndex) {
    final lessons = module.lessons ?? [];
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      childrenPadding: EdgeInsets.zero,
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '${moduleIndex + 1}',
            style: TextStyle(
              color: primary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
      title: Text(
        module.title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
      ),
      subtitle: Text(
        '${lessons.length} bài học',
        style: TextStyle(color: textMedium, fontSize: 12),
      ),
      trailing: Icon(Icons.expand_more, color: textMedium),
      children: lessons.isEmpty
          ? [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Chưa có bài học nào',
                  style: TextStyle(color: textLight, fontSize: 13, fontStyle: FontStyle.italic),
                ),
              ),
            ]
          : lessons.asMap().entries.map((entry) {
              return _buildLessonItem(entry.value, entry.key);
            }).toList(),
    );
  }

  Widget _buildLessonItem(CourseLessonDetail lesson, int lessonIndex) {
    final contents = lesson.contents ?? [];
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 16, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cardBorder.withValues(alpha: 0.6)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
          leading: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Icon(Icons.play_arrow, color: info, size: 16),
            ),
          ),
          title: Text(
            lesson.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textDark,
            ),
          ),
          subtitle: Text(
            '${contents.length} nội dung',
            style: TextStyle(color: textLight, fontSize: 11),
          ),
          trailing: Icon(Icons.expand_more, color: textLight, size: 20),
          children: contents.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Chưa có nội dung',
                      style: TextStyle(
                          color: textLight, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ),
                ]
              : contents.map((c) => _buildContentItem(c)).toList(),
        ),
      ),
    );
  }

  Widget _buildContentItem(LessonContentResponse content) {
    IconData icon;
    Color color;
    switch (content.type) {
      case LessonContentType.TEXT:
        icon = Icons.article_outlined;
        color = info;
        break;
      case LessonContentType.VIDEO:
        icon = Icons.videocam_outlined;
        color = danger;
        break;
      case LessonContentType.LINK:
        icon = Icons.link;
        color = purple;
        break;
    }

    final displayContent = content.content ?? '(trống)';
    final isLongText = content.type == LessonContentType.TEXT && displayContent.length > 200;
    final previewText = isLongText
        ? '${displayContent.substring(0, 200)}...'
        : displayContent;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cardBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                content.type.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const Spacer(),
              Text(
                '#${content.orderIndex + 1}',
                style: TextStyle(fontSize: 11, color: textLight),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (content.type == LessonContentType.VIDEO)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_circle_outline,
                          color: Colors.red, size: 16),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          displayContent,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (content.thumbnailUrl != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      content.thumbnailUrl!,
                      height: 80,
                      width: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 80,
                        width: 140,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ],
            )
          else if (content.type == LessonContentType.LINK)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: purple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.attach_file, size: 14, color: purple),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      displayContent,
                      style: TextStyle(
                        fontSize: 12,
                        color: purple,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                previewText,
                style: TextStyle(
                  fontSize: 12,
                  color: textDark,
                  height: 1.5,
                ),
                maxLines: isLongText ? 6 : null,
                overflow: isLongText ? TextOverflow.ellipsis : TextOverflow.visible,
              ),
            ),
          if (isLongText)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '[Nội dung đã bị cắt ngắn — xem đầy đủ khi mở khóa học]',
                style: TextStyle(
                  fontSize: 10,
                  color: textLight,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooterActions() {
    final isPending =
        _courseDetail?.status.toUpperCase() == 'PENDING';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: cardBorder)),
      ),
      child: Row(
        children: [
          Text(
            'ID: ${_courseDetail?.id}',
            style: TextStyle(color: textLight, fontSize: 12),
          ),
          const Spacer(),
          if (isPending) ...[
            OutlinedButton.icon(
              onPressed: _isSaving ? null : _showRejectDialog,
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('Từ chối'),
              style: OutlinedButton.styleFrom(
                foregroundColor: danger,
                side: BorderSide(color: danger),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _approveCourse,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline, size: 18),
              label: Text(_isSaving ? 'Đang xử lý...' : 'Phê duyệt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ] else
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Đóng'),
            ),
        ],
      ),
    );
  }

  Widget _buildQuizzesSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFBBF24).withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.quiz_outlined, color: const Color(0xFFB45309), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Bài kiểm tra (Quiz)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                  ),
                ),
                const Spacer(),
                if (_isLoadingQuizzes)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Text(
                    '${_quizzes.length} bài',
                    style: TextStyle(color: textMedium, fontSize: 13),
                  ),
              ],
            ),
          ),
          if (_isLoadingQuizzes)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('Đang tải bài kiểm tra...'),
              ),
            )
          else if (_quizzes.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.quiz_outlined, color: textLight, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      'Khóa học chưa có bài kiểm tra nào',
                      style: TextStyle(color: textMedium, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _quizzes.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: cardBorder),
              itemBuilder: (context, index) {
                return _buildQuizItem(_quizzes[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildQuizItem(CourseQuizResponse quiz) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      childrenPadding: EdgeInsets.zero,
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFB45309).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(Icons.help_outline, color: Color(0xFFB45309), size: 18),
        ),
      ),
      title: Text(
        quiz.title.isEmpty ? 'Bài kiểm tra' : quiz.title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
      ),
      subtitle: Wrap(
        spacing: 8,
        children: [
          Text(
            '${quiz.questionCount ?? 0} câu hỏi',
            style: TextStyle(color: textMedium, fontSize: 12),
          ),
          if (quiz.passingScore != null)
            Text(
              ' • Đạt: ${quiz.passingScore}%',
              style: TextStyle(color: textMedium, fontSize: 12),
            ),
          if (quiz.timeLimitMinutes != null && quiz.timeLimitMinutes! > 0)
            Text(
              ' • ${quiz.timeLimitMinutes} phút',
              style: TextStyle(color: textMedium, fontSize: 12),
            ),
        ],
      ),
      trailing: Icon(Icons.expand_more, color: textMedium),
      children: _buildQuizQuestions(quiz),
    );
  }

  List<Widget> _buildQuizQuestions(CourseQuizResponse quiz) {
    final questions = quiz.questions ?? [];
    if (questions.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Chưa có câu hỏi nào trong bài kiểm tra này',
            style: TextStyle(color: textLight, fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ),
      ];
    }

    return questions.asMap().entries.map((entry) {
      return _buildQuizQuestionItem(entry.key, entry.value);
    }).toList();
  }

  Widget _buildQuizQuestionItem(int index, CourseQuizQuestionResponse question) {
    final options = question.options ?? [];

    IconData typeIcon;
    Color typeColor;
    String typeLabel;
    switch (question.type?.toUpperCase()) {
      case 'SINGLE_CHOICE':
      case 'SINGLE':
        typeIcon = Icons.check_circle_outline;
        typeColor = const Color(0xFF3B82F6);
        typeLabel = 'Một đáp án';
        break;
      case 'MULTIPLE_CHOICE':
      case 'MULTIPLE':
        typeIcon = Icons.check_box_outlined;
        typeColor = const Color(0xFF8B5CF6);
        typeLabel = 'Nhiều đáp án';
        break;
      default:
        typeIcon = Icons.help_outline;
        typeColor = textMedium;
        typeLabel = question.type ?? 'Trắc nghiệm';
    }

    return Container(
      margin: const EdgeInsets.only(left: 24, right: 16, top: 4, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cardBorder.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.content,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textDark,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(typeIcon, size: 12, color: typeColor),
                          const SizedBox(width: 4),
                          Text(
                            typeLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: typeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (options.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...options.map((opt) {
              final isCorrect = opt.isCorrect == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? const Color(0xFF10B981).withValues(alpha: 0.08)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isCorrect
                        ? const Color(0xFF10B981).withValues(alpha: 0.3)
                        : cardBorder.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.circle_outlined,
                      size: 16,
                      color: isCorrect ? const Color(0xFF10B981) : textLight,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        opt.content,
                        style: TextStyle(
                          fontSize: 12,
                          color: isCorrect ? const Color(0xFF065F46) : textDark,
                          fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
