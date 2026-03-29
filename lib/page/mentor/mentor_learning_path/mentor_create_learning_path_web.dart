import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/model/learning_path_model.dart';
import 'package:smet/service/mentor/learning_path_service.dart';

/// Mentor Create/Edit Learning Path - Web Layout
class MentorCreateLearningPathWeb extends StatefulWidget {
  /// Nếu có editId => mode EDIT, load dữ liệu từ API
  final String? editId;

  const MentorCreateLearningPathWeb({super.key, this.editId});

  @override
  State<MentorCreateLearningPathWeb> createState() =>
      _MentorCreateLearningPathWebState();
}

class _MentorCreateLearningPathWebState
    extends State<MentorCreateLearningPathWeb> {
  final LearningPathService _service = LearningPathService();
  final _formKey = GlobalKey<FormState>();

  // Form fields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // State
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isEditMode = false;
  Long? _editingPathId;

  // Available courses from mentor
  List<Map<String, dynamic>> _availableCourses = [];
  bool _loadingCourses = true;

  // Selected courses (with order)
  List<CourseItemDetail> _selectedCourses = [];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.editId != null && widget.editId!.isNotEmpty;
    _loadAvailableCourses();
    if (_isEditMode) {
      _loadExistingPath();
    }
  }

  int _parseLongFromMap(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableCourses() async {
    try {
      final courses = await _service.getMentorCourses();
      setState(() {
        _availableCourses = courses;
        _loadingCourses = false;
      });
    } catch (e) {
      setState(() => _loadingCourses = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi tải khóa học: $e")));
      }
    }
  }

  Future<void> _loadExistingPath() async {
    setState(() => _isLoading = true);
    try {
      final detail = await _service.getLearningPathDetail(
        Long(int.parse(widget.editId!)),
      );
      _titleController.text = detail.title;
      _descriptionController.text = detail.description;
      _editingPathId = detail.id;
      setState(() {
        _selectedCourses = detail.courses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi tải lộ trình: $e")));
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      if (_isEditMode && _editingPathId != null) {
        // UPDATE
        await _service.updateLearningPath(
          _editingPathId!,
          _titleController.text.trim(),
          _descriptionController.text.trim(),
        );
      } else {
        // CREATE - backend uses @RequestParam, returns Map with id
        final created = await _service.createLearningPath(
          _titleController.text.trim(),
          _descriptionController.text.trim(),
        );
        final createdId = Long(_parseLongFromMap(created['id']));
        _editingPathId = createdId;

        // Thêm các khóa học đã chọn (nếu có)
        for (int i = 0; i < _selectedCourses.length; i++) {
          await _service.addCourseToLearningPath(
            createdId,
            _selectedCourses[i].courseId,
            i,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode ? "Cập nhật thành công!" : "Tạo lộ trình thành công!",
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.go(
          '/mentor/learning-paths?refresh=${DateTime.now().millisecondsSinceEpoch}',
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showCourseSelector() {
    showDialog(
      context: context,
      builder:
          (context) => _CourseSelectorDialog(
            availableCourses: _availableCourses,
            selectedCourseIds:
                _selectedCourses.map((c) => c.courseId.value).toSet(),
            onCoursesSelected: (courses) {
              setState(() {
                _selectedCourses =
                    courses.asMap().entries.map((entry) {
                      return CourseItemDetail(
                        relationId: Long(0), // 👈 BẮT BUỘC THÊM
                        courseId: Long(_parseLongFromMap(entry.value['id'])),
                        title: entry.value['title'] ?? 'Khoa hoc',
                        mentorName: entry.value['mentorName'],
                        moduleCount: _parseInt(entry.value['moduleCount']),
                        orderIndex: entry.key,
                      );
                    }).toList();
              });
            },
          ),
    );
  }

  Future<void> _removeCourse(int index) async {
    final course = _selectedCourses[index];

    // 👉 Nếu đang edit thì gọi API
    if (_editingPathId != null && course.relationId.value != 0) {
      try {
        await _service.removeCourseFromLearningPath(
          _editingPathId!,
          course.relationId, // 👈 QUAN TRỌNG
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Xóa thất bại: $e")));
        }
        return;
      }
    }

    // 👉 Remove UI
    setState(() {
      _selectedCourses.removeAt(index);

      // Reindex lại
      for (int i = 0; i < _selectedCourses.length; i++) {
        _selectedCourses[i] = CourseItemDetail(
          relationId: _selectedCourses[i].relationId,
          courseId: _selectedCourses[i].courseId,
          title: _selectedCourses[i].title,
          mentorName: _selectedCourses[i].mentorName,
          moduleCount: _selectedCourses[i].moduleCount,
          orderIndex: i,
        );
      }
    });
  }

  Future<void> _reorderCourses(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;

      final item = _selectedCourses.removeAt(oldIndex);
      _selectedCourses.insert(newIndex, item);

      // Reindex
      for (int i = 0; i < _selectedCourses.length; i++) {
        _selectedCourses[i] = CourseItemDetail(
          relationId: _selectedCourses[i].relationId,
          courseId: _selectedCourses[i].courseId,
          title: _selectedCourses[i].title,
          mentorName: _selectedCourses[i].mentorName,
          moduleCount: _selectedCourses[i].moduleCount,
          orderIndex: i,
        );
      }
    });

    // 👉 CALL API (chỉ khi edit)
    if (_editingPathId != null) {
      try {
        final orders =
            _selectedCourses
                .map(
                  (c) => {
                    "relationId": c.relationId.value,
                    "orderIndex": c.orderIndex,
                  },
                )
                .toList();

        await _service.reorderCourses(_editingPathId!, orders);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Reorder thất bại: $e")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      body: Column(
        children: [
          /// PAGE HEADER WITH BREADCRUMB
          Container(
            margin: const EdgeInsets.fromLTRB(30, 30, 30, 0),
            child: BreadcrumbPageHeader(
              pageTitle: _isEditMode ? "Chỉnh sửa lộ trình" : "Tạo lộ trình mới",
              pageIcon: Icons.add_road_rounded,
              breadcrumbs: [
                const BreadcrumbItem(label: "Lộ trình", route: "/mentor/learning-paths"),
                BreadcrumbItem(label: _isEditMode ? "Chỉnh sửa lộ trình" : "Tạo lộ trình mới"),
              ],
              primaryColor: const Color(0xFF6366F1),
              actions: [
                TextButton(
                  onPressed: () => context.go('/mentor/learning-paths'),
                  child: const Text("Hủy"),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child:
                      _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isEditMode ? "Lưu thay đổi" : "Tạo lộ trình"),
                ),
              ],
            ),
          ),

          /// CONTENT
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                      padding: const EdgeInsets.all(30),
                      child: Form(
                        key: _formKey,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// LEFT - FORM
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  _buildInfoCard(),
                                  const SizedBox(height: 24),
                                  _buildCoursesCard(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),

                            /// RIGHT - PREVIEW
                            Expanded(flex: 2, child: _buildPreviewCard()),
                          ],
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return _buildCard(
      title: "Thông tin lộ trình",
      icon: Icons.info_outline,
      children: [
        /// TITLE
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: "Tiêu đề lộ trình",
            hintText: "VD: Lộ trình Java Backend cho người mới",
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return "Vui lòng nhập tiêu đề";
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        /// DESCRIPTION
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: "Mô tả",
            hintText: "Mô tả ngắn về lộ trình học tập...",
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildCoursesCard() {
    return _buildCard(
      title: "Khóa học trong lộ trình",
      icon: Icons.menu_book,
      action: TextButton.icon(
        onPressed: _loadingCourses ? null : _showCourseSelector,
        icon: const Icon(Icons.add, size: 18),
        label: const Text("Thêm khóa học"),
      ),
      children: [
        if (_loadingCourses)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_selectedCourses.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xfff8f9fc),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.library_books_outlined,
                    size: 40,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Chưa có khóa học nào",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _showCourseSelector,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Thêm khóa học"),
                  ),
                ],
              ),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _selectedCourses.length,
            onReorder: _reorderCourses,
            itemBuilder: (context, index) {
              final course = _selectedCourses[index];
              return _buildCourseItem(course, index);
            },
          ),
      ],
    );
  }

  Widget _buildCourseItem(CourseItemDetail course, int index) {
    return Container(
      key: ValueKey(
        course.relationId.value != 0
            ? course.relationId.value
            : course.courseId.value,
      ),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          /// DRAG HANDLE
          ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_handle, color: Colors.grey),
          ),
          const SizedBox(width: 12),

          /// ORDER INDEX
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xff1a90ff),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                "${index + 1}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          /// COURSE INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (course.mentorName != null)
                  Text(
                    course.mentorName!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),

          /// MODULE COUNT
          if (course.moduleCount != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xffeef3ff),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "${course.moduleCount} modules",
                style: const TextStyle(fontSize: 11, color: Color(0xff1a90ff)),
              ),
            ),

          /// REMOVE
          IconButton(
            onPressed: () => _removeCourse(index),
            icon: const Icon(Icons.close, size: 18),
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    return _buildCard(
      title: "Xem trước",
      icon: Icons.preview,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xfff8f9fc),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _titleController.text.isEmpty
                    ? "Tiêu đề lộ trình"
                    : _titleController.text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _descriptionController.text.isEmpty
                    ? "Mô tả lộ trình học tập..."
                    : _descriptionController.text,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _previewChip(
                    Icons.menu_book,
                    "${_selectedCourses.length} khóa học",
                  ),
                  const SizedBox(width: 8),
                  _previewChip(
                    Icons.library_books,
                    "${_selectedCourses.fold(0, (sum, c) => sum + (c.moduleCount ?? 0))} bài học",
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _previewChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xffeef3ff),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xff1a90ff)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xff1a90ff)),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? action,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// CARD HEADER
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xff1a90ff)),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (action != null) action,
              ],
            ),
          ),

          /// CARD CONTENT
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================
/// COURSE SELECTOR DIALOG
/// ============================================
class _CourseSelectorDialog extends StatefulWidget {
  final List<Map<String, dynamic>> availableCourses;
  final Set<int> selectedCourseIds;
  final Function(List<Map<String, dynamic>> courses) onCoursesSelected;

  const _CourseSelectorDialog({
    required this.availableCourses,
    required this.selectedCourseIds,
    required this.onCoursesSelected,
  });

  @override
  State<_CourseSelectorDialog> createState() => _CourseSelectorDialogState();
}

class _CourseSelectorDialogState extends State<_CourseSelectorDialog> {
  final Set<int> _selected = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.selectedCourseIds);
  }

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return widget.availableCourses;
    return widget.availableCourses.where((c) {
      final title = (c['title'] ?? '').toLowerCase();
      return title.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Row(
              children: [
                const Text(
                  "Chọn khóa học",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            /// SEARCH
            TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: "Tìm kiếm khóa học...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
            const SizedBox(height: 16),

            /// SELECTED COUNT
            if (_selected.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  "Đã chọn: ${_selected.length} khóa học",
                  style: const TextStyle(
                    color: Color(0xff1a90ff),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            /// COURSE LIST
            Flexible(
              child:
                  _filtered.isEmpty
                      ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            "Không tìm thấy khóa học nào",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final course = _filtered[index];
                          final courseId = course['id'];
                          final isSelected = _selected.contains(courseId);
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selected.add(courseId);
                                } else {
                                  _selected.remove(courseId);
                                }
                              });
                            },
                            title: Text(
                              course['title'] ?? 'Khóa học',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              course['mentorName'] != null
                                  ? "${course['mentorName']} • ${course['moduleCount'] ?? 0} modules"
                                  : "${course['moduleCount'] ?? 0} modules",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            activeColor: const Color(0xff1a90ff),
                            dense: true,
                          );
                        },
                      ),
            ),
            const SizedBox(height: 16),

            /// ACTIONS
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Hủy"),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final selectedCourses =
                        widget.availableCourses
                            .where(
                              (c) =>
                                  _selected.contains(c['courseId'] ?? c['id']),
                            )
                            .toList();
                    widget.onCoursesSelected(selectedCourses);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff1a90ff),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text("Xác nhận"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
