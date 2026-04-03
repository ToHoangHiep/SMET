import 'package:flutter/material.dart';
import 'package:smet/page/employee/course_detail/widgets/syllabus_section.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/model/Employee_course_model.dart';

class AdminCoursePreviewWeb extends StatefulWidget {
  final CourseDetail course;
  final List<BreadcrumbItem>? breadcrumbs;
  final VoidCallback onBack;

  const AdminCoursePreviewWeb({
    super.key,
    required this.course,
    this.breadcrumbs,
    required this.onBack,
  });

  @override
  State<AdminCoursePreviewWeb> createState() => _AdminCoursePreviewWebState();
}

class _AdminCoursePreviewWebState extends State<AdminCoursePreviewWeb> {
  final Map<int, bool> _expandedModules = {};

  List<SyllabusModule> _buildSyllabusModules() {
    return widget.course.modules.asMap().entries.map((entry) {
      final idx = entry.key;
      final m = entry.value;
      return SyllabusModule(
        title: m.title,
        lessonCount: m.lessons.length,
        lessons: m.lessons
            .map((l) => SyllabusLesson(title: l.title, type: SyllabusLessonType.video))
            .toList(),
        isExpanded: _expandedModules[idx] ?? false,
        onToggle: () {
          setState(() {
            _expandedModules[idx] = !(_expandedModules[idx] ?? false);
          });
        },
      );
    }).toList();
  }

  Color get _deadlineStatusColor {
    switch (widget.course.deadlineStatus?.toUpperCase()) {
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
    final course = widget.course;

    return Column(
      children: [
        // ─── Admin Header ────────────────────────────────────────
        _AdminPreviewHeader(
          breadcrumbs: widget.breadcrumbs,
          onBack: widget.onBack,
        ),

        // ─── Preview Banner ───────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          color: const Color(0xFFFEF3C7),
          child: const Row(
            children: [
              Icon(Icons.visibility, size: 18, color: Color(0xFFB45309)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Chế độ xem trước — Bạn chỉ xem nội dung khóa học. Đăng ký, học và chỉnh sửa nội dung không khả dụng tại đây.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ─── Main Content ────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Hero Header Card ───
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
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.person, size: 20, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Giảng viên',
                                style: TextStyle(fontSize: 11, color: Color(0xFFD0E8FF), fontWeight: FontWeight.w500),
                              ),
                              Text(
                                course.mentorName,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                          if (course.departmentName != null) ...[
                            const SizedBox(width: 24),
                            Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.3)),
                            const SizedBox(width: 24),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Đơn vị',
                                  style: TextStyle(fontSize: 11, color: Color(0xFFD0E8FF), fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  course.departmentName!,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ─── Stats Row ───
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
                    if (course.deadlineType != null) ...[
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
                    ],
                    if (course.deadlineStatus != null && course.deadlineStatus!.isNotEmpty) ...[
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

                // ─── Syllabus ───
                _SyllabusHeader(
                  moduleCount: course.moduleCount,
                  lessonCount: course.lessonCount,
                  modulesWithState: _buildSyllabusModules(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String get _deadlineStatusLabel {
    switch (widget.course.deadlineStatus?.toUpperCase()) {
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
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
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

class _SyllabusHeader extends StatelessWidget {
  final int moduleCount;
  final int lessonCount;
  final List<SyllabusModule> modulesWithState;

  const _SyllabusHeader({
    required this.moduleCount,
    required this.lessonCount,
    required this.modulesWithState,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Nội dung khóa học',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
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
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF137FEC)),
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
                Icon(Icons.library_books_outlined, size: 48, color: Color(0xFFCBD5E1)),
                SizedBox(height: 12),
                Text('Chưa có chương nào', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                SizedBox(height: 4),
                Text('Khóa học chưa có nội dung nào được thêm vào.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)), textAlign: TextAlign.center),
              ],
            ),
          )
        else
          SyllabusSection(
            modules: modulesWithState,
            onLessonTap: (moduleIdx, lessonIdx) {},
          ),
      ],
    );
  }
}

class _AdminPreviewHeader extends StatelessWidget {
  final List<BreadcrumbItem>? breadcrumbs;
  final VoidCallback onBack;

  const _AdminPreviewHeader({this.breadcrumbs, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (breadcrumbs != null && breadcrumbs!.isNotEmpty) ...[
            SharedBreadcrumb(
              items: breadcrumbs!,
              primaryColor: const Color(0xFF6366F1),
              fontSize: 12,
              padding: const EdgeInsets.only(bottom: 4),
            ),
          ],
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
                tooltip: 'Quay về',
                color: const Color(0xFF64748B),
              ),
              const Text(
                'Chi tiết khóa học',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              const Icon(Icons.visibility_outlined, size: 20, color: Color(0xFF6366F1)),
              const SizedBox(width: 6),
              const Text(
                'Chỉ xem trước',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6366F1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
