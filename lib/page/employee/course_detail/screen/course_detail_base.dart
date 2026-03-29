import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/employee/course_detail/screen/course_detail_web.dart';
import 'package:smet/page/employee/course_detail/screen/course_detail_mobile.dart';
import 'package:smet/page/employee/course_detail/widgets/hero_section.dart';
import 'package:smet/page/employee/course_detail/widgets/course_stats_section.dart';
import 'package:smet/page/employee/course_detail/widgets/syllabus_section.dart';
import 'package:smet/page/employee/course_detail/widgets/instructor_section.dart';
import 'package:smet/page/employee/course_detail/widgets/reviews_section.dart';
import 'package:smet/page/employee/course_detail/widgets/offered_by_section.dart';
import 'package:smet/page/employee/course_detail/widgets/enroll_card.dart';
import 'package:smet/page/employee/course_detail/widgets/course_info_card.dart';
import 'package:smet/service/employee/course_service.dart';
import 'package:smet/model/Employee_course_model.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';

class CourseDetailPage extends StatefulWidget {
  final String courseId;

  const CourseDetailPage({super.key, required this.courseId});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  CourseDetail? _course;
  bool _isLoading = true;
  String? _error;
  bool _isEnrolled = false;
  bool _isEnrolling = false;
  double _progressPercent = 0;

  // Track expanded modules
  final Map<int, bool> _expandedModules = {};

  @override
  void initState() {
    super.initState();
    _loadCourseDetail();
  }

  Future<void> _loadCourseDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final course = await CourseService.getCourseDetail(widget.courseId);
      final enrolled = await CourseService.isEnrolled(widget.courseId);

      // Initialize expanded state for modules
      for (var i = 0; i < course.modules.length; i++) {
        _expandedModules[i] = course.modules[i].isExpanded;
      }

      // Load progress if enrolled
      double progress = 0;
      if (enrolled) {
        try {
          final learningCourse = await CourseService.getCourseProgress(widget.courseId);
          if (learningCourse != null) {
            progress = learningCourse.progressPercent;
          }
        } catch (_) {
          // Progress API may not be available, ignore
        }
      }

      setState(() {
        _course = course;
        _isEnrolled = enrolled;
        _progressPercent = progress;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading course detail: $e');
      setState(() {
        _error = 'Không thể tải thông tin khóa học';
        _isLoading = false;
      });
    }
  }

  void _toggleModule(int index) {
    setState(() {
      _expandedModules[index] = !(_expandedModules[index] ?? false);
    });
  }

  Future<void> _onEnroll() async {
    setState(() => _isEnrolling = true);

    try {
      final success = await CourseService.enrollCourse(widget.courseId);
      if (success) {
        setState(() => _isEnrolled = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng ký thành công!'),
              backgroundColor: Color(0xFF22C55E),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng ký thất bại: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isEnrolling = false);
    }
  }

  void _onStartLearning() {
    context.go('/employee/learn/${widget.courseId}');
  }

  void _onNavigateTo(String path) {
    context.go(path);
  }

  void _onLogout() {
    context.go('/login');
  }

  void _onShare() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã sao chép liên kết khóa học!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _onBookmark() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu khóa học!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ─── Build Hero ───
  Widget buildHero() {
    if (_course == null) return const SizedBox.shrink();

    return HeroSection(
      title: _course!.title,
      description: _course!.description,
      imageUrl: _course!.imageUrl,
      duration: _course!.duration,
      level: _course!.level,
      rating: _course!.rating,
      studentsCount: _course!.studentsCount,
      isBestSeller: _course!.isBestSeller,
      category: _course!.category,
      instructorName: _course!.instructor.name,
      instructorAvatar: _course!.instructor.avatarUrl,
    );
  }

  // ─── Build Course Stats ───
  Widget buildCourseStats() {
    if (_course == null) return const SizedBox.shrink();

    return CourseStatsSection(
      videoHours: _course!.videoHours,
      resources: _course!.resources,
      hasCertificate: _course!.hasCertificate,
    );
  }

  // ─── Build Syllabus ───
  Widget buildSyllabus() {
    if (_course == null) return const SizedBox.shrink();

    final modulesWithState = _course!.modules.asMap().entries.map((entry) {
      final index = entry.key;
      final module = entry.value;
      return SyllabusModule(
        title: module.title,
        lessonCount: module.lessonCount,
        lessons: module.lessons
            .map((l) => SyllabusLesson(title: l, type: SyllabusLessonType.video))
            .toList(),
        isExpanded: _expandedModules[index] ?? false,
        onToggle: () => _toggleModule(index),
      );
    }).toList();

    return SyllabusSection(
      modules: modulesWithState,
      onLessonTap: (moduleIdx, lessonIdx) {
        // TODO: Navigate to specific lesson
        debugPrint('Tap lesson $lessonIdx in module $moduleIdx');
      },
    );
  }

  // ─── Build Instructor ───
  Widget buildInstructor() {
    if (_course == null) return const SizedBox.shrink();

    return InstructorSection(
      name: _course!.instructor.name,
      title: _course!.instructor.title,
      avatarUrl: _course!.instructor.avatarUrl,
      bio: _course!.instructor.bio,
      linkedInUrl: _course!.instructor.linkedInUrl,
      websiteUrl: _course!.instructor.websiteUrl,
      isTopInstructor: _course!.rating >= 4.5,
    );
  }

  // ─── Build Reviews ───
  Widget buildReviews() {
    if (_course == null) return const SizedBox.shrink();

    final reviewItems = _course!.reviews
        .map((r) => ReviewItem(
              rating: r.rating,
              comment: r.comment,
              userName: r.userName,
              avatarUrl: r.avatarUrl,
            ))
        .toList();

    return ReviewsSection(
      reviews: reviewItems,
      averageRating: _course!.rating,
      onSeeAll: () {
        // TODO: Navigate to all reviews page
      },
    );
  }

  // ─── Build Offered By ───
  Widget buildOfferedBy() {
    if (_course == null) return const SizedBox.shrink();

    return OfferedBySection(
      departmentName: _course!.departmentName,
      mentorName: _course!.instructor.name,
    );
  }

  // ─── Build Enroll Card ───
  Widget buildEnrollCard() {
    if (_course == null) return const SizedBox.shrink();

    return EnrollCard(
      onEnroll: () {
        if (!_isEnrolling) _onEnroll();
      },
      onStartLearning: _onStartLearning,
      videoHours: _course!.videoHours,
      resources: _course!.resources,
      hasCertificate: _course!.hasCertificate,
      enrolledCount: _course!.enrolledCount,
      isEnrolled: _isEnrolled,
      isLoading: _isEnrolling,
      progressPercent: _isEnrolled ? _progressPercent : null,
      imageUrl: _course!.imageUrl,
      onShare: _onShare,
      onBookmark: _onBookmark,
    );
  }

  // ─── Build Course Info Card ───
  Widget buildCourseInfoCard() {
    if (_course == null) return const SizedBox.shrink();

    return CourseInfoCard(
      deadlineType: _course!.deadlineType,
      defaultDeadlineDays: _course!.defaultDeadlineDays,
      fixedDeadline: _course!.fixedDeadline,
      onShare: _onShare,
      courseTitle: _course!.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF137FEC)),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(fontSize: 16, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCourseDetail,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (kIsWeb || constraints.maxWidth > 850) {
              return CourseDetailWeb(
                hero: buildHero(),
                courseStats: buildCourseStats(),
                syllabus: buildSyllabus(),
                instructor: buildInstructor(),
                reviews: buildReviews(),
                enrollCard: buildEnrollCard(),
                offeredBy: buildOfferedBy(),
                courseInfoCard: buildCourseInfoCard(),
                breadcrumbs: [
                  const BreadcrumbItem(
                    label: 'Trang chủ',
                    route: '/employee/dashboard',
                  ),
                  const BreadcrumbItem(
                    label: 'Danh mục khóa học',
                    route: '/employee/courses',
                  ),
                  BreadcrumbItem(label: _course?.title ?? 'Chi tiết khóa học'),
                ],
              );
            } else {
              return CourseDetailMobile(
                hero: buildHero(),
                courseStats: buildCourseStats(),
                syllabus: buildSyllabus(),
                instructor: buildInstructor(),
                reviews: buildReviews(),
                enrollCard: buildEnrollCard(),
                courseInfoCard: buildCourseInfoCard(),
                onNavigate: _onNavigateTo,
                onLogout: _onLogout,
              );
            }
          },
        ),
      ),
    );
  }
}
