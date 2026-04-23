import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/model/department_model.dart';
import 'package:smet/service/mentor/course_service.dart';
import 'package:smet/service/mentor/module_service.dart';
import 'package:smet/service/mentor/lesson_service.dart';
import 'package:smet/service/mentor/quiz_service.dart';
import 'package:smet/service/common/auth_service.dart';

/// Mentor Course Detail / Edit - Mobile Layout
class MentorCourseDetailMobile extends StatefulWidget {
  final String? courseId;

  const MentorCourseDetailMobile({super.key, this.courseId});

  @override
  State<MentorCourseDetailMobile> createState() =>
      _MentorCourseDetailMobileState();
}

class _MentorCourseDetailMobileState extends State<MentorCourseDetailMobile> {
  static const _primary = Color(0xFF137FEC);

  final MentorCourseService _courseService = MentorCourseService();
  final MentorModuleService _moduleService = MentorModuleService();
  final MentorLessonService _lessonService = MentorLessonService();
  final MentorQuizService _quizService = MentorQuizService();

  CourseDetailResponse? _course;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  bool _isEditMode = false;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _deadlineDaysController;
  DeadlineType _deadlineType = DeadlineType.RELATIVE;
  int _deadlineDays = 20;
  DateTime? _fixedDeadline;

  /// Level: 1=Beginner, 2=Intermediate, 3=Advanced
  int _selectedLevel = 1;
  int _initialLevel = 1;
  DepartmentModel? _department;
  bool _loadingDepartment = false;

  List<ModuleResponse> _modules = [];

  bool get _canEdit =>
      _course != null &&
      _course!.courseStatus == CourseStatus.DRAFT;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _deadlineDaysController = TextEditingController(text: _deadlineDays.toString());

    if (widget.courseId != null && widget.courseId!.isNotEmpty) {
      _isEditMode = true;
      _loadCourse();
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _deadlineDaysController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartment() async {
    setState(() => _loadingDepartment = true);
    try {
      final userData = await AuthService.getMe();
      final userDeptId = userData['departmentId'] as int?;
      final userDeptName = userData['departmentName'] as String?;
      if (userDeptId != null && userDeptName != null) {
        setState(() {
          _department = DepartmentModel(
            id: userDeptId,
            name: userDeptName,
            code: userData['departmentCode']?.toString() ?? '',
            isActive: true,
          );
          _loadingDepartment = false;
        });
        return;
      }
    } catch (e) {
      log("Could not get current user from auth/me: $e");
    }
    setState(() {
      _department = null;
      _loadingDepartment = false;
    });
  }

  Future<void> _loadCourse() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final course = await _courseService.getCourseDetail(
        Long(int.parse(widget.courseId!)),
      );
      setState(() {
        _course = course;
        _titleController.text = course.title;
        _descriptionController.text = course.description ?? '';
        _deadlineType = _parseDeadlineType(course.deadlineType);
        _deadlineDays = course.defaultDeadlineDays ?? 20;
        _deadlineDaysController.text = _deadlineDays.toString();
        _fixedDeadline = course.fixedDeadline;

        // Load level
        _selectedLevel = course.level ?? 1;
        _initialLevel = _selectedLevel;

        // Load department from course data
        if (course.departmentId != null && course.departmentName != null) {
          _department = DepartmentModel(
            id: course.departmentId!,
            name: course.departmentName!,
            code: course.departmentCode ?? '',
            isActive: true,
          );
        } else {
          _loadDepartment();
        }
      });
      await _loadModules();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadModules() async {
    if (_course == null) return;
    try {
      final modules = await _moduleService.getModulesByCourse(_course!.id);
      final modulesWithLessons = await Future.wait(
        modules.map((m) async {
          try {
            final lessons = await _lessonService.getLessonsByModule(m.id);
            return ModuleResponse(
              id: m.id,
              title: m.title,
              orderIndex: m.orderIndex,
              lessons: lessons,
              quizId: m.quizId,
            );
          } catch (_) {
            return m;
          }
        }),
      );
      if (mounted) {
        setState(() => _modules = modulesWithLessons);
      }
    } catch (e) {
      log("  [WARN] Failed to load modules: $e");
    }
  }

  Future<void> _saveCourse() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập tiêu đề")),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final request = UpdateCourseRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        defaultDeadlineDays: _deadlineDays,
        deadlineType: _deadlineType.name,
        fixedDeadline: _fixedDeadline?.toIso8601String(),
        level: _selectedLevel != _initialLevel ? _selectedLevel : null,
      );
      await _courseService.updateCourse(_course!.id, request);
      await _loadCourse();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lưu thành công"),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')}'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _publishCourse() async {
    // === VALIDATION FRONTEND ===
    if (_modules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Không thể gửi phê duyệt: Khóa học phải có ít nhất 1 module."),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }
    final emptyModule = _modules.where((m) => m.lessons.isEmpty).toList();
    if (emptyModule.isNotEmpty) {
      final names = emptyModule.map((m) => '"${m.title}"').join(', ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể gửi phê duyệt: Module $names chưa có bài học nào.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }
    // === END VALIDATION ===

    try {
      await _courseService.submitCourse(_course!.id);
      await _loadCourse();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đã gửi phê duyệt thành công"),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')}'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  DeadlineType _parseDeadlineType(String? value) {
    if (value == null) return DeadlineType.RELATIVE;
    return value.toUpperCase() == 'FIXED' ? DeadlineType.FIXED : DeadlineType.RELATIVE;
  }

  // ============================================
  // DIALOG HELPERS
  // ============================================

  InputDecoration _field(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF94A3B8), size: 20) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
    );
  }

  Future<void> _showAddModuleDialog() async {
    final titleController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.library_add, color: _primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Text("Thêm Chương mới"),
          ],
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: titleController,
            autofocus: true,
            decoration: _field("Tên chương", icon: Icons.bookmark_add_outlined),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? "Vui lòng nhập tên chương" : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy", style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Thêm"),
          ),
        ],
      ),
    );

    if (result == true && titleController.text.trim().isNotEmpty && _course != null) {
      try {
        final request = CreateModuleRequest(
          title: titleController.text.trim(),
          orderIndex: _modules.length,
          courseId: _course!.id,
        );
        await _moduleService.createModule(request);
        await _loadCourse();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Thêm chương thành công"),
              backgroundColor: Color(0xFF22C55E),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')}'), backgroundColor: const Color(0xFFEF4444)),
          );
        }
      }
    }
  }

  Future<void> _showAddLessonDialog(ModuleResponse module) async {
    String lessonType = 'TEXT';
    final contentController = TextEditingController();
    final videoController = TextEditingController();
    final titleController = TextEditingController();
    final durationController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.play_circle_filled, color: _primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Bài học: ${module.title}",
                  style: const TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: _field("Tên bài học", icon: Icons.title),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? "Vui lòng nhập tên bài học" : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: lessonType,
                    decoration: _field("Loại nội dung", icon: Icons.category_outlined),
                    items: const [
                      DropdownMenuItem(value: 'TEXT', child: Text("Văn bản")),
                      DropdownMenuItem(value: 'VIDEO', child: Text("Video")),
                      DropdownMenuItem(value: 'LINK', child: Text("Tài liệu")),
                    ],
                    onChanged: (v) => setStateDialog(() => lessonType = v!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: durationController,
                    keyboardType: TextInputType.number,
                    decoration: _field("Thời lượng (phút)", icon: Icons.timer_outlined),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return "Vui lòng nhập thời lượng";
                      final n = int.tryParse(v.trim());
                      if (n == null || n < 1) return "Thời lượng phải >= 1 phút";
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  if (lessonType == 'TEXT' || lessonType == 'LINK')
                    TextField(
                      controller: contentController,
                      maxLines: 3,
                      decoration: _field(
                        lessonType == 'LINK' ? "Link tài liệu" : "Nội dung",
                        icon: lessonType == 'LINK' ? Icons.link : Icons.article_outlined,
                      ),
                    ),
                  if (lessonType == 'VIDEO')
                    TextField(
                      controller: videoController,
                      decoration: _field("YouTube URL", icon: Icons.videocam_outlined),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Hủy", style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Thêm"),
            ),
          ],
        ),
      ),
    );

    if (result == true && titleController.text.trim().isNotEmpty) {
      try {
        final request = CreateLessonRequest(
          title: titleController.text.trim(),
          orderIndex: module.lessonCount,
          moduleId: module.id,
          contentType: lessonType,
          content: lessonType != 'VIDEO' ? contentController.text : null,
          videoUrl: lessonType == 'VIDEO' ? videoController.text : null,
          durationMinutes: int.tryParse(durationController.text.trim()),
        );
        await _lessonService.createLesson(request);
        await _loadCourse();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Thêm bài học thành công"),
              backgroundColor: Color(0xFF22C55E),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')}'), backgroundColor: const Color(0xFFEF4444)),
          );
        }
      }
    }
  }

  Future<void> _deleteModule(ModuleResponse module) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
            ),
            const SizedBox(width: 12),
            const Text("Xóa chương"),
          ],
        ),
        content: Text(
          "Bạn có chắc muốn xóa chương \"${module.title}\" và tất cả bài học trong đó?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy", style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _moduleService.deleteModule(module.id);
        await _loadCourse();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Xóa chương thành công"),
              backgroundColor: Color(0xFF22C55E),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')}'), backgroundColor: const Color(0xFFEF4444)),
          );
        }
      }
    }
  }

  Future<void> _deleteLesson(ModuleResponse module, LessonResponse lesson) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
            ),
            const SizedBox(width: 12),
            const Text("Xóa bài học"),
          ],
        ),
        content: Text("Bạn có chắc muốn xóa bài học \"${lesson.title}\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy", style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _lessonService.deleteLesson(lesson.id);
        await _loadCourse();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Xóa bài học thành công"),
              backgroundColor: Color(0xFF22C55E),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')}'), backgroundColor: const Color(0xFFEF4444)),
          );
        }
      }
    }
  }

  Future<void> _deleteModuleQuiz(ModuleResponse module) async {
    if (module.quizId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
            ),
            const SizedBox(width: 12),
            const Text("Xóa Quiz"),
          ],
        ),
        content: const Text("Bạn có chắc muốn xóa quiz của chương này? Tất cả câu hỏi trong quiz cũng sẽ bị xóa."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy", style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _quizService.deleteQuiz(module.quizId!);
        await _loadCourse();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Xóa quiz thành công"),
              backgroundColor: Color(0xFF22C55E),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')}'), backgroundColor: const Color(0xFFEF4444)),
          );
        }
      }
    }
  }

  void _openModuleQuiz(ModuleResponse module) {
    final cid = _course!.id.value;
    if (module.quizId != null) {
      context.go(
        '/mentor/quizzes/create?quizId=${module.quizId!.value}&moduleId=${module.id.value}&courseId=$cid',
      );
    } else {
      context.go(
        '/mentor/quizzes/create?moduleId=${module.id.value}&courseId=$cid',
      );
    }
  }

  Widget _buildLessonContent(LessonResponse lesson) {
    // Sử dụng primary helper để lấy content đầu tiên
    final primary = lesson.firstContent;
    final contentType = primary?.type;
    final lessonContent = primary?.content;
    final videoUrl = primary?.videoUrl;

    switch (contentType) {
      case LessonContentType.VIDEO:
        return Row(
          children: [
            const Icon(Icons.videocam_outlined, size: 12, color: _primary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                videoUrl ?? '',
                style: const TextStyle(fontSize: 11, color: _primary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      case LessonContentType.LINK:
        return Row(
          children: [
            const Icon(Icons.link, size: 12, color: _primary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                lessonContent ?? '',
                style: const TextStyle(fontSize: 11, color: _primary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      default:
        return Text(
          lessonContent ?? '',
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => context.go('/mentor/courses'),
        ),
        title: Text(
          _course?.title ?? "Chi tiết khóa học",
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        actions: [
          if (_isEditMode && _canEdit) ...[
            if (!_course!.isPublished)
              TextButton.icon(
                onPressed: _publishCourse,
                icon: const Icon(Icons.publish, size: 18),
                label: const Text("Gửi phê duyệt", style: TextStyle(fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF22C55E)),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveCourse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check, size: 18),
                          SizedBox(width: 4),
                          Text("Lưu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
              ),
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, size: 32, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadCourse,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Thử lại"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_course != null) ...[
            _buildStatusRow(),
            if (!_canEdit)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _course!.courseStatus == CourseStatus.ARCHIVED
                            ? 'Khóa học đã lưu trữ. Không thể chỉnh sửa cấu trúc.'
                            : 'Khóa học đã được phê duyệt. Không thể chỉnh sửa module, bài học và quiz.',
                        style: const TextStyle(fontSize: 12, color: Color(0xFFF59E0B)),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
          ],

          // Thông tin cơ bản
          _buildCard(
            header: _cardHeader("Thông tin khóa học", Icons.book_outlined),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  enabled: _canEdit,
                  decoration: _field("Tên khóa học *", icon: Icons.school_outlined),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  enabled: _canEdit,
                  decoration: _field("Mô tả khóa học", icon: Icons.description_outlined),
                  maxLines: 4,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Phòng ban
          _buildCard(
            header: _cardHeader("Phòng ban", Icons.business_outlined),
            child: Column(
              children: [
                _buildDepartmentBadge(),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Cấp độ
          _buildCard(
            header: _cardHeader("Cấp độ", Icons.signal_cellular_alt_outlined),
            child: Column(
              children: [
                _buildLevelSelector(),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Hạn nộp bài
          _buildCard(
            header: _cardHeader("Hạn nộp bài", Icons.timer_outlined),
            child: Column(
              children: [
                _buildDeadlineSelector(enabled: _canEdit),
                const SizedBox(height: 12),
                if (_deadlineType == DeadlineType.RELATIVE)
                  Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: _deadlineDaysController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          enabled: _canEdit,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.numbers, size: 18, color: Color(0xFF94A3B8)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _primary, width: 2),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFFAFAFA),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                          onChanged: (v) => _deadlineDays = int.tryParse(v) ?? 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "ngày sau đăng ký",
                          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  )
                else
                  _DatePickerButton(
                    selectedDate: _fixedDeadline,
                    primaryColor: _primary,
                    enabled: _canEdit,
                    onPicked: (date) => setState(() => _fixedDeadline = date),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Cấu trúc khóa học
          _buildCard(
            header: Row(
              children: [
                _cardHeader("Cấu trúc (${_modules.length} chương)", Icons.account_tree_outlined),
                const Spacer(),
                if (_canEdit)
                  TextButton.icon(
                    onPressed: _showAddModuleDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Thêm", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      foregroundColor: _primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                  ),
              ],
            ),
            child: _modules.isEmpty
                ? _buildEmptyState(
                    icon: Icons.library_books_outlined,
                    title: "Chưa có chương nào",
                    subtitle: "Nhấn \"Thêm\" để tạo chương đầu tiên.",
                  )
                : _buildModulesList(),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatusRow() {
    final course = _course!;
    final isPublished = course.isPublished;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isPublished
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPublished
              ? const Color(0xFF22C55E).withValues(alpha: 0.3)
              : const Color(0xFFF59E0B).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPublished ? Icons.check_circle : Icons.pending_outlined,
            size: 16,
            color: isPublished ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
          ),
          const SizedBox(width: 8),
          Text(
            course.statusLabel,
            style: TextStyle(
              color: isPublished ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 14, color: isPublished
              ? const Color(0xFF22C55E).withValues(alpha: 0.3)
              : const Color(0xFFF59E0B).withValues(alpha: 0.3)),
          const SizedBox(width: 16),
          Icon(Icons.view_module, size: 14, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Text(
            "${course.moduleCount} chương",
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(width: 12),
          Icon(Icons.play_lesson, size: 14, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Text(
            "${course.lessonCount} bài",
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentBadge() {
    if (_loadingDepartment) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
            ),
            const SizedBox(width: 12),
            Text("Đang xác định phòng ban...", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.business, color: _primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _department?.name ?? "Không xác định được",
                  style: TextStyle(
                    fontSize: 14, color: _department != null ? const Color(0xFF0F172A) : Colors.grey[600], fontWeight: FontWeight.w500,
                  ),
                ),
                if (_department != null && _department!.code.isNotEmpty)
                  Text(_department!.code, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 12, color: const Color(0xFF22C55E)),
                const SizedBox(width: 4),
                Text("Auto", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF22C55E))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSelector() {
    return Row(
      children: [
        Expanded(
          child: _LevelOption(
            label: "Sơ cấp", sublabel: "L1", icon: Icons.star_border,
            isSelected: _selectedLevel == 1,
            color: const Color(0xFF22C55E),
            onTap: _canEdit ? () => setState(() => _selectedLevel = 1) : () {},
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _LevelOption(
            label: "Trung cấp", sublabel: "L2", icon: Icons.star_half,
            isSelected: _selectedLevel == 2,
            color: const Color(0xFFF59E0B),
            onTap: _canEdit ? () => setState(() => _selectedLevel = 2) : () {},
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _LevelOption(
            label: "Cao cấp", sublabel: "L3", icon: Icons.star,
            isSelected: _selectedLevel == 3,
            color: const Color(0xFFEF4444),
            onTap: _canEdit ? () => setState(() => _selectedLevel = 3) : () {},
          ),
        ),
      ],
    );
  }

  Widget _buildDeadlineSelector({bool enabled = true}) {
    return Row(
      children: [
        Expanded(
          child: _DeadlineOption(
            label: "Tương đối",
            icon: Icons.schedule,
            isSelected: _deadlineType == DeadlineType.RELATIVE,
            onTap: enabled ? () => setState(() => _deadlineType = DeadlineType.RELATIVE) : () {},
            primaryColor: _primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _DeadlineOption(
            label: "Ngày cố định",
            icon: Icons.event,
            isSelected: _deadlineType == DeadlineType.FIXED,
            onTap: enabled ? () => setState(() => _deadlineType = DeadlineType.FIXED) : () {},
            primaryColor: _primary,
          ),
        ),
      ],
    );
  }

  Widget _buildModulesList() {
    return Column(
      children: _modules.asMap().entries.map((entry) {
        final module = entry.value;
        return _buildModuleItem(module, entry.key);
      }).toList(),
    );
  }

  Widget _buildModuleItem(ModuleResponse module, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              "${index + 1}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: _primary,
                fontSize: 13,
              ),
            ),
          ),
        ),
        title: Text(
          module.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF0F172A),
          ),
        ),
        subtitle: Text(
          module.quizId != null
              ? "${module.lessonCount} bài học · Đã gắn quiz"
              : "${module.lessonCount} bài học",
          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_canEdit) IconButton(
              icon: const Icon(Icons.add, size: 20, color: _primary),
              tooltip: "Thêm bài học",
              onPressed: () => _showAddLessonDialog(module),
              visualDensity: VisualDensity.compact,
            ),
            if (_canEdit) IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFEF4444)),
              tooltip: "Xóa chương",
              onPressed: () => _deleteModule(module),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        children: [
          if (module.lessons.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "Chưa có bài học nào",
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
            )
          else
            ...module.lessons.map((lesson) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              leading: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.play_arrow, size: 16, color: Color(0xFF64748B)),
              ),
              title: Text(
                lesson.title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              subtitle: _buildLessonContent(lesson),
              dense: true,
              trailing: _canEdit
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                      tooltip: "Xóa bài học",
                      onPressed: () => _deleteLesson(module, lesson),
                      visualDensity: VisualDensity.compact,
                    )
                  : null,
            )),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.quiz_outlined, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      const Text(
                        "Quiz",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: module.quizId != null
                              ? const Color(0xFF6366F1).withValues(alpha: 0.1)
                              : const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          module.quizId != null ? "Đã tạo" : "Chưa tạo",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: module.quizId != null ? const Color(0xFF6366F1) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_canEdit && module.quizId != null)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          tooltip: "Xóa quiz",
                          onPressed: () => _deleteModuleQuiz(module),
                          style: IconButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      TextButton.icon(
                        onPressed: _canEdit ? () => _openModuleQuiz(module) : null,
                        icon: Icon(
                          module.quizId != null ? Icons.edit_outlined : Icons.add,
                          size: 16,
                          color: module.quizId != null
                              ? const Color(0xFF6366F1)
                              : (_canEdit ? _primary : const Color(0xFFE5E7EB)),
                        ),
                        label: Text(
                          module.quizId != null ? "Sửa" : "Tạo",
                          style: TextStyle(
                            fontSize: 12,
                            color: module.quizId != null
                                ? const Color(0xFF6366F1)
                                : (_canEdit ? _primary : const Color(0xFFE5E7EB)),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: module.quizId != null
                              ? const Color(0xFF6366F1)
                              : (_canEdit ? _primary : const Color(0xFFE5E7EB)),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, color: _primary, size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget header, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: header,
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 26, color: Color(0xFFCBD5E1)),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DeadlineOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color primaryColor;

  const _DeadlineOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor.withValues(alpha: 0.1) : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? primaryColor : const Color(0xFFE5E7EB),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? primaryColor : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? primaryColor : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _LevelOption extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _LevelOption({
    required this.label, required this.sublabel, required this.icon,
    required this.isSelected, required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: isSelected ? color : const Color(0xFF94A3B8)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: isSelected ? color : const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 9,
                color: isSelected ? color.withValues(alpha: 0.7) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  final DateTime? selectedDate;
  final Color primaryColor;
  final ValueChanged<DateTime> onPicked;
  final bool enabled;

  const _DatePickerButton({
    required this.selectedDate,
    required this.primaryColor,
    required this.onPicked,
    this.enabled = true,
  });

  String _format(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled
          ? () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: primaryColor,
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: const Color(0xFF0F172A),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) onPicked(picked);
            }
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selectedDate != null ? primaryColor : const Color(0xFFE5E7EB),
            width: selectedDate != null ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 20,
              color: selectedDate != null ? primaryColor : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedDate != null ? _format(selectedDate!) : 'Chọn ngày deadline',
                style: TextStyle(
                  fontSize: 15,
                  color: selectedDate != null ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                  fontWeight: selectedDate != null ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            if (selectedDate != null)
              GestureDetector(
                onTap: () => onPicked(DateTime(1900)),
                child: const Icon(Icons.clear, size: 18, color: Color(0xFF94A3B8)),
              ),
          ],
        ),
      ),
    );
  }
}
