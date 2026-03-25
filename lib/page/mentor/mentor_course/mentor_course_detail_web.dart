import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/service/mentor/course_service.dart';
import 'package:smet/service/mentor/module_service.dart';
import 'package:smet/service/mentor/lesson_service.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:smet/service/mentor/lesson_content_service.dart';

/// Mentor Course Detail / Edit - Web Layout
class MentorCourseDetailWeb extends StatefulWidget {
  final String? courseId;

  const MentorCourseDetailWeb({super.key, this.courseId});

  @override
  State<MentorCourseDetailWeb> createState() => _MentorCourseDetailWebState();
}

class _MentorCourseDetailWebState extends State<MentorCourseDetailWeb>
    with SingleTickerProviderStateMixin {
  final MentorCourseService _courseService = MentorCourseService();
  final MentorModuleService _moduleService = MentorModuleService();
  final MentorLessonService _lessonService = MentorLessonService();
  final LessonContentService _lessonContentService = LessonContentService();
  late TabController _tabController;
  CourseDetailResponse? _course;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  bool _isEditMode = false;

  bool _isLessonDialogOpen = false;
  // Form controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DeadlineType _deadlineType = DeadlineType.RELATIVE;
  int _deadlineDays = 20;
  DateTime? _fixedDeadline;

  // Module/lesson editing state
  List<ModuleResponse> _modules = [];

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
      // Silently fail for modules load, course info still shows
      log("  [WARN] Failed to load modules: $e");
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
            backgroundColor: Colors.green,
          ),
        );

        // 👉 QUAN TRỌNG: quay về list + trigger reload
        context.go(
          '/mentor/courses?refresh=${DateTime.now().millisecondsSinceEpoch}',
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
      context.go('/mentor/courses?refresh=...');
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

  Future<void> _showEditModuleDialog(ModuleResponse module) async {
    final controller = TextEditingController(text: module.title);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Chỉnh sửa chương"),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: "Tên chương",
                  border: OutlineInputBorder(),
                ),
                validator:
                    (v) =>
                        (v == null || v.trim().isEmpty)
                            ? "Không được để trống"
                            : null,
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

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cập nhật chương thành công")),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
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
                          DropdownMenuItem(
                            value: 'LINK',
                            child: Text("Tài liệu"),
                          ),
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
                        TextFormField(
                          controller: contentController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: "Nội dung / Link",
                            border: OutlineInputBorder(),
                          ),
                        ),

                      if (lessonType == 'VIDEO')
                        TextFormField(
                          controller: videoController,
                          decoration: const InputDecoration(
                            labelText: "YouTube embed URL",
                            hintText: "https://www.youtube.com/embed/xxx",
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
        final lesson = await _lessonService.createLesson(request);

        // 🔥 TẠO CONTENT
        String? contentValue;

        if (lessonType == 'VIDEO') {
          contentValue = videoController.text.trim();
        } else {
          contentValue = contentController.text.trim();
        }

        if (contentValue != null && contentValue.isNotEmpty) {
          await _lessonContentService.createContent(
            lesson.id.value, // 🔥 FIX CHÍNH
            {"type": lessonType, "content": contentValue, "orderIndex": 0},
          );
        }

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

  Future<void> _showEditLessonDialog(
    ModuleResponse module,
    LessonResponse lesson,
  ) async {
    final titleController = TextEditingController(text: lesson.title);
    final contentController = TextEditingController(text: lesson.content ?? '');
    final videoController = TextEditingController(text: lesson.videoUrl ?? '');

    String lessonType = lesson.contentType ?? 'TEXT';

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                title: const Text("Chỉnh sửa bài học"),
                content: Form(
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
                        items: const [
                          DropdownMenuItem(value: 'TEXT', child: Text("Text")),
                          DropdownMenuItem(
                            value: 'VIDEO',
                            child: Text("Video"),
                          ),
                          DropdownMenuItem(
                            value: 'LINK',
                            child: Text("Tài liệu"),
                          ),
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
                        TextFormField(
                          controller: contentController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText:
                                lessonType == 'LINK'
                                    ? "Link tài liệu"
                                    : "Nội dung",
                            hintText:
                                lessonType == 'LINK'
                                    ? "https://example.com/file.pdf"
                                    : null,
                            border: const OutlineInputBorder(),
                          ),
                          validator: (v) {
                            final value = v?.trim() ?? '';

                            if (lessonType == 'TEXT') {
                              if (value.isEmpty) {
                                return "Vui lòng nhập nội dung";
                              }
                            }

                            if (lessonType == 'LINK') {
                              if (value.isEmpty) {
                                return "Vui lòng nhập link tài liệu";
                              }

                              final lower = value.toLowerCase();
                              final isValid =
                                  lower.endsWith('.pdf') ||
                                  lower.endsWith('.doc') ||
                                  lower.endsWith('.docx');

                              if (!isValid) {
                                return "Chỉ chấp nhận link .pdf, .doc, .docx";
                              }
                            }

                            return null;
                          },
                        ),

                      if (lessonType == 'VIDEO')
                        TextFormField(
                          controller: videoController,
                          decoration: const InputDecoration(
                            labelText: "YouTube URL",
                            hintText: "https://www.youtube.com/watch?v=xxx",
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            final value = v?.trim() ?? '';

                            if (value.isEmpty) {
                              return "Vui lòng nhập link YouTube";
                            }

                            final lower = value.toLowerCase();
                            final isYoutube =
                                lower.contains('youtube.com') ||
                                lower.contains('youtu.be');

                            if (!isYoutube) {
                              return "Chỉ chấp nhận link YouTube";
                            }

                            return null;
                          },
                        ),
                    ],
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
                    child: const Text("Lưu"),
                  ),
                ],
              );
            },
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
            await _lessonContentService
                .updateContent(lesson.id.value, lesson.contentId!.value, {
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
            const SnackBar(content: Text("Cập nhật bài học thành công")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
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

  Widget _buildBreadcrumb() {
    return Row(
      children: [
        InkWell(
          onTap: () => context.go('/mentor/courses'),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xfff5f6fa),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, size: 20, color: Color(0xff1a90ff)),
                SizedBox(width: 4),
                Text("Khóa học", style: TextStyle(color: Color(0xff1a90ff))),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            _course?.title ?? "Chi tiết khóa học",
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
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
    return Column(
      children: [
        /// BREADCRUMB
        Padding(
          padding: const EdgeInsets.only(top: 30, left: 30, right: 30),
          child: Row(
            children: [
              Expanded(child: _buildBreadcrumb()),
              if (_isEditMode && _course != null) ...[
                TextButton.icon(
                  onPressed: () {
                    context.go(
                      '/mentor/quizzes/create?courseId=${_course!.id.value}&final=true',
                    );
                  },
                  icon: const Icon(Icons.quiz_outlined),
                  label: const Text("Final Quiz"),
                ),
                const SizedBox(width: 8),
                if (!_course!.isPublished)
                  TextButton.icon(
                    onPressed: _publishCourse,
                    icon: const Icon(Icons.publish),
                    label: const Text("Xuất bản"),
                  ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveCourse,
                  icon:
                      _isSaving
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.save),
                  label: const Text("Lưu thay đổi"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff1a90ff),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),

        /// TAB BAR
        Container(
          margin: const EdgeInsets.only(top: 20, left: 30, right: 30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xff1a90ff),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xff1a90ff),
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            tabs: const [
              Tab(text: "Thông tin khóa học"),
              Tab(text: "Cấu trúc khóa học"),
            ],
          ),
        ),

        /// TAB CONTENT
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
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_course != null) ...[_statusRow(), const SizedBox(height: 20)],

            /// TITLE
            _buildField(label: "Tên khóa học *", controller: _titleController),
            const SizedBox(height: 16),

            /// DESCRIPTION
            _buildField(
              label: "Mô tả",
              controller: _descriptionController,
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            /// DEADLINE TYPE
            _buildDeadlineSection(),
          ],
        ),
      ),
    );
  }

  Widget _statusRow() {
    final course = _course!;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color:
                course.isPublished
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            course.statusLabel,
            style: TextStyle(
              color: course.isPublished ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          "${_modules.length} chương • ${_modules.fold(0, (sum, m) => sum + m.lessonCount)} bài học",
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildDeadlineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Hạn nộp bài",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 12),

        /// Type selector
        Row(
          children: [
            Expanded(
              child: RadioListTile<DeadlineType>(
                title: const Text("Tương đối", style: TextStyle(fontSize: 14)),
                value: DeadlineType.RELATIVE,
                groupValue: _deadlineType,
                onChanged: (v) => setState(() => _deadlineType = v!),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: RadioListTile<DeadlineType>(
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
            ),
          ],
        ),

        if (_deadlineType == DeadlineType.RELATIVE) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 100,
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
                  onChanged: (v) => _deadlineDays = int.tryParse(v) ?? 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text("ngày sau ngày đăng ký"),
            ],
          ),
        ],

        if (_deadlineType == DeadlineType.FIXED) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate:
                    _fixedDeadline ??
                    DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() => _fixedDeadline = date);
              }
            },
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(
              _fixedDeadline != null
                  ? "${_fixedDeadline!.day}/${_fixedDeadline!.month}/${_fixedDeadline!.year}"
                  : "Chọn ngày",
            ),
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
              Text(
                "${_modules.length} Chương",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddModuleDialog,
                icon: const Icon(Icons.add),
                label: const Text("Thêm Chương"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff1a90ff),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_modules.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.folder_open, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      "Chưa có chương nào",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(
              _modules.length,
              (i) => _buildModuleCard(_modules[i], i),
            ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(ModuleResponse module, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Chương ${index + 1}: ${module.title}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    "${module.lessonCount} bài học • Quiz",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.quiz_outlined, size: 20),
                  tooltip: "Tạo Quiz",
                  onPressed: () {
                    context.go(
                      '/mentor/quizzes/create?moduleId=${module.id.value}',
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  tooltip: "Sửa chương",
                  onPressed: () => _showEditModuleDialog(module),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPressed: () => _deleteModule(module),
                ),
              ],
            ),
          ],
        ),
        initiallyExpanded: index == 0,
        children: [
          // Header row with add lesson button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Danh sách bài học",
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    setState(() {
                      _isLessonDialogOpen = true;
                    });

                    await Future.delayed(const Duration(milliseconds: 50));
                    await _showAddLessonDialog(module);

                    if (!mounted) return;
                    setState(() {
                      _isLessonDialogOpen = false;
                    });
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Thêm bài học"),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xff1a90ff),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (module.lessons.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                "Chưa có bài học nào",
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...module.lessons.map(
              (lesson) => ListTile(
                leading: const Icon(Icons.play_circle_outline, size: 20),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 6),

                    _buildLessonContent(lesson),
                  ],
                ),
                subtitle:
                    lesson.durationMinutes != null
                        ? Text(
                          "${lesson.durationMinutes} phút",
                          style: const TextStyle(fontSize: 12),
                        )
                        : null,
                dense: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      tooltip: "Sửa bài học",
                      onPressed: () async {
                        setState(() {
                          _isLessonDialogOpen = true;
                        });

                        await Future.delayed(const Duration(milliseconds: 50));
                        await _showEditLessonDialog(module, lesson);

                        if (!mounted) return;
                        setState(() {
                          _isLessonDialogOpen = false;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 18,
                      ),
                      onPressed: () => _deleteLesson(module, lesson),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
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
          style: TextStyle(fontSize: 12, color: Colors.grey),
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
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
          ),
        );

      default:
        return Text(lesson.content ?? '', style: const TextStyle(fontSize: 12));
    }
  }

  Widget _buildVideoIframe(String? url) {
    if (url == null || url.trim().isEmpty) {
      return const Text("Không có video");
    }

    final embedUrl = _convertYoutubeUrl(url);
    log("RAW VIDEO URL: $url");
    log("EMBED VIDEO URL: $embedUrl");

    final viewId =
        'video-${embedUrl.hashCode}-${DateTime.now().millisecondsSinceEpoch}';

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(viewId, (int _) {
      final iframe =
          html.IFrameElement()
            ..src = embedUrl
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '250px'
            ..allow =
                'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share'
            ..allowFullscreen = true;

      return iframe;
    });

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: SizedBox(
        width: double.infinity,
        height: 250,
        child: HtmlElementView(viewType: viewId),
      ),
    );
  }

  String _convertYoutubeUrl(String url) {
    final value = url.trim();
    if (value.isEmpty) return '';

    // raw video id
    final rawIdReg = RegExp(r'^[a-zA-Z0-9_-]{11}$');
    if (rawIdReg.hasMatch(value)) {
      return 'https://www.youtube.com/embed/$value';
    }

    final uri = Uri.tryParse(value);
    if (uri == null) return value;

    // youtube watch url
    if (uri.host.contains('youtube.com')) {
      final videoId = uri.queryParameters['v'];
      if (videoId != null && videoId.isNotEmpty) {
        return 'https://www.youtube.com/embed/$videoId';
      }

      // already embed url
      if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'embed') {
        return value;
      }
    }

    // youtu.be short url
    if (uri.host.contains('youtu.be')) {
      if (uri.pathSegments.isNotEmpty) {
        return 'https://www.youtube.com/embed/${uri.pathSegments.first}';
      }
    }

    return value;
  }
}
