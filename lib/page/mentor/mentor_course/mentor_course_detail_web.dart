import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/page/shared/widgets/rich_text_editor.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/model/learning_path_model.dart' as lp_model;
import 'package:smet/service/mentor/course_service.dart';
import 'package:smet/service/mentor/module_service.dart';
import 'package:smet/service/mentor/lesson_service.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:smet/service/mentor/lesson_content_service.dart';
import 'package:smet/service/mentor/quiz_service.dart';
import 'package:smet/service/common/global_notification_service.dart';

/// Mentor Course Detail / Edit - Web Layout
/// UI mềm mại, phong cách Coursera cho phần cấu trúc khóa học.
class MentorCourseDetailWeb extends StatefulWidget {
  final String? courseId;

  const MentorCourseDetailWeb({super.key, this.courseId});

  @override
  State<MentorCourseDetailWeb> createState() => _MentorCourseDetailWebState();
}

class _MentorCourseDetailWebState extends State<MentorCourseDetailWeb>
    with SingleTickerProviderStateMixin {
  static const _primary = Color(0xFF6366F1);
  static const _primaryLight = Color(0xFF818CF8);
  static const _bgLight = Color(0xFFF3F6FC);
  static const _cardBorder = Color(0xFFE8ECF4);
  static const _textDark = Color(0xFF0F172A);
  static const _textMedium = Color(0xFF64748B);
  static const _textLight = Color(0xFF94A3B8);
  static const _success = Color(0xFF22C55E);
  static const _warning = Color(0xFFF59E0B);
  static const _danger = Color(0xFFEF4444);

  final MentorCourseService _courseService = MentorCourseService();
  final MentorModuleService _moduleService = MentorModuleService();
  final MentorLessonService _lessonService = MentorLessonService();
  final LessonContentService _lessonContentService = LessonContentService();
  final MentorQuizService _quizService = MentorQuizService();

  late TabController _tabController;
  late QuillController _quillController;

  CourseDetailResponse? _course;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  bool _isEditMode = false;
  bool _isLessonDialogOpen = false;

  late TextEditingController _titleController;
  late TextEditingController _deadlineDaysController;
  DeadlineType _deadlineType = DeadlineType.RELATIVE;
  int _deadlineDays = 20;
  DateTime? _fixedDeadline;

  String? _initialDescription;
  DeadlineType _initialDeadlineType = DeadlineType.RELATIVE;
  int _initialDeadlineDays = 20;
  DateTime? _initialFixedDeadline;

  List<ModuleResponse> _modules = [];

  bool get _canEdit =>
      _course != null &&
      _course!.courseStatus == CourseStatus.DRAFT;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _titleController = TextEditingController();
    _deadlineDaysController = TextEditingController(text: _deadlineDays.toString());
    _quillController = QuillController.basic();

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
    _deadlineDaysController.dispose();
    _quillController.dispose();
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
      _titleController.text = course.title;
      _deadlineType = _parseDeadlineType(course.deadlineType) ?? DeadlineType.RELATIVE;
      _deadlineDays = course.defaultDeadlineDays ?? 20;
      _deadlineDaysController.text = _deadlineDays.toString();
      _fixedDeadline = course.fixedDeadline;

      _initialDescription = course.description;
      _initialDeadlineType = _deadlineType;
      _initialDeadlineDays = _deadlineDays;
      _initialFixedDeadline = _fixedDeadline;

      // Init Quill with course description
      if (course.description != null && course.description!.isNotEmpty) {
        _quillController = QuillController(
          document: Document()..insert(0, course.description!),
          selection: const TextSelection.collapsed(offset: 0),
        );
      }

      setState(() => _course = course);
      await _loadModules();
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
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
              id: m.id, title: m.title, orderIndex: m.orderIndex,
              lessons: lessons, quizId: m.quizId,
            );
          } catch (_) { return m; }
        }),
      );
      if (mounted) setState(() => _modules = modulesWithLessons);
    } catch (e) { log("  [WARN] Failed to load modules: $e"); }
  }

  DeadlineType _parseDeadlineType(String? value) {
    if (value == null) return DeadlineType.RELATIVE;
    return value.toUpperCase() == 'FIXED' ? DeadlineType.FIXED : DeadlineType.RELATIVE;
  }

  Future<void> _saveCourse() async {
    if (!_isEditMode) return;
    if (_titleController.text.trim().isEmpty) {
      GlobalNotificationService.show(
        context: context, message: 'Vui lòng nhập tiêu đề khóa học',
        type: NotificationType.warning,
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final currentDescription = _quillController.document.toPlainText().trim();
      final request = UpdateCourseRequest(
        title: _titleController.text.trim(),
        description: currentDescription != (_initialDescription ?? '')
            ? currentDescription : null,
        defaultDeadlineDays: _deadlineDays != _initialDeadlineDays
            ? _deadlineDays : null,
        deadlineType: _deadlineType.name != _initialDeadlineType.name
            ? _deadlineType.name : null,
        fixedDeadline: _fixedDeadline?.toIso8601String() != _initialFixedDeadline?.toIso8601String()
            ? _fixedDeadline?.toIso8601String() : null,
      );
      await _courseService.updateCourse(_course!.id, request);
      if (mounted) {
        GlobalNotificationService.show(
          context: context, message: 'Lưu thành công',
          type: NotificationType.success,
        );
        context.go('/mentor/courses?refresh=${DateTime.now().millisecondsSinceEpoch}');
      }
    } catch (e) {
      if (mounted) GlobalNotificationService.show(context: context, message: 'Lỗi: ${e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')}', type: NotificationType.error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _archiveCourse() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: _warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.archive_outlined, color: _warning, size: 22),
            ),
            const SizedBox(width: 14),
            const Text("Lưu trữ khóa học"),
          ],
        ),
        content: const Text("Bạn có chắc muốn lưu trữ khóa học này? Khóa học sẽ không còn hiển thị với nhân viên."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy bỏ")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _warning, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      GlobalNotificationService.show(context: context, message: 'Lưu trữ thành công', type: NotificationType.success);
      context.go('/mentor/courses?refresh=${DateTime.now().millisecondsSinceEpoch}');
    } catch (e) {
      if (mounted) GlobalNotificationService.show(context: context, message: 'Lỗi: ${e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')}', type: NotificationType.error);
    }
  }

  Future<void> _onModulesReorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;
    final List<ModuleResponse> reordered = List.from(_modules);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);
    setState(() => _modules = reordered);
    try {
      await _courseService.reorderModules(
        _course!.id, reordered.map((m) => Long(m.id.value)).toList(),
      );
      if (mounted) GlobalNotificationService.show(context: context, message: 'Đã sắp xếp lại thứ tự chương', type: NotificationType.success);
    } catch (e) {
      await _loadModules();
      if (mounted) GlobalNotificationService.show(context: context, message: 'Lỗi sắp xếp: $e', type: NotificationType.error);
    }
  }

  Future<void> _moveLesson(ModuleResponse module, int lessonIndex, int direction) async {
    final lessons = List<LessonResponse>.from(module.lessons);
    final newIndex = lessonIndex + direction;
    if (newIndex < 0 || newIndex >= lessons.length) return;
    final item = lessons.removeAt(lessonIndex);
    lessons.insert(newIndex, item);
    final idx = _modules.indexWhere((m) => m.id.value == module.id.value);
    if (idx != -1) {
      setState(() => _modules[idx] = ModuleResponse(
        id: module.id, title: module.title, orderIndex: module.orderIndex,
        lessons: lessons, quizId: module.quizId,
      ));
    }
    try {
      await _lessonService.reorderLessons(module.id, lessons.map((l) => Long(l.id.value)).toList());
    } catch (e) {
      await _loadModules();
      if (mounted) GlobalNotificationService.show(context: context, message: 'Lỗi sắp xếp: $e', type: NotificationType.error);
    }
  }

  Future<void> _publishCourse() async {
    // === VALIDATION FRONTEND ===
    if (_modules.isEmpty) {
      GlobalNotificationService.show(
        context: context,
        message: 'Không thể xuất bản: Khóa học phải có ít nhất 1 module.',
        type: NotificationType.error,
      );
      return;
    }
    final emptyModule = _modules.where((m) => m.lessons.isEmpty).toList();
    if (emptyModule.isNotEmpty) {
      final names = emptyModule.map((m) => '"${m.title}"').join(', ');
      GlobalNotificationService.show(
        context: context,
        message: 'Không thể xuất bản: Module $names chưa có bài học nào.',
        type: NotificationType.error,
      );
      return;
    }
    // === END VALIDATION ===

    try {
      await _courseService.publishCourse(_course!.id);
      if (!mounted) return;
      GlobalNotificationService.show(context: context, message: 'Xuất bản thành công', type: NotificationType.success);
      context.go('/mentor/courses?refresh=${DateTime.now().millisecondsSinceEpoch}');
    } catch (e) {
      if (mounted) GlobalNotificationService.show(context: context, message: 'Lỗi: ${e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')}', type: NotificationType.error);
    }
  }

  // ══════════════════════════════════════════════════════
  // DIALOG HELPERS
  // ══════════════════════════════════════════════════════

  InputDecoration _field(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: _textLight, size: 20) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _danger),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Future<void> _showAddModuleDialog() async {
    final titleController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final chapterNumber = _modules.length + 1;
    String previewText = 'Chương $chapterNumber';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: _primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.library_add_rounded, color: _primary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text("Thêm Chương mới",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _textDark)),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context, false),
                          icon: const Icon(Icons.close, size: 20),
                          color: _textMedium,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text("Tên chương",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: titleController,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: "Nhập tên chương...",
                        hintStyle: TextStyle(color: _textLight),
                        prefixIcon: Icon(Icons.bookmark_add_outlined, color: _textLight, size: 20),
                        filled: true,
                        fillColor: const Color(0xFFF5F6FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: _primary, width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.red, width: 1),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.red, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? "Vui lòng nhập tên chương" : null,
                      onChanged: (value) {
                        setDialogState(() {
                          previewText = value.trim().isEmpty
                            ? 'Chương $chapterNumber'
                            : 'Chương $chapterNumber - $value';
                        });
                      },
                      onFieldSubmitted: (_) {
                        if (formKey.currentState!.validate()) Navigator.pop(context, true);
                      },
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.preview_rounded, size: 16, color: _primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              previewText,
                              style: TextStyle(fontSize: 13, color: _primary, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("Hủy", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _textMedium)),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(context, true); },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("Thêm", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (result == true && titleController.text.trim().isNotEmpty && _course != null) {
      try {
        await _moduleService.createModule(CreateModuleRequest(
          title: titleController.text.trim(), orderIndex: _modules.length, courseId: _course!.id,
        ));
        await _loadCourse();
        if (mounted) GlobalNotificationService.show(context: context, message: 'Thêm chương thành công', type: NotificationType.success);
      } catch (e) {
        if (mounted) GlobalNotificationService.show(context: context, message: 'Lỗi: ${e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')}', type: NotificationType.error);
      }
    }
  }

  Future<void> _showEditModuleDialog(ModuleResponse module) async {
    final controller = TextEditingController(text: module.title);
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.edit_outlined, color: _primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text("Chỉnh sửa chương",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _textDark)),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context, false),
                        icon: const Icon(Icons.close, size: 20),
                        color: _textMedium,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text("Tên chương",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: controller,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: "Nhập tên chương...",
                      hintStyle: TextStyle(color: _textLight),
                      prefixIcon: Icon(Icons.bookmark_outlined, color: _textLight, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF5F6FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _primary, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.red, width: 1),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.red, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? "Không được để trống" : null,
                    onFieldSubmitted: (_) {
                      if (formKey.currentState!.validate()) Navigator.pop(context, true);
                    },
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Hủy", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _textMedium)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(context, true); },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Lưu", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (result == true) {
      try {
        await _moduleService.updateModule(module.id, CreateModuleRequest(
          title: controller.text.trim(), orderIndex: module.orderIndex, courseId: _course!.id,
        ));
        await _loadCourse();
        if (mounted) GlobalNotificationService.show(context: context, message: 'Cập nhật chương thành công', type: NotificationType.success);
      } catch (e) {
        if (mounted) GlobalNotificationService.show(context: context, message: 'Lỗi: ${e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')}', type: NotificationType.error);
      }
    }
  }

  Future<void> _showAddLessonDialog(ModuleResponse module) async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final videoController = TextEditingController();
    String lessonType = 'TEXT';
    final formKey = GlobalKey<FormState>();
    final lessonNumber = module.lessonCount + 1;
    String previewText = 'Bài $lessonNumber';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
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
                    validator: (v) => (v == null || v.trim().isEmpty) ? "Vui lòng nhập tên bài học" : null,
                    onChanged: (value) {
                      setStateDialog(() {
                        previewText = value.trim().isEmpty
                          ? 'Bài $lessonNumber'
                          : 'Bài $lessonNumber - $value';
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.preview_rounded, size: 15, color: _primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            previewText,
                            style: TextStyle(fontSize: 12, color: _primary, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  LessonTypeSelector(
                    selectedType: lessonType,
                    onTypeChanged: (v) => setStateDialog(() => lessonType = v),
                    primaryColor: _primary,
                  ),
                  const SizedBox(height: 16),
                  if (lessonType == 'TEXT' || lessonType == 'LINK')
                    RichTextEditorWidget(
                      initialContent: contentController.text,
                      hintText: lessonType == 'LINK' ? 'Link tài liệu (.pdf, .doc, .docx)' : 'Nhập nội dung bài học...',
                      primaryColor: _primary,
                      maxHeight: 160,
                      onContentChanged: (v) => contentController.text = v,
                    ),
                  if (lessonType == 'VIDEO')
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6FA),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.videocam_outlined, color: _primary, size: 20),
                              const SizedBox(width: 8),
                              Text("Link video", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: videoController,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: "Dán link YouTube embed...",
                              hintStyle: TextStyle(color: _textLight),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 12, right: 8),
                                child: Icon(Icons.link_rounded, color: _textLight, size: 18),
                              ),
                              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: _primary, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy bỏ", style: TextStyle(color: _textMedium))),
            ElevatedButton(
              onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(context, true); },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary, foregroundColor: Colors.white,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        String contentValue = lessonType == 'VIDEO' ? videoController.text.trim() : contentController.text.trim();
        if (contentValue.isNotEmpty) {
          await _lessonContentService.createContent(lesson.id.value, {
            "type": lessonType, "content": contentValue, "orderIndex": 0, "moduleId": module.id.value,
          });
        }
        await _loadCourse();
        if (mounted) GlobalNotificationService.show(context: context, message: 'Thêm bài học thành công', type: NotificationType.success);
      } catch (e) {
        if (mounted) GlobalNotificationService.show(context: context, message: 'Lỗi: ${e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')}', type: NotificationType.error);
      }
    }
  }

  Future<void> _showEditLessonDialog(ModuleResponse module, LessonResponse lesson) async {
    final titleController = TextEditingController(text: lesson.title);
    final primaryContentData = lesson.firstContent;
    final contentController = TextEditingController(text: primaryContentData?.content ?? '');
    final videoController = TextEditingController(text: primaryContentData?.videoUrl ?? '');
    String lessonType = primaryContentData?.type.name ?? 'TEXT';
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
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
                    validator: (v) => (v == null || v.trim().isEmpty) ? "Vui lòng nhập tên bài học" : null,
                  ),
                  const SizedBox(height: 16),
                  LessonTypeSelector(
                    selectedType: lessonType,
                    onTypeChanged: (v) => setStateDialog(() => lessonType = v),
                    primaryColor: _primary,
                  ),
                  const SizedBox(height: 16),
                  if (lessonType == 'TEXT' || lessonType == 'LINK')
                    RichTextEditorWidget(
                      initialContent: contentController.text,
                      hintText: lessonType == 'LINK' ? 'Link tài liệu' : 'Nhập nội dung...',
                      primaryColor: _primary,
                      maxHeight: 160,
                      onContentChanged: (v) => contentController.text = v,
                    ),
                  if (lessonType == 'VIDEO')
                    TextFormField(
                      controller: videoController,
                      decoration: _field("YouTube URL", icon: Icons.videocam_outlined),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy bỏ", style: TextStyle(color: _textMedium))),
            ElevatedButton(
              onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(context, true); },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary, foregroundColor: Colors.white,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        String contentValue = lessonType == 'VIDEO' ? videoController.text.trim() : contentController.text.trim();
        if (contentValue.isNotEmpty) {
          final primaryId = lesson.primaryContentId;
          if (primaryId != null) {
            await _lessonContentService.updateContent(lesson.id.value, primaryId.value, {
              "lessonId": lesson.id.value, "type": lessonType, "content": contentValue, "orderIndex": 0, "moduleId": module.id.value,
            });
          } else {
            await _lessonContentService.createContent(lesson.id.value, {
              "type": lessonType, "content": contentValue, "orderIndex": 0, "moduleId": module.id.value,
            });
          }
        }
        await _loadCourse();
        if (mounted) GlobalNotificationService.show(context: context, message: 'Cập nhật bài học thành công', type: NotificationType.success);
      } catch (e) {
        if (mounted) GlobalNotificationService.show(context: context, message: 'Lỗi: ${e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')}', type: NotificationType.error);
      }
    }
  }

  Future<void> _deleteModule(ModuleResponse module) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: _danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.delete_outline, color: _danger, size: 20),
            ),
            const SizedBox(width: 12),
            const Text("Xóa chương"),
          ],
        ),
        content: Text("Bạn có chắc muốn xóa chương \"${module.title}\" và tất cả bài học trong đó?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy bỏ", style: TextStyle(color: _textMedium))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _danger, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        if (mounted) GlobalNotificationService.show(context: context, message: 'Xóa chương thành công', type: NotificationType.success);
      } catch (e) {
        if (mounted) GlobalNotificationService.show(context: context, message: 'Lỗi: ${e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')}', type: NotificationType.error);
      }
    }
  }

  Future<void> _deleteLesson(ModuleResponse module, LessonResponse lesson) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: _danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.delete_outline, color: _danger, size: 20),
            ),
            const SizedBox(width: 12),
            const Text("Xóa bài học"),
          ],
        ),
        content: Text("Bạn có chắc muốn xóa bài học \"${lesson.title}\"?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy bỏ", style: TextStyle(color: _textMedium))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _danger, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        if (mounted) GlobalNotificationService.show(context: context, message: 'Xóa bài học thành công', type: NotificationType.success);
      } catch (e) {
        if (mounted) GlobalNotificationService.show(context: context, message: 'Lỗi: ${e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')}', type: NotificationType.error);
      }
    }
  }

  Future<void> _deleteModuleQuiz(ModuleResponse module) async {
    if (module.quizId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: _danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.delete_outline, color: _danger, size: 20),
            ),
            const SizedBox(width: 12),
            const Text("Xóa Quiz"),
          ],
        ),
        content: const Text("Bạn có chắc muốn xóa quiz của chương này? Tất cả câu hỏi trong quiz cũng sẽ bị xóa."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy bỏ", style: TextStyle(color: _textMedium))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _danger, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        if (mounted) GlobalNotificationService.show(context: context, message: 'Xóa quiz thành công', type: NotificationType.success);
      } catch (e) {
        if (mounted) GlobalNotificationService.show(context: context, message: 'Lỗi: ${e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')}', type: NotificationType.error);
      }
    }
  }

  String _convertYoutubeUrl(String url) {
    final value = url.trim();
    if (value.isEmpty) return '';
    final rawIdReg = RegExp(r'^[a-zA-Z0-9_-]{11}$');
    if (rawIdReg.hasMatch(value)) return 'https://www.youtube.com/embed/$value';
    final uri = Uri.tryParse(value);
    if (uri == null) return value;
    if (uri.host.contains('youtube.com')) {
      final videoId = uri.queryParameters['v'];
      if (videoId != null && videoId.isNotEmpty) return 'https://www.youtube.com/embed/$videoId';
      if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'embed') return value;
    }
    if (uri.host.contains('youtu.be')) {
      if (uri.pathSegments.isNotEmpty) return 'https://www.youtube.com/embed/${uri.pathSegments.first}';
    }
    return value;
  }

  Widget _buildLessonContent(LessonResponse lesson) {
    final primary = lesson.firstContent;
    final contentType = primary?.type;
    final lessonContent = primary?.content;
    final videoUrl = primary?.videoUrl;

    if (_isLessonDialogOpen) {
      return Container(
        margin: const EdgeInsets.only(top: 6),
        child: Text(
          "Đang chỉnh sửa bài học...",
          style: TextStyle(fontSize: 12, color: _textLight.withValues(alpha: 0.7)),
        ),
      );
    }

    switch (contentType) {
      case LessonContentType.VIDEO:
        return _buildVideoIframe(videoUrl);
      case LessonContentType.LINK:
        return Container(
          margin: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Icon(Icons.link, size: 12, color: _primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  lessonContent ?? '',
                  style: TextStyle(fontSize: 11, color: _primary, decoration: TextDecoration.underline),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      default:
        return Container(
          margin: const EdgeInsets.only(top: 6),
          child: Text(
            lessonContent ?? '',
            style: TextStyle(fontSize: 12, color: _textMedium),
            maxLines: 2, overflow: TextOverflow.ellipsis,
          ),
        );
    }
  }

  Widget _buildVideoIframe(String? url) {
    if (url == null || url.trim().isEmpty) {
      return Text("Không có video", style: TextStyle(fontSize: 12, color: _textLight));
    }
    final embedUrl = _convertYoutubeUrl(url);
    final viewId = 'video-${embedUrl.hashCode}-${DateTime.now().millisecondsSinceEpoch}';
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(viewId, (int _) {
      final iframe = html.IFrameElement()
        ..src = embedUrl
        ..style.border = 'none'
        ..style.borderRadius = '12px'
        ..style.width = '100%'
        ..style.height = '200px'
        ..style.overflow = 'hidden'
        ..allow = 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share'
        ..allowFullscreen = true;
      return iframe;
    });
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: double.infinity, height: 200,
        child: HtmlElementView(viewType: viewId),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // BUILD METHODS
  // ══════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primary))
          : _error != null ? _buildError() : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: _danger.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: const Icon(Icons.error_outline, size: 36, color: _danger),
          ),
          const SizedBox(height: 20),
          Text(_error!, style: const TextStyle(color: _danger, fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadCourse,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                if (_course!.courseStatus == CourseStatus.PUBLISHED) ...[
                  OutlinedButton.icon(
                    onPressed: _archiveCourse,
                    icon: const Icon(Icons.archive_outlined, size: 18),
                    label: const Text("Lưu trữ"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _warning,
                      side: const BorderSide(color: _warning),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                if (!_course!.isPublished) ...[
                  OutlinedButton.icon(
                    onPressed: _publishCourse,
                    icon: const Icon(Icons.publish, size: 18),
                    label: const Text("Xuất bản"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _success,
                      side: const BorderSide(color: _success),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                if (_canEdit) ...[
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveCourse,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary, foregroundColor: Colors.white,
                      elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    ),
                    icon: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save, size: 18),
                    label: const Text("Lưu thay đổi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
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
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _cardBorder),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: _textMedium,
              indicatorColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              indicator: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(10)),
              tabs: const [
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.info_outline, size: 18), SizedBox(width: 8), Text("Thông tin khóa học"),
                ])),
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.account_tree_outlined, size: 18), SizedBox(width: 8), Text("Cấu trúc khóa học"),
                ])),
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
            child: _buildSoftCard(
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
                    enabled: _canEdit,
                    decoration: _field("Tên khóa học *", icon: Icons.school_outlined),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionLabel("Mô tả khóa học", Icons.description_outlined),
                  const SizedBox(height: 10),
                  RichTextEditorWidget(
                    controller: _quillController,
                    hintText: "Nhập mô tả chi tiết về khóa học...",
                    readOnly: !_canEdit,
                    primaryColor: _primary,
                    maxHeight: 200,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 20),

          // RIGHT
          Expanded(
            child: _buildSoftCard(
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
        color: isPublished ? _success.withValues(alpha: 0.08) : _warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPublished ? _success.withValues(alpha: 0.2) : _warning.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPublished ? Icons.check_circle : Icons.pending_outlined,
            size: 18,
            color: isPublished ? _success : _warning,
          ),
          const SizedBox(width: 8),
          Text(
            course.statusLabel,
            style: TextStyle(color: isPublished ? _success : _warning, fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 14, color: _textLight.withValues(alpha: 0.3)),
          const SizedBox(width: 16),
          Icon(Icons.view_module, size: 16, color: _textMedium),
          const SizedBox(width: 6),
          Text("${_modules.length} chương", style: TextStyle(color: _textMedium, fontSize: 13)),
          const SizedBox(width: 12),
          Icon(Icons.play_lesson, size: 16, color: _textMedium),
          const SizedBox(width: 6),
          Text(
            "${_modules.fold(0, (sum, m) => sum + m.lessonCount)} bài học",
            style: TextStyle(color: _textMedium, fontSize: 13),
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
            Expanded(child: _DeadlineOption(
              label: "Tương đối", icon: Icons.schedule,
              isSelected: _deadlineType == DeadlineType.RELATIVE,
              onTap: _canEdit ? () => setState(() => _deadlineType = DeadlineType.RELATIVE) : () {},
              primaryColor: _primary,
            )),
            const SizedBox(width: 10),
            Expanded(child: _DeadlineOption(
              label: "Ngày cố định", icon: Icons.event,
              isSelected: _deadlineType == DeadlineType.FIXED,
              onTap: _canEdit ? () => setState(() => _deadlineType = DeadlineType.FIXED) : () {},
              primaryColor: _primary,
            )),
          ],
        ),
        const SizedBox(height: 14),
        if (_deadlineType == DeadlineType.RELATIVE) ...[
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
                    prefixIcon: const Icon(Icons.numbers, size: 18, color: _textLight),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _primary, width: 2),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  onChanged: (v) { _deadlineDays = int.tryParse(v) ?? 20; },
                ),
              ),
              const SizedBox(width: 12),
              Text("ngày sau ngày đăng ký", style: TextStyle(fontSize: 14, color: _textMedium)),
            ],
          ),
        ] else ...[
          _DatePickerButton(
            selectedDate: _fixedDeadline,
            primaryColor: _primary,
            enabled: _canEdit,
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
          if (!_canEdit)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _warning.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: _warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _course!.courseStatus == CourseStatus.ARCHIVED
                          ? 'Khóa học đã lưu trữ. Không thể chỉnh sửa cấu trúc.'
                          : 'Khóa học đã xuất bản. Không thể chỉnh sửa module, bài học và quiz.',
                      style: const TextStyle(fontSize: 13, color: _warning),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [_primary.withValues(alpha: 0.15), _primaryLight.withValues(alpha: 0.08)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_tree_outlined, color: _primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${_modules.length} Chương",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _textDark, letterSpacing: -0.3),
                      ),
                      Text(
                        "${_modules.fold(0, (sum, m) => sum + m.lessonCount)} bài học",
                        style: TextStyle(fontSize: 13, color: _textMedium),
                      ),
                    ],
                  ),
                ],
              ),
              if (_canEdit)
                _AnimatedAddButton(
                  primaryColor: _primary,
                  label: "Thêm Chương",
                  icon: Icons.add,
                  onPressed: _showAddModuleDialog,
                ),
            ],
          ),
          const SizedBox(height: 24),

          if (_modules.isEmpty)
            _buildEmptyStructureState()
          else ...[
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _cardBorder),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Text(
                      "Tên bài học",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textMedium),
                    ),
                  ),
                  Text(
                    "Loại",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textMedium),
                  ),
                  const SizedBox(width: 100),
                ],
              ),
            ),
            const SizedBox(height: 8),

            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _modules.length,
              onReorder: _canEdit ? _onModulesReorder : (_, __) {},
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return Material(
                      elevation: 6,
                      borderRadius: BorderRadius.circular(16),
                      child: child,
                    );
                  },
                  child: child,
                );
              },
              itemBuilder: (context, index) =>
                  _buildModuleSection(_modules[index], index, ValueKey(_modules[index].id)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModuleSection(ModuleResponse module, int index, ValueKey itemKey) {
    return _CourseraModuleCard(
      key: itemKey,
      module: module,
      index: index,
      primary: _primary,
      primaryLight: _primaryLight,
      textDark: _textDark,
      textMedium: _textMedium,
      textLight: _textLight,
      cardBorder: _cardBorder,
      success: _success,
      danger: _danger,
      canEdit: _canEdit,
      onEditModule: () => _showEditModuleDialog(module),
      onDeleteModule: () => _deleteModule(module),
      onAddLesson: () async {
        setState(() => _isLessonDialogOpen = true);
        await Future.delayed(const Duration(milliseconds: 50));
        await _showAddLessonDialog(module);
        if (!mounted) return;
        setState(() => _isLessonDialogOpen = false);
      },
      onEditLesson: (lesson) async {
        setState(() => _isLessonDialogOpen = true);
        await Future.delayed(const Duration(milliseconds: 50));
        await _showEditLessonDialog(module, lesson);
        if (!mounted) return;
        setState(() => _isLessonDialogOpen = false);
      },
      onDeleteLesson: (lesson) => _deleteLesson(module, lesson),
      onMoveLessonUp: (i) => _moveLesson(module, i, -1),
      onMoveLessonDown: (i) => _moveLesson(module, i, 1),
      onOpenQuiz: () {
        final cid = _course!.id.value;
        if (module.quizId != null) {
          context.go('/mentor/quizzes/create?quizId=${module.quizId!.value}&moduleId=${module.id.value}&courseId=$cid');
        } else {
          context.go('/mentor/quizzes/create?moduleId=${module.id.value}&courseId=$cid');
        }
      },
      onDeleteQuiz: () => _deleteModuleQuiz(module),
      onReorder: (oldIndex, newIndex) => _onModulesReorder(oldIndex, newIndex),
      buildLessonContent: _buildLessonContent,
    );
  }

  Widget _buildPillBadge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textColor),
      ),
    );
  }

  Widget _buildEmptyStructureState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [_primary.withValues(alpha: 0.1), _primaryLight.withValues(alpha: 0.05)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.library_books_outlined, size: 40, color: _primary.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 24),
          const Text(
            "Chưa có chương nào",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _textDark),
          ),
          const SizedBox(height: 8),
          Text(
            "Nhấn \"Thêm Chương\" để bắt đầu xây dựng cấu trúc khóa học.",
            style: TextStyle(fontSize: 14, color: _textMedium, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [_primary.withValues(alpha: 0.12), _primary.withValues(alpha: 0.06)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _primary, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textDark, letterSpacing: -0.2),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _textLight),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _textMedium),
        ),
      ],
    );
  }

  Widget _buildSoftCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }
}

// ══════════════════════════════════════════════════════════
// SUB-WIDGETS
// ══════════════════════════════════════════════════════════

class _AnimatedAddButton extends StatefulWidget {
  final Color primaryColor;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _AnimatedAddButton({
    required this.primaryColor,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  State<_AnimatedAddButton> createState() => _AnimatedAddButtonState();
}

class _AnimatedAddButtonState extends State<_AnimatedAddButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton.icon(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isHovered ? widget.primaryColor : widget.primaryColor.withValues(alpha: 0.1),
            foregroundColor: _isHovered ? Colors.white : widget.primaryColor,
            elevation: _isHovered ? 2 : 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          icon: Icon(widget.icon, size: 18),
          label: Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ),
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
    required this.label, required this.icon,
    required this.isSelected, required this.onTap, required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? primaryColor : const Color(0xFF94A3B8)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: isSelected ? primaryColor : const Color(0xFF64748B),
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
    required this.selectedDate, required this.primaryColor,
    required this.onPicked, this.enabled = true,
  });

  String _format(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

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
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: primaryColor, onPrimary: Colors.white,
                      surface: Colors.white, onSurface: const Color(0xFF0F172A),
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) onPicked(picked);
            }
          : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selectedDate != null ? primaryColor : const Color(0xFFE2E8F0),
            width: selectedDate != null ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 20, color: selectedDate != null ? primaryColor : const Color(0xFF94A3B8)),
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

// ══════════════════════════════════════════════════════════
// COURSERA-STYLE MODULE CARD
// ══════════════════════════════════════════════════════════

class _CourseraModuleCard extends StatefulWidget {
  final ModuleResponse module;
  final int index;
  final Color primary;
  final Color primaryLight;
  final Color textDark;
  final Color textMedium;
  final Color textLight;
  final Color cardBorder;
  final Color success;
  final Color danger;
  final bool canEdit;
  final VoidCallback onEditModule;
  final VoidCallback onDeleteModule;
  final VoidCallback onAddLesson;
  final Function(LessonResponse) onEditLesson;
  final Function(LessonResponse) onDeleteLesson;
  final Function(int)? onMoveLessonUp;
  final Function(int)? onMoveLessonDown;
  final VoidCallback onOpenQuiz;
  final VoidCallback onDeleteQuiz;
  final Function(int, int) onReorder;
  final Widget Function(LessonResponse) buildLessonContent;

  const _CourseraModuleCard({
    required super.key,
    required this.module,
    required this.index,
    required this.primary,
    required this.primaryLight,
    required this.textDark,
    required this.textMedium,
    required this.textLight,
    required this.cardBorder,
    required this.success,
    required this.danger,
    required this.canEdit,
    required this.onEditModule,
    required this.onDeleteModule,
    required this.onAddLesson,
    required this.onEditLesson,
    required this.onDeleteLesson,
    required this.onMoveLessonUp,
    required this.onMoveLessonDown,
    required this.onOpenQuiz,
    required this.onDeleteQuiz,
    required this.onReorder,
    required this.buildLessonContent,
  });

  @override
  State<_CourseraModuleCard> createState() => _CourseraModuleCardState();
}

class _CourseraModuleCardState extends State<_CourseraModuleCard>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _animController;
  late Animation<double> _iconRotation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.index == 0;
    _animController = AnimationController(duration: const Duration(milliseconds: 250), vsync: this);
    _iconRotation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    if (_expanded) _animController.value = 1;
  }

  @override
  void didUpdateWidget(_CourseraModuleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index == 0 && !_expanded) {
      setState(() { _expanded = true; _animController.forward(); });
    }
  }

  @override
  void dispose() { _animController.dispose(); super.dispose(); }

  void _toggleExpand() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) { _animController.forward(); } else { _animController.reverse(); }
    });
  }

  IconData _lessonIcon(LessonContentType? type) {
    switch (type) {
      case LessonContentType.VIDEO: return Icons.videocam_outlined;
      case LessonContentType.LINK: return Icons.link;
      default: return Icons.article_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? widget.primary.withValues(alpha: 0.2) : widget.cardBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? widget.primary.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: _isHovered ? 16 : 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Module Header ──
              InkWell(
                onTap: _toggleExpand,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      // Drag handle
                      if (widget.canEdit)
                        ReorderableDragStartListener(
                          index: widget.index,
                          child: const MouseRegion(
                            cursor: SystemMouseCursors.grab,
                            child: Icon(Icons.drag_indicator, size: 20, color: Color(0xFFCBD5E1)),
                          ),
                        ),
                      if (widget.canEdit) const SizedBox(width: 8),
                      // Module number badge
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                            colors: [
                              widget.primary.withValues(alpha: 0.15),
                              widget.primaryLight.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            "${widget.index + 1}",
                            style: TextStyle(fontWeight: FontWeight.w700, color: widget.primary, fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Title & subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chương ${widget.index + 1} - ${widget.module.title}',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: widget.textDark),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                _buildPill("${widget.module.lessonCount} bài", widget.textMedium, const Color(0xFFE2E8F0)),
                                if (widget.module.quizId != null) ...[
                                  const SizedBox(width: 6),
                                  _buildPill("Quiz", widget.primary, widget.primary.withValues(alpha: 0.1)),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Actions
                      if (widget.canEdit) ...[
                        _IconBtn(
                          icon: Icons.edit_outlined, size: 18, color: widget.textMedium,
                          tooltip: "Sửa chương",
                          onPressed: widget.onEditModule,
                        ),
                        const SizedBox(width: 2),
                        _IconBtn(
                          icon: Icons.delete_outline, size: 18, color: widget.danger,
                          tooltip: "Xóa chương",
                          onPressed: widget.onDeleteModule,
                        ),
                        const SizedBox(width: 8),
                      ],
                      RotationTransition(
                        turns: _iconRotation,
                        child: const Icon(Icons.expand_more, size: 20, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Content (animated expand/collapse) ──
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                firstChild: _buildExpandedContent(),
                secondChild: const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Column(
      children: [
        const Divider(height: 1, color: Color(0xFFF1F5F9)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lessons header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: widget.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.list_alt, size: 16, color: widget.textMedium),
                        const SizedBox(width: 8),
                        Text(
                          "Danh sách bài học",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: widget.textMedium),
                        ),
                        const SizedBox(width: 8),
                        _buildPill("${widget.module.lessons.length}", widget.textMedium, const Color(0xFFE2E8F0)),
                      ],
                    ),
                    if (widget.canEdit)
                      _TextBtn(
                        icon: Icons.add, label: "Thêm bài học",
                        color: widget.primary,
                        onPressed: widget.onAddLesson,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              if (widget.module.lessons.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      "Chưa có bài học nào — nhấn \"Thêm bài học\" để bắt đầu.",
                      style: TextStyle(fontSize: 13, color: widget.textLight),
                    ),
                  ),
                )
              else
                ...List.generate(widget.module.lessons.length, (i) {
                  final lesson = widget.module.lessons[i];
                  return _LessonTile(
                    lesson: lesson,
                    lessonIndex: i,
                    primary: widget.primary,
                    textDark: widget.textDark,
                    textMedium: widget.textMedium,
                    textLight: widget.textLight,
                    cardBorder: widget.cardBorder,
                    success: widget.success,
                    danger: widget.danger,
                    canEdit: widget.canEdit,
                    icon: _lessonIcon(lesson.primaryType),
                    onEdit: () => widget.onEditLesson(lesson),
                    onDelete: () => widget.onDeleteLesson(lesson),
                    onMoveUp: i > 0 ? () => widget.onMoveLessonUp?.call(i) : null,
                    onMoveDown: i < widget.module.lessons.length - 1 ? () => widget.onMoveLessonDown?.call(i) : null,
                    child: widget.buildLessonContent(lesson),
                  );
                }),

              const SizedBox(height: 10),

              // Quiz section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: widget.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.quiz_outlined, size: 16, color: widget.textMedium),
                        const SizedBox(width: 8),
                        Text(
                          "Quiz chương",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: widget.textMedium),
                        ),
                        const SizedBox(width: 8),
                        _buildPill(
                          widget.module.quizId != null ? 'Đã tạo' : 'Chưa tạo',
                          widget.module.quizId != null ? widget.primary : widget.textLight,
                          widget.module.quizId != null ? widget.primary.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.canEdit && widget.module.quizId != null)
                          _IconBtn(
                            icon: Icons.delete_outline, size: 18, color: widget.danger,
                            tooltip: "Xóa quiz", onPressed: widget.onDeleteQuiz,
                          ),
                        _TextBtn(
                          icon: widget.module.quizId != null ? Icons.edit_outlined : Icons.add,
                          label: widget.module.quizId != null ? "Sửa quiz" : "Tạo quiz",
                          color: widget.module.quizId != null ? widget.primary : (widget.canEdit ? widget.primary : widget.textLight),
                          onPressed: widget.canEdit ? widget.onOpenQuiz : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPill(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textColor),
      ),
    );
  }
}

class _LessonTile extends StatefulWidget {
  final LessonResponse lesson;
  final int lessonIndex;
  final Color primary;
  final Color textDark;
  final Color textMedium;
  final Color textLight;
  final Color cardBorder;
  final Color success;
  final Color danger;
  final bool canEdit;
  final IconData icon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final Widget child;

  const _LessonTile({
    required this.lesson, required this.lessonIndex, required this.primary,
    required this.textDark, required this.textMedium, required this.textLight,
    required this.cardBorder, required this.success, required this.danger,
    required this.canEdit, required this.icon,
    required this.onEdit, required this.onDelete,
    required this.onMoveUp, required this.onMoveDown, required this.child,
  });

  @override
  State<_LessonTile> createState() => _LessonTileState();
}

class _LessonTileState extends State<_LessonTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFFF8FAFC) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                // Reorder arrows
                if (widget.canEdit) ...[
                  _IconBtn(icon: Icons.arrow_upward, size: 16, color: widget.onMoveUp != null ? widget.textMedium : const Color(0xFFE2E8F0), onPressed: widget.onMoveUp),
                  _IconBtn(icon: Icons.arrow_downward, size: 16, color: widget.onMoveDown != null ? widget.textMedium : const Color(0xFFE2E8F0), onPressed: widget.onMoveDown),
                  const SizedBox(width: 4),
                ],
                // Type icon
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: widget.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(widget.icon, size: 16, color: widget.primary),
                ),
                const SizedBox(width: 12),
                // Title & content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bài ${widget.lessonIndex + 1} - ${widget.lesson.title}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: widget.textDark),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      widget.child,
                    ],
                  ),
                ),
                // Edit/Delete
                if (widget.canEdit && _isHovered) ...[
                  _IconBtn(icon: Icons.edit_outlined, size: 16, color: widget.textMedium, tooltip: "Sửa bài học", onPressed: widget.onEdit),
                  _IconBtn(icon: Icons.delete_outline, size: 16, color: widget.danger, tooltip: "Xóa bài học", onPressed: widget.onDelete),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final String? tooltip;
  final VoidCallback? onPressed;

  const _IconBtn({
    required this.icon, required this.size, required this.color,
    this.tooltip, this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final btn = InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: size, color: onPressed != null ? color : const Color(0xFFE2E8F0)),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}

class _TextBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _TextBtn({
    required this.icon, required this.label,
    required this.color, this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: onPressed != null ? color : const Color(0xFFE2E8F0)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: onPressed != null ? color : const Color(0xFFE2E8F0)),
            ),
          ],
        ),
      ),
    );
  }
}
