import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/service/mentor/course_service.dart';
import 'package:smet/service/mentor/module_service.dart';
import 'package:smet/service/mentor/lesson_service.dart';

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

  late TabController _tabController;
  CourseDetailResponse? _course;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  bool _isEditMode = false;

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
      final course = await _courseService.getCourseDetail(Long(int.parse(widget.courseId!)));
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
      await _loadCourse();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lưu thành công"), backgroundColor: Colors.green),
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
          const SnackBar(content: Text("Xuất bản thành công"), backgroundColor: Colors.green),
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
      builder: (context) => AlertDialog(
        title: const Text("Thêm Chương mới"),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: "Tên chương",
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? "Vui lòng nhập tên chương" : null,
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
            const SnackBar(content: Text("Thêm chương thành công"), backgroundColor: Colors.green),
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
    final titleController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Thêm Bài học vào '${module.title}'"),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: "Tên bài học",
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? "Vui lòng nhập tên bài học" : null,
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

    if (result == true && titleController.text.trim().isNotEmpty) {
      try {
        final request = CreateLessonRequest(
          title: titleController.text.trim(),
          orderIndex: module.lessonCount,
          moduleId: module.id,
        );
        await _lessonService.createLesson(request);
        await _loadCourse();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Thêm bài học thành công"), backgroundColor: Colors.green),
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
      builder: (context) => AlertDialog(
        title: const Text("Xóa chương"),
        content: Text("Bạn có chắc muốn xóa chương '${module.title}' và tất cả bài học trong đó?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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
            const SnackBar(content: Text("Xóa chương thành công"), backgroundColor: Colors.green),
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

  Future<void> _deleteLesson(ModuleResponse module, LessonResponse lesson) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xóa bài học"),
        content: Text("Bạn có chắc muốn xóa bài học '${lesson.title}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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
            const SnackBar(content: Text("Xóa bài học thành công"), backgroundColor: Colors.green),
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
      body: _isLoading
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
          ElevatedButton(
            onPressed: _loadCourse,
            child: const Text("Thử lại"),
          ),
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
                if (!_course!.isPublished)
                  TextButton.icon(
                    onPressed: _publishCourse,
                    icon: const Icon(Icons.publish),
                    label: const Text("Xuất bản"),
                  ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveCourse,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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
            children: [
              _buildInfoTab(),
              _buildStructureTab(),
            ],
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
            if (_course != null) ...[
              _statusRow(),
              const SizedBox(height: 20),
            ],

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
            color: course.isPublished
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
          "${course.moduleCount} chương • ${course.lessonCount} bài học",
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
                title: const Text("Ngày cố định", style: TextStyle(fontSize: 14)),
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
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  controller: TextEditingController(text: _deadlineDays.toString()),
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
                initialDate: _fixedDeadline ?? DateTime.now().add(const Duration(days: 30)),
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
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
            ...List.generate(_modules.length, (i) => _buildModuleCard(_modules[i], i)),
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
                    "${module.lessonCount} bài học",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              tooltip: "Xóa chương",
              onPressed: () => _deleteModule(module),
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
                  onPressed: () => _showAddLessonDialog(module),
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
            ...module.lessons.map((lesson) => ListTile(
              leading: const Icon(Icons.play_circle_outline, size: 20),
              title: Text(lesson.title, style: const TextStyle(fontSize: 14)),
              subtitle: lesson.durationMinutes != null
                  ? Text("${lesson.durationMinutes} phút", style: const TextStyle(fontSize: 12))
                  : null,
              dense: true,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                tooltip: "Xóa bài học",
                onPressed: () => _deleteLesson(module, lesson),
              ),
            )),
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
}
