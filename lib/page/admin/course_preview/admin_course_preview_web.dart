import 'package:flutter/material.dart';
import 'package:smet/model/Employee_course_model.dart';
import 'package:smet/page/employee/course_detail/widgets/hero_section.dart';
import 'package:smet/page/employee/course_detail/widgets/course_stats_section.dart';
import 'package:smet/page/employee/course_detail/widgets/syllabus_section.dart';
import 'package:smet/page/employee/course_detail/widgets/instructor_section.dart';
import 'package:smet/page/employee/course_detail/widgets/reviews_section.dart';
import 'package:smet/page/employee/course_detail/widgets/offered_by_section.dart';
import 'package:smet/page/employee/course_detail/widgets/enroll_card.dart';
import 'package:smet/page/employee/course_detail/widgets/course_info_card.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';

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
        lessonCount: m.lessonCount,
        lessons: m.lessons
            .map((l) => SyllabusLesson(
                  title: l,
                  type: SyllabusLessonType.video,
                  isCompleted: false,
                ))
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

  List<ReviewItem> _buildReviewItems() {
    return widget.course.reviews
        .map((r) => ReviewItem(
              rating: r.rating,
              comment: r.comment,
              userName: r.userName,
              avatarUrl: r.avatarUrl,
            ))
        .toList();
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
                // ─── Hero ───
                HeroSection(
                  title: course.title,
                  description: course.description,
                  imageUrl: course.imageUrl,
                  duration: course.duration,
                  level: course.level,
                  rating: course.rating,
                  studentsCount: course.studentsCount,
                  isBestSeller: course.isBestSeller,
                  category: course.category,
                  instructorName: course.instructor.name,
                  instructorAvatar: course.instructor.avatarUrl,
                  instructorBio: course.instructor.bio,
                ),
                const SizedBox(height: 24),

                // ─── Stats row ───
                CourseStatsSection(
                  videoHours: course.videoHours,
                  resources: course.resources,
                  hasCertificate: course.hasCertificate,
                ),
                const SizedBox(height: 32),

                // ─── 2-column layout ───
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Left column ───
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          OfferedBySection(
                            departmentName: course.departmentName,
                            mentorName: course.instructor.name,
                          ),
                          const SizedBox(height: 32),

                          SyllabusSection(
                            modules: _buildSyllabusModules(),
                          ),
                          const SizedBox(height: 32),

                          InstructorSection(
                            name: course.instructor.name,
                            title: course.instructor.title,
                            avatarUrl: course.instructor.avatarUrl,
                            bio: course.instructor.bio,
                            linkedInUrl: course.instructor.linkedInUrl,
                            websiteUrl: course.instructor.websiteUrl,
                          ),
                          const SizedBox(height: 32),

                          if (course.reviews.isNotEmpty) ...[
                            ReviewsSection(
                              reviews: _buildReviewItems(),
                              averageRating: course.rating,
                            ),
                            const SizedBox(height: 32),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(width: 24),

                    // ─── Right column (sticky sidebar) ───
                    SizedBox(
                      width: 360,
                      child: Column(
                        children: [
                          // EnrollCard — all actions disabled in preview
                          EnrollCard(
                            onEnroll: null,
                            onStartLearning: null,
                            videoHours: course.videoHours,
                            resources: course.resources,
                            hasCertificate: course.hasCertificate,
                            enrolledCount: course.enrolledCount,
                            isEnrolled: false,
                            imageUrl: course.imageUrl,
                          ),
                          const SizedBox(height: 16),

                          CourseInfoCard(
                            deadlineType: course.deadlineType,
                            defaultDeadlineDays: course.defaultDeadlineDays,
                            fixedDeadline: course.fixedDeadline,
                            courseTitle: course.title,
                          ),
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

class _AdminPreviewHeader extends StatelessWidget {
  final List<BreadcrumbItem>? breadcrumbs;
  final VoidCallback onBack;

  const _AdminPreviewHeader({
    this.breadcrumbs,
    required this.onBack,
  });

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
