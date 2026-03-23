import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/service/mentor/course_service.dart';
import 'package:smet/service/mentor/module_service.dart';
import 'package:smet/service/mentor/lesson_service.dart';

/// Mentor Course Detail / Edit - Mobile Layout
class MentorCourseDetailMobile extends StatefulWidget {
  final String? courseId;

  const MentorCourseDetailMobile({super.key, this.courseId});

  @override
  State<MentorCourseDetailMobile> createState() =>
      _MentorCourseDetailMobileState();
}

class _MentorCourseDetailMobileState extends State<MentorCourseDetailMobile> {
  final MentorCourseService _courseService = MentorCourseService();
  final MentorModuleService _moduleService = MentorModuleService();
  final MentorLessonService _lessonService = MentorLessonService();

  CourseDetailResponse? _course;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  bool _isEditMode = false;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DeadlineType _deadlineType = DeadlineType.RELATIVE;
  int _deadlineDays = 20;
  DateTime? _fixedDeadline;

  List<ModuleResponse> _modules = [];

  @override
  void initState() {
    super.initState();
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
      // Load modules separately since course detail doesn't include them
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
      // Load lessons for each module separately
      final modulesWithLessons = await Future.wait(
        modules.map((m) async {
          try {
            final lessons = await _lessonService.getLessonsByModule(m.id);
            return ModuleResponse(
              id: m.id,
              title: m.title,
              orderIndex: m.orderIndex,
              lessons: lessons,
            );
          } catch (_) {
            return m; // fallback to module without lessons
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Vui lòng nhập tiêu đề")));
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
      await _loadCourse();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lưu thành công"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _publishCourse() async {
    try {
      await _courseService.publishCourse(_course!.id);
      await _loadCourse();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Xuất bản thành công"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ============================================
  // MODULE ACTIONS
  // ============================================

  Future<void> _showAddModuleDialog() async {
    final titleController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Thêm Chương mới"),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "Tên chương",
                  border: OutlineInputBorder(),
                ),
                validator:
                    (v) =>
                        (v == null || v.trim().isEmpty)
                            ? "Vui lòng nhập tên chương"
                            : null,
                autofocus: true,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Hủy"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context, true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff1a90ff),
                  foregroundColor: Colors.white,
                ),
                child: const Text("Thêm"),
              ),
            ],
          ),
    );

    if (result == true &&
        titleController.text.trim().isNotEmpty &&
        _course != null) {
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
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
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
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Thêm Bài học vào '${module.title}'"),
            content: StatefulBuilder(
              builder: (context, setStateDialog) {
                return Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// TITLE
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: "Tên bài học",
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? "Vui lòng nhập tên bài học"
                                    : null,
                      ),

                      const SizedBox(height: 12),

                      /// TYPE
                      DropdownButtonFormField<String>(
                        value: lessonType,
                        decoration: const InputDecoration(
                          labelText: "Loại nội dung",
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'TEXT', child: Text("Text")),
                          DropdownMenuItem(
                            value: 'VIDEO',
                            child: Text("Video"),
                          ),
                          DropdownMenuItem(value: 'LINK', child: Text("Link")),
                        ],
                        onChanged: (v) {
                          setStateDialog(() {
                            lessonType = v!;
                          });
                        },
                      ),

                      const SizedBox(height: 12),

                      /// CONTENT
                      if (lessonType == 'TEXT' || lessonType == 'LINK')
                        TextField(
                          controller: contentController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: "Nội dung / Link",
                            border: OutlineInputBorder(),
                          ),
                        ),

                      if (lessonType == 'VIDEO')
                        TextField(
                          controller: videoController,
                          decoration: const InputDecoration(
                            labelText: "Video URL",
                            border: OutlineInputBorder(),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Hủy"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context, true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff1a90ff),
                  foregroundColor: Colors.white,
                ),
                child: const Text("Thêm"),
              ),
            ],
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
        await _lessonService.createLesson(request);
        await _loadCourse();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Thêm bài học thành công"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _deleteModule(ModuleResponse module) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Xóa chương"),
            content: Text(
              "Bạn có chắc muốn xóa chương '${module.title}' và tất cả bài học trong đó?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Hủy"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
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
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _deleteLesson(
    ModuleResponse module,
    LessonResponse lesson,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Xóa bài học"),
            content: Text("Bạn có chắc muốn xóa bài học '${lesson.title}'?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Hủy"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
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
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/mentor/courses'),
        ),
        title: Text(
          _course?.title ?? "Chi tiết khóa học",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          if (_isEditMode && _course != null) ...[
            if (!_course!.isPublished)
              TextButton(
                onPressed: _publishCourse,
                child: const Text(
                  "Xuất bản",
                  style: TextStyle(color: Color(0xff1a90ff)),
                ),
              ),
            IconButton(
              onPressed: _isSaving ? null : _saveCourse,
              icon:
                  _isSaving
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.check, color: Color(0xff1a90ff)),
            ),
          ],
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
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
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadCourse, child: const Text("Thử lại")),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// STATUS
          if (_course != null) _buildStatusRow(),
          const SizedBox(height: 16),

          /// INFO CARD
          _buildCard(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Tên khóa học *",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: "Mô tả",
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
            ],
          ),
          const SizedBox(height: 16),

          /// DEADLINE CARD
          _buildCard(
            title: "Hạn nộp bài",
            children: [
              Column(
                children: [
                  RadioListTile<DeadlineType>(
                    title: const Text(
                      "Tương đối",
                      style: TextStyle(fontSize: 14),
                    ),
                    value: DeadlineType.RELATIVE,
                    groupValue: _deadlineType,
                    onChanged: (v) => setState(() => _deadlineType = v!),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_deadlineType == DeadlineType.RELATIVE)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              controller: TextEditingController(
                                text: _deadlineDays.toString(),
                              ),
                              onChanged:
                                  (v) => _deadlineDays = int.tryParse(v) ?? 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text("ngày sau đăng ký"),
                        ],
                      ),
                    ),
                  RadioListTile<DeadlineType>(
                    title: const Text(
                      "Ngày cố định",
                      style: TextStyle(fontSize: 14),
                    ),
                    value: DeadlineType.FIXED,
                    groupValue: _deadlineType,
                    onChanged: (v) => setState(() => _deadlineType = v!),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_deadlineType == DeadlineType.FIXED)
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate:
                                _fixedDeadline ??
                                DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null)
                            setState(() => _fixedDeadline = date);
                        },
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          _fixedDeadline != null
                              ? "${_fixedDeadline!.day}/${_fixedDeadline!.month}/${_fixedDeadline!.year}"
                              : "Chọn ngày",
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          /// STRUCTURE CARD
          _buildCard(
            title: "Cấu trúc khóa học (${_modules.length} chương)",
            trailing: TextButton.icon(
              onPressed: _showAddModuleDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Thêm"),
            ),
            children:
                _modules.isEmpty
                    ? [
                      Container(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.folder_open,
                                size: 36,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Chưa có chương nào",
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]
                    : _modules.asMap().entries.map((entry) {
                      final module = entry.value;
                      return _buildModuleItem(module, entry.key);
                    }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow() {
    final course = _course!;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color:
                course.isPublished
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            course.statusLabel,
            style: TextStyle(
              color: course.isPublished ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          "${course.moduleCount} chương • ${course.lessonCount} bài",
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildModuleItem(ModuleResponse module, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: Text(
          "Chương ${index + 1}: ${module.title}",
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          "${module.lessonCount} bài học",
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        children:
            module.lessons
                .map(
                  (l) => ListTile(
                    leading: const Icon(Icons.play_circle_outline, size: 18),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.title, style: const TextStyle(fontSize: 13)),

                        const SizedBox(height: 4),

                        _buildLessonContent(l),
                      ],
                    ),
                    dense: true,
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildCard({
    String? title,
    Widget? trailing,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  if (trailing != null) trailing,
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonContent(LessonResponse lesson) {
    switch (lesson.contentType) {
      case 'VIDEO':
        return Text(
          "🎥 ${lesson.videoUrl ?? ''}",
          style: const TextStyle(fontSize: 11, color: Colors.blue),
        );

      case 'LINK':
        return InkWell(
          onTap: () {
            // mở link sau
          },
          child: Text(
            lesson.content ?? '',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
          ),
        );

      default:
        return Text(lesson.content ?? '', style: const TextStyle(fontSize: 11));
    }
  }
}
