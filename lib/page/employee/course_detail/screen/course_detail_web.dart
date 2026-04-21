import 'package:flutter/material.dart';
import 'package:smet/page/employee/widgets/shell/employee_top_header.dart';
import 'package:smet/page/employee/course_detail/widgets/syllabus_section.dart';
import 'package:smet/page/employee/course_detail/widgets/enroll_card.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/model/Employee_course_model.dart';

class CourseDetailWeb extends StatelessWidget {
  final CourseDetail course;
  final Map<int, bool> expandedModules;
  final void Function(int) onToggleModule;
  final bool isEnrolling;
  final bool isPreviewMode;
  final VoidCallback? onEnroll;
  final VoidCallback? onLeaveCourse;
  final VoidCallback? onStartLearning;
  final VoidCallback? onShare;
  final VoidCallback? onBookmark;
  final VoidCallback? onChatWithMentor;
  final List<BreadcrumbItem>? breadcrumbs;

  const CourseDetailWeb({
    super.key,
    required this.course,
    required this.expandedModules,
    required this.onToggleModule,
    required this.isEnrolling,
    required this.isPreviewMode,
    required this.onEnroll,
    this.onLeaveCourse,
    required this.onStartLearning,
    this.onShare,
    this.onBookmark,
    this.onChatWithMentor,
    this.breadcrumbs,
  });

  String get _deadlineText {
    if (course.fixedDeadline != null && course.fixedDeadline!.isNotEmpty) {
      return 'Hạn chót: ${course.fixedDeadline}';
    }
    if (course.defaultDeadlineDays != null) {
      return 'Hạn chót: ${course.defaultDeadlineDays} ngày sau khi đăng ký';
    }
    return 'Không có giới hạn thời gian';
  }

  String get _deadlineStatusLabel {
    switch (course.deadlineStatus?.toUpperCase()) {
      case 'OVERDUE':
        return 'Quá hạn';
      case 'DUE_SOON':
        return 'Sắp hết hạn';
      case 'ON_TIME':
        return 'Còn thời gian';
      default:
        return '';
    }
  }

  Color get _deadlineStatusColor {
    switch (course.deadlineStatus?.toUpperCase()) {
      case 'OVERDUE':
        return const Color(0xFFEF4444);
      case 'DUE_SOON':
        return const Color(0xFFF59E0B);
      case 'ON_TIME':
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        EmployeeTopHeader(
          currentPage: 'Chi tiết khóa học',
          breadcrumbs: breadcrumbs,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Hero Header Card ───────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF137FEC), Color(0xFF0F57D0)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        course.title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      if (course.description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          course.description,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.5,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Mentor & Department row
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Giảng viên',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFD0E8FF),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                course.mentorName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          if (course.departmentName != null) ...[
                            const SizedBox(width: 24),
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            const SizedBox(width: 24),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Đơn vị',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFD0E8FF),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  course.departmentName!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const Spacer(),
                          if (course.enrolled)
                            OutlinedButton.icon(
                              onPressed: onChatWithMentor,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                              label: const Text(
                                'Chat với Mentor',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ─── Stats row ──────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.library_books,
                        iconBg: const Color(0xFFDBEAFE),
                        iconColor: const Color(0xFF137FEC),
                        label: 'Số chương',
                        value: '${course.moduleCount}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.play_lesson,
                        iconBg: const Color(0xFFFEF3C7),
                        iconColor: const Color(0xFFF59E0B),
                        label: 'Số bài học',
                        value: '${course.lessonCount}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.schedule,
                        iconBg: _deadlineStatusColor.withValues(alpha: 0.1),
                        iconColor: _deadlineStatusColor,
                        label: 'Thời hạn',
                        value: course.defaultDeadlineDays != null
                            ? '${course.defaultDeadlineDays} ngày'
                            : course.fixedDeadline ?? 'Không giới hạn',
                      ),
                    ),
                    if (course.deadlineStatus != null &&
                        course.deadlineStatus!.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: _deadlineStatusColor == const Color(0xFFEF4444)
                              ? Icons.warning
                              : _deadlineStatusColor == const Color(0xFFF59E0B)
                                  ? Icons.access_time
                                  : Icons.check_circle,
                          iconBg: _deadlineStatusColor.withValues(alpha: 0.1),
                          iconColor: _deadlineStatusColor,
                          label: 'Trạng thái hạn',
                          value: _deadlineStatusLabel,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 32),

                // ─── 2-column layout ─────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left column
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Deadline info card
                          if (course.deadlineType != null) ...[
                            _DeadlineInfoCard(
                              deadlineText: _deadlineText,
                              deadlineStatus: _deadlineStatusLabel,
                              deadlineStatusColor: _deadlineStatusColor,
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Syllabus
                          _SyllabusHeader(
                            moduleCount: course.moduleCount,
                            lessonCount: course.lessonCount,
                            expandedModules: expandedModules,
                            course: course,
                            onToggleModule: onToggleModule,
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),

                    const SizedBox(width: 24),

                    // Right column
                    SizedBox(
                      width: 360,
                      child: Column(
                        children: [
                          _StickyEnrollCard(
                            child: EnrollCard(
                              onEnroll: isPreviewMode ? null : onEnroll,
                              onStartLearning: onStartLearning,
                              onLeaveCourse: isPreviewMode ? null : onLeaveCourse,
                              moduleCount: course.moduleCount,
                              lessonCount: course.lessonCount,
                              isEnrolled: course.enrolled,
                              progress: course.progress,
                              enrollmentStatus: course.enrollmentStatus,
                              isLoading: isEnrolling,
                              isArchived: course.isArchived,
                              onShare: onShare,
                              onBookmark: onBookmark,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeadlineInfoCard extends StatelessWidget {
  final String deadlineText;
  final String deadlineStatus;
  final Color deadlineStatusColor;

  const _DeadlineInfoCard({
    required this.deadlineText,
    required this.deadlineStatus,
    required this.deadlineStatusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            size: 20,
            color: deadlineStatusColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thời hạn hoàn thành',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  deadlineText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          if (deadlineStatus.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: deadlineStatusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                deadlineStatus,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: deadlineStatusColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SyllabusHeader extends StatelessWidget {
  final int moduleCount;
  final int lessonCount;
  final Map<int, bool> expandedModules;
  final CourseDetail course;
  final void Function(int) onToggleModule;

  const _SyllabusHeader({
    required this.moduleCount,
    required this.lessonCount,
    required this.expandedModules,
    required this.course,
    required this.onToggleModule,
  });

  @override
  Widget build(BuildContext context) {
    final modulesWithState = course.modules.asMap().entries.map((entry) {
      final index = entry.key;
      final module = entry.value;
      return SyllabusModule(
        title: module.title,
        lessonCount: module.lessons.length,
        lessons: module.lessons
            .map((l) => SyllabusLesson(title: l.title, type: SyllabusLessonType.video))
            .toList(),
        isExpanded: expandedModules[index] ?? false,
        onToggle: () => onToggleModule(index),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Nội dung khóa học',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF137FEC).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$moduleCount chương • $lessonCount bài học',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF137FEC),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (modulesWithState.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Column(
              children: [
                Icon(Icons.library_books_outlined,
                    size: 48, color: Color(0xFFCBD5E1)),
                SizedBox(height: 12),
                Text(
                  'Chưa có chương nào',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Khóa học chưa có nội dung nào được thêm vào.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          SyllabusSection(
            modules: modulesWithState,
            onLessonTap: (moduleIdx, lessonIdx) {
              debugPrint('Tap lesson $lessonIdx in module $moduleIdx');
            },
          ),
      ],
    );
  }
}

class _StickyEnrollCard extends StatelessWidget {
  final Widget child;

  const _StickyEnrollCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
