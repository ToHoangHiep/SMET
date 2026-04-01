import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/model/learning_path_model.dart' as lp_model;
import 'package:smet/service/mentor/course_service.dart';
import 'package:smet/service/mentor/module_service.dart';
import 'package:smet/service/mentor/lesson_service.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:smet/service/mentor/lesson_content_service.dart';
import 'package:smet/service/mentor/quiz_service.dart';

/// Mentor Course Detail / Edit - Web Layout
class MentorCourseDetailWeb extends StatefulWidget {
  final String? courseId;

  const MentorCourseDetailWeb({super.key, this.courseId});

  @override
  State<MentorCourseDetailWeb> createState() => _MentorCourseDetailWebState();
}

class _MentorCourseDetailWebState extends State<MentorCourseDetailWeb>
    with SingleTickerProviderStateMixin {
  static const _primary = Color(0xFF137FEC);

  final MentorCourseService _courseService = MentorCourseService();
  final MentorModuleService _moduleService = MentorModuleService();
  final MentorLessonService _lessonService = MentorLessonService();
  final LessonContentService _lessonContentService = LessonContentService();
  final MentorQuizService _quizService = MentorQuizService();

  late TabController _tabController;
  CourseDetailResponse? _course;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  bool _isEditMode = false;

  bool _isLessonDialogOpen = false;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DeadlineType _deadlineType = DeadlineType.RELATIVE;
  int _deadlineDays = 20;
  DateTime? _fixedDeadline;

  List<ModuleResponse> _modules = [];
  Long? _finalQuizId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();

    if (widget.courseId != null && widget.courseId!.isNotEmpty) {
      _isEditMode = true;
      _loadCourse();
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
        _descriptionController.text = course.description;
        _deadlineType = course.deadlineType ?? DeadlineType.RELATIVE;
        _deadlineDays = course.defaultDeadlineDays ?? 20;
        _fixedDeadline = course.fixedDeadline;
      });
      await _loadModules();
      await _loadFinalQuizId();
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
      for (final m in modulesWithLessons) {
        log(
          '[QuizDebug] module id=${m.id.value} title="${m.title}" quizId=${m.quizId?.value} '
          '(UI "Đã tạo"/"Chưa tạo" theo quizId != null)',
        );
      }
    } catch (e) {
      log("  [WARN] Failed to load modules: $e");
    }
  }

  Future<void> _loadFinalQuizId() async {
    if (_course == null) return;
    try {
      final q = await _quizService.getFinalQuizByCourse(
        lp_model.Long(_course!.id.value),
      );
      if (mounted) {
        setState(() {
          _finalQuizId = q.id != null ? Long(q.id!.value) : null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _finalQuizId = null);
    }
  }

  Future<void> _saveCourse() async {
    if (!_isEditMode) return;

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập tiêu đề khóa học")),
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
      );

      await _courseService.updateCourse(_course!.id, request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lưu thành công"),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
        context.go('/mentor/courses?refresh=${DateTime.now().millisecondsSinceEpoch}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: $e"), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ============================================
  // ARCHIVE COURSE
  // ============================================
  Future<void> _archiveCourse() async {
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
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.archive_outlined, color: Color(0xFFF59E0B), size: 20),
            ),
            const SizedBox(width: 12),
            const Text("Lưu trữ khóa học"),
          ],
        ),
        content: const Text(
          "Bạn có chắc muốn lưu trữ khóa học này? Khóa học sẽ không còn hiển thị với nhân viên nhưng vẫn được giữ lại.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy", style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Lưu trữ"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _courseService.archiveCourse(_course!.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lưu trữ thành công"),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
      context.go(
        '/mentor/courses?refresh=${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: $e"), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  // ============================================
  // REORDER MODULES (drag-drop)
  // ============================================
  Future<void> _onModulesReorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;
    final List<ModuleResponse> reordered = List.from(_modules);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);

    setState(() => _modules = reordered);

    try {
      await _courseService.reorderModules(
        _course!.id,
        reordered.map((m) => Long(m.id.value)).toList(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đã sắp xếp lại thứ tự chương"),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      await _loadModules();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi sắp xếp: $e"), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  // ============================================
  // REORDER LESSONS (up / down)
  // ============================================
  Future<void> _moveLesson(ModuleResponse module, int lessonIndex, int direction) async {
    final lessons = List<LessonResponse>.from(module.lessons);
    final newIndex = lessonIndex + direction;
    if (newIndex < 0 || newIndex >= lessons.length) return;

    final item = lessons.removeAt(lessonIndex);
    lessons.insert(newIndex, item);

    setState(() {
      final idx = _modules.indexWhere((m) => m.id.value == module.id.value);
      if (idx != -1) {
        _modules[idx] = ModuleResponse(
          id: module.id,
          title: module.title,
          orderIndex: module.orderIndex,
          lessons: lessons,
          quizId: module.quizId,
        );
      }
    });

    try {
      await _lessonService.reorderLessons(
        module.id,
        lessons.map((l) => Long(l.id.value)).toList(),
      );
    } catch (e) {
      await _loadModules();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi sắp xếp: $e"), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  Future<void> _publishCourse() async {
    try {
      await _courseService.publishCourse(_course!.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Xuất bản thành công"),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
      context.go(
        '/mentor/courses?refresh=${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: $e"), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
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
            SnackBar(content: Text("Lỗi: $e"), backgroundColor: const Color(0xFFEF4444)),
          );
        }
      }
    }
  }

  Future<void> _showEditModuleDialog(ModuleResponse module) async {
    final controller = TextEditingController(text: module.title);
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
              child: const Icon(Icons.edit_outlined, color: _primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Text("Chỉnh sửa chương"),
          ],
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: _field("Tên chương", icon: Icons.bookmark_outlined),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? "Không được để trống" : null,
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
            child: const Text("Lưu"),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final request = CreateModuleRequest(
          title: controller.text.trim(),
          orderIndex: module.orderIndex,
          courseId: _course!.id,
        );
        await _moduleService.updateModule(module.id, request);
        await _loadCourse();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Cập nhật chương thành công"),
              backgroundColor: Color(0xFF22C55E),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Lỗi: $e"), backgroundColor: const Color(0xFFEF4444)),
          );
        }
      }
    }
  }

  Future<void> _showAddLessonDialog(ModuleResponse module) async {
    final titleController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String lessonType = 'TEXT';
    final contentController = TextEditingController();
    final videoController = TextEditingController();

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
                  if (lessonType == 'TEXT' || lessonType == 'LINK')
                    TextFormField(
                      controller: contentController,
                      maxLines: 3,
                      decoration: _field(
                        lessonType == 'LINK' ? "Link tài liệu" : "Nội dung",
                        icon: lessonType == 'LINK' ? Icons.link : Icons.article_outlined,
                      ),
                    ),
                  if (lessonType == 'VIDEO')
                    TextFormField(
                      controller: videoController,
                      decoration: _field("YouTube embed URL", icon: Icons.videocam_outlined),
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
        );
        final lesson = await _lessonService.createLesson(request);

        String contentValue;
        if (lessonType == 'VIDEO') {
          contentValue = videoController.text.trim();
        } else {
          contentValue = contentController.text.trim();
        }

        if (contentValue.isNotEmpty) {
          await _lessonContentService.createContent(
            lesson.id.value,
            {"type": lessonType, "content": contentValue, "orderIndex": 0},
          );
        }

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
            SnackBar(content: Text("Lỗi: $e"), backgroundColor: const Color(0xFFEF4444)),
          );
        }
      }
    }
  }

  Future<void> _showEditLessonDialog(ModuleResponse module, LessonResponse lesson) async {
    final titleController = TextEditingController(text: lesson.title);
    final contentController = TextEditingController(text: lesson.content ?? '');
    final videoController = TextEditingController(text: lesson.videoUrl ?? '');
    String lessonType = lesson.contentType ?? 'TEXT';
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
                child: const Icon(Icons.edit_outlined, color: _primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Text("Chỉnh sửa bài học"),
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
                  if (lessonType == 'TEXT' || lessonType == 'LINK')
                    TextFormField(
                      controller: contentController,
                      maxLines: 3,
                      decoration: _field(
                        lessonType == 'LINK' ? "Link tài liệu" : "Nội dung",
                        icon: lessonType == 'LINK' ? Icons.link : Icons.article_outlined,
                      ),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty && lessonType == 'TEXT') return "Vui lòng nhập nội dung";
                        if (value.isEmpty && lessonType == 'LINK') return "Vui lòng nhập link tài liệu";
                        if (lessonType == 'LINK') {
                          final lower = value.toLowerCase();
                          final isValid = lower.endsWith('.pdf') ||
                              lower.endsWith('.doc') ||
                              lower.endsWith('.docx');
                          if (!isValid) return "Chỉ chấp nhận link .pdf, .doc, .docx";
                        }
                        return null;
                      },
                    ),
                  if (lessonType == 'VIDEO')
                    TextFormField(
                      controller: videoController,
                      decoration: _field("YouTube URL", icon: Icons.videocam_outlined),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return "Vui lòng nhập link YouTube";
                        final lower = value.toLowerCase();
                        if (!lower.contains('youtube.com') && !lower.contains('youtu.be')) {
                          return "Chỉ chấp nhận link YouTube";
                        }
                        return null;
                      },
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
              child: const Text("Lưu"),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        final request = CreateLessonRequest(
          title: titleController.text.trim(),
          orderIndex: lesson.orderIndex,
          moduleId: module.id,
          contentType: lessonType,
          content: lessonType != 'VIDEO' ? contentController.text.trim() : null,
          videoUrl: lessonType == 'VIDEO' ? videoController.text.trim() : null,
        );

        await _lessonService.updateLesson(lesson.id, request);

        String contentValue = '';
        if (lessonType == 'VIDEO') {
          contentValue = videoController.text.trim();
        } else {
          contentValue = contentController.text.trim();
        }

        if (contentValue.isNotEmpty) {
          if (lesson.contentId != null) {
            await _lessonContentService.updateContent(lesson.id.value, lesson.contentId!.value, {
              "lessonId": lesson.id.value,
              "type": lessonType,
              "content": contentValue,
              "orderIndex": 0,
            });
          } else {
            await _lessonContentService.createContent(lesson.id.value, {
              "type": lessonType,
              "content": contentValue,
              "orderIndex": 0,
            });
          }
        }

        await _loadCourse();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Cập nhật bài học thành công"),
              backgroundColor: Color(0xFF22C55E),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Lỗi: $e"), backgroundColor: const Color(0xFFEF4444)),
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
            SnackBar(content: Text("Lỗi: $e"), backgroundColor: const Color(0xFFEF4444)),
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
            SnackBar(content: Text("Lỗi: $e"), backgroundColor: const Color(0xFFEF4444)),
          );
        }
      }
    }
  }

  String _convertYoutubeUrl(String url) {
    final value = url.trim();
    if (value.isEmpty) return '';

    final rawIdReg = RegExp(r'^[a-zA-Z0-9_-]{11}$');
    if (rawIdReg.hasMatch(value)) {
      return 'https://www.youtube.com/embed/$value';
    }

    final uri = Uri.tryParse(value);
    if (uri == null) return value;

    if (uri.host.contains('youtube.com')) {
      final videoId = uri.queryParameters['v'];
      if (videoId != null && videoId.isNotEmpty) {
        return 'https://www.youtube.com/embed/$videoId';
      }
      if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'embed') {
        return value;
      }
    }

    if (uri.host.contains('youtu.be')) {
      if (uri.pathSegments.isNotEmpty) {
        return 'https://www.youtube.com/embed/${uri.pathSegments.first}';
      }
    }

    return value;
  }

  Widget _buildLessonContent(LessonResponse lesson) {
    log("TYPE: ${lesson.contentType}");
    log("VIDEO URL: ${lesson.videoUrl}");

    if (_isLessonDialogOpen) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        height: 60,
        alignment: Alignment.centerLeft,
        child: const Text(
          "Đang chỉnh sửa bài học...",
          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
        ),
      );
    }

    switch (lesson.contentType) {
      case 'VIDEO':
        return _buildVideoIframe(lesson.videoUrl);
      case 'LINK':
        return InkWell(
          onTap: () {},
          child: Text(
            lesson.content ?? '',
            style: const TextStyle(
              fontSize: 12,
              color: _primary,
              decoration: TextDecoration.underline,
            ),
          ),
        );
      default:
        return Text(
          lesson.content ?? '',
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
    }
  }

  Widget _buildVideoIframe(String? url) {
    if (url == null || url.trim().isEmpty) {
      return const Text("Không có video", style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)));
    }

    final embedUrl = _convertYoutubeUrl(url);
    log("RAW VIDEO URL: $url");
    log("EMBED VIDEO URL: $embedUrl");

    final viewId = 'video-${embedUrl.hashCode}-${DateTime.now().millisecondsSinceEpoch}';

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(viewId, (int _) {
      final iframe = html.IFrameElement()
        ..src = embedUrl
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '200px'
        ..allow = 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share'
        ..allowFullscreen = true;

      return iframe;
    });

    return SizedBox(
      width: double.infinity,
      height: 200,
      child: HtmlElementView(viewType: viewId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFFEE2E2),
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
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // PAGE HEADER
        Padding(
          padding: const EdgeInsets.fromLTRB(30, 30, 30, 0),
          child: BreadcrumbPageHeader(
            pageTitle: _course?.title ?? "Chi tiết khóa học",
            pageIcon: Icons.menu_book_rounded,
            breadcrumbs: [
              const BreadcrumbItem(label: "Khóa học", route: "/mentor/courses"),
              BreadcrumbItem(label: _course?.title ?? "Chi tiết khóa học"),
            ],
            primaryColor: _primary,
            actions: [
              if (_isEditMode && _course != null) ...[
                OutlinedButton.icon(
                  onPressed: () {
                    final cid = _course!.id.value;
                    if (_finalQuizId != null) {
                      context.go(
                        '/mentor/quizzes/create?quizId=${_finalQuizId!.value}&courseId=$cid&final=true',
                      );
                    } else {
                      context.go(
                        '/mentor/quizzes/create?courseId=$cid&final=true',
                      );
                    }
                  },
                  icon: const Icon(Icons.quiz_outlined, size: 18),
                  label: Text(_finalQuizId != null ? 'Sửa Final Quiz' : 'Tạo Final Quiz'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _archiveCourse,
                  icon: const Icon(Icons.archive_outlined, size: 18),
                  label: const Text("Lưu trữ"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF59E0B),
                    side: const BorderSide(color: Color(0xFFF59E0B)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
                const SizedBox(width: 10),
                if (!_course!.isPublished) ...[
                  OutlinedButton.icon(
                    onPressed: _publishCourse,
                    icon: const Icon(Icons.publish, size: 18),
                    label: const Text("Xuất bản"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF22C55E),
                      side: const BorderSide(color: Color(0xFF22C55E)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveCourse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save, size: 18),
                  label: const Text("Lưu thay đổi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ],
            ],
          ),
        ),

        // TAB BAR
        Padding(
          padding: const EdgeInsets.only(top: 20, left: 30, right: 30),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              indicator: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(10),
              ),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, size: 18),
                      SizedBox(width: 6),
                      Text("Thông tin khóa học"),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_tree_outlined, size: 18),
                      SizedBox(width: 6),
                      Text("Cấu trúc khóa học"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // TAB CONTENT
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildInfoTab(), _buildStructureTab()],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT
          Expanded(
            flex: 2,
            child: _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_course != null) ...[
                    _buildStatusRow(),
                    const SizedBox(height: 20),
                  ],
                  _buildSectionHeader("Thông tin cơ bản", Icons.book_outlined),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    decoration: _field("Tên khóa học *", icon: Icons.school_outlined),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: _field("Mô tả khóa học", icon: Icons.description_outlined),
                    maxLines: 5,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 20),

          // RIGHT
          Expanded(
            child: _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("Hạn nộp bài", Icons.timer_outlined),
                  const SizedBox(height: 16),
                  _buildDeadlineSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow() {
    final course = _course!;
    final isPublished = course.isPublished;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isPublished ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
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
            size: 18,
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
          Container(width: 1, height: 14, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(width: 16),
          const Icon(Icons.view_module, size: 16, color: Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(
            "${_modules.length} chương",
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.play_lesson, size: 16, color: Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(
            "${_modules.fold(0, (sum, m) => sum + m.lessonCount)} bài học",
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Row(
            children: [
              Expanded(
                child: _DeadlineOption(
                  label: "Tương đối",
                  icon: Icons.schedule,
                  isSelected: _deadlineType == DeadlineType.RELATIVE,
                  onTap: () => setState(() => _deadlineType = DeadlineType.RELATIVE),
                  primaryColor: _primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DeadlineOption(
                  label: "Ngày cố định",
                  icon: Icons.event,
                  isSelected: _deadlineType == DeadlineType.FIXED,
                  onTap: () => setState(() => _deadlineType = DeadlineType.FIXED),
                  primaryColor: _primary,
                ),
              ),
            ],
          ),
        const SizedBox(height: 14),
        if (_deadlineType == DeadlineType.RELATIVE) ...[
          Row(
            children: [
              SizedBox(
                width: 90,
                child: TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
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
                  controller: TextEditingController(text: _deadlineDays.toString()),
                  onChanged: (v) => _deadlineDays = int.tryParse(v) ?? 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text("ngày sau ngày đăng ký", style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
            ],
          ),
        ] else ...[
          _DatePickerButton(
            selectedDate: _fixedDeadline,
            primaryColor: _primary,
            onPicked: (date) => setState(() => _fixedDeadline = date),
          ),
        ],
      ],
    );
  }

  Widget _buildStructureTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_tree_outlined, color: _primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "${_modules.length} Chương",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showAddModuleDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Thêm Chương", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_modules.isEmpty)
            _buildEmptyState()
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _modules.length,
              onReorder: _onModulesReorder,
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(16),
                      child: child,
                    );
                  },
                  child: child,
                );
              },
              itemBuilder: (context, index) {
                return _buildModuleCard(_modules[index], index, ValueKey(_modules[index].id));
              },
            ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(ModuleResponse module, int index, ValueKey itemKey) {
    return Container(
      key: itemKey,
      margin: const EdgeInsets.only(bottom: 16),
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
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: const EdgeInsets.only(bottom: 16),
        initiallyExpanded: index == 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              "${index + 1}",
              style: const TextStyle(fontWeight: FontWeight.bold, color: _primary, fontSize: 15),
            ),
          ),
        ),
        title: Text(
          module.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF0F172A)),
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
            ReorderDragHandle(
              index: index,
              onReorder: _onModulesReorder,
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: "Sửa chương",
              onPressed: () => _showEditModuleDialog(module),
              style: IconButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: "Xóa chương",
              onPressed: () => _deleteModule(module),
              style: IconButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            ),
          ],
        ),
        children: [
          // Add lesson header
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                    const Icon(Icons.list_alt, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    const Text(
                      "Danh sách bài học",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${module.lessons.length}",
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () async {
                    setState(() => _isLessonDialogOpen = true);
                    await Future.delayed(const Duration(milliseconds: 50));
                    await _showAddLessonDialog(module);
                    if (!mounted) return;
                    setState(() => _isLessonDialogOpen = false);
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Thêm bài học", style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(foregroundColor: _primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          if (module.lessons.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(
                "Chưa có bài học nào",
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
            )
          else
            ...List.generate(
              module.lessons.length,
              (i) => _buildLessonTile(module, module.lessons[i], i),
            ),

          // Quiz section
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                TextButton.icon(
                  onPressed: () {
                    if (module.quizId != null) {
                      context.go(
                        '/mentor/quizzes/create?quizId=${module.quizId!.value}&moduleId=${module.id.value}&courseId=${_course!.id.value}',
                      );
                    } else {
                      context.go(
                        '/mentor/quizzes/create?moduleId=${module.id.value}&courseId=${_course!.id.value}',
                      );
                    }
                  },
                  icon: Icon(
                    module.quizId != null ? Icons.edit_outlined : Icons.add,
                    size: 18,
                  ),
                  label: Text(
                    module.quizId != null ? "Sửa quiz" : "Tạo quiz",
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: module.quizId != null ? const Color(0xFF6366F1) : _primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonTile(ModuleResponse module, LessonResponse lesson, int lessonIndex) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_upward, size: 16),
            tooltip: "Di chuyển lên",
            onPressed: lessonIndex > 0
                ? () => _moveLesson(module, lessonIndex, -1)
                : null,
            style: IconButton.styleFrom(
              foregroundColor: lessonIndex > 0
                  ? const Color(0xFF64748B)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_downward, size: 16),
            tooltip: "Di chuyển xuống",
            onPressed: lessonIndex < module.lessons.length - 1
                ? () => _moveLesson(module, lessonIndex, 1)
                : null,
            style: IconButton.styleFrom(
              foregroundColor: lessonIndex < module.lessons.length - 1
                  ? const Color(0xFF64748B)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _lessonIcon(lesson.contentType),
              size: 16,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
      title: Text(
        lesson.title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: _buildLessonContent(lesson),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: "Sửa bài học",
            onPressed: () async {
              setState(() => _isLessonDialogOpen = true);
              await Future.delayed(const Duration(milliseconds: 50));
              await _showEditLessonDialog(module, lesson);
              if (!mounted) return;
              setState(() => _isLessonDialogOpen = false);
            },
            style: IconButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: "Xóa bài học",
            onPressed: () => _deleteLesson(module, lesson),
            style: IconButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
          ),
        ],
      ),
    );
  }

  IconData _lessonIcon(String? type) {
    switch (type) {
      case 'VIDEO':
        return Icons.videocam_outlined;
      case 'LINK':
        return Icons.link;
      default:
        return Icons.article_outlined;
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _primary, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: child,
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.library_books_outlined, size: 32, color: Color(0xFFCBD5E1)),
          ),
          const SizedBox(height: 16),
          const Text(
            "Chưa có chương nào",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Nhấn \"Thêm Chương\" để bắt đầu xây dựng cấu trúc khóa học.",
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
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
            Icon(icon, size: 18, color: isSelected ? primaryColor : const Color(0xFF94A3B8)),
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
      child: child,
    );
  }
}

class ReorderDragHandle extends StatelessWidget {
  final int index;
  final void Function(int, int) onReorder;

  const ReorderDragHandle({
    super.key,
    required this.index,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableDragStartListener(
      index: index,
      child: const MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: Icon(
          Icons.drag_indicator,
          size: 20,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  final DateTime? selectedDate;
  final Color primaryColor;
  final ValueChanged<DateTime> onPicked;

  const _DatePickerButton({
    required this.selectedDate,
    required this.primaryColor,
    required this.onPicked,
  });

  String _format(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
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
      },
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
                selectedDate != null ? _format(selectedDate!) : 'Chọn ngày',
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
