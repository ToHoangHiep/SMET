import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/learning_path_model.dart';
import 'package:smet/service/mentor/learning_path_service.dart';

/// Mentor Create/Edit Learning Path - Mobile Layout
class MentorCreateLearningPathMobile extends StatefulWidget {
  final String? editId;

  const MentorCreateLearningPathMobile({super.key, this.editId});

  @override
  State<MentorCreateLearningPathMobile> createState() =>
      _MentorCreateLearningPathMobileState();
}

class _MentorCreateLearningPathMobileState
    extends State<MentorCreateLearningPathMobile> {
  final LearningPathService _service = LearningPathService();
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isEditMode = false;
  Long? _editingPathId;

  List<Map<String, dynamic>> _availableCourses = [];
  bool _loadingCourses = true;

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
        // Cap nhat title va description
        await _service.updateLearningPath(
          _editingPathId!,
          _titleController.text.trim(),
          _descriptionController.text.trim(),
        );

        // Lay chi tiet hien tai de biet courses nao can xoa
        final currentDetail = await _service.getLearningPathDetail(
          _editingPathId!,
        );

        // Lay danh sach courseId hien tai
        final existingCourseIds =
            currentDetail.courses.map((c) => c.courseId.value).toSet();
        // Lay danh sach courseId da chon
        final selectedCourseIds =
            _selectedCourses.map((c) => c.courseId.value).toSet();

        // Xoa courses khong con trong danh sach da chon
        for (final course in currentDetail.courses) {
          if (!selectedCourseIds.contains(course.courseId.value)) {
            await _service.removeCourseFromLearningPath(
              _editingPathId!,
              course.relationId, // 👈 CHUẨN
            );
          }
        }

        // Them courses moi chua co
        for (int i = 0; i < _selectedCourses.length; i++) {
          final courseId = _selectedCourses[i].courseId.value;
          if (!existingCourseIds.contains(courseId)) {
            await _service.addCourseToLearningPath(
              _editingPathId!,
              _selectedCourses[i].courseId,
              i,
            );
          }
        }
      } else {
        // CREATE
        final created = await _service.createLearningPath(
          _titleController.text.trim(),
          _descriptionController.text.trim(),
        );
        final createdId = Long(_parseLongFromMap(created['id']));
        _editingPathId = createdId;

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
        context.go('/mentor/learning-paths');
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => _MobileCourseSelectorSheet(
            availableCourses: _availableCourses,
            selectedCourseIds:
                _selectedCourses.map((c) => c.courseId.value).toSet(),
            onCoursesSelected: (courses) {
              setState(() {
                _selectedCourses =
                    courses.asMap().entries.map((entry) {
                      return CourseItemDetail(
                        relationId: Long(0), // 👈 THÊM DÒNG NÀY
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

    // 👉 gọi API nếu đang edit và có relationId
    if (_editingPathId != null && course.relationId.value != 0) {
      try {
        await _service.removeCourseFromLearningPath(
          _editingPathId!,
          course.relationId, // 👈 CHUẨN
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

    // 👉 remove UI
    setState(() {
      _selectedCourses.removeAt(index);

      // reindex
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/mentor/learning-paths'),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: Text(
          _isEditMode ? "Chỉnh sửa lộ trình" : "Tạo lộ trình mới",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child:
                _isSaving
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Text(
                      _isEditMode ? "Lưu" : "Tạo",
                      style: const TextStyle(
                        color: Color(0xff1a90ff),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// INFO CARD
                      _buildCard(
                        children: [
                          /// TITLE
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: "Tiêu đề lộ trình",
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
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      /// COURSES CARD
                      _buildCard(
                        title: "Khóa học",
                        trailing: TextButton.icon(
                          onPressed:
                              _loadingCourses ? null : _showCourseSelector,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text("Thêm"),
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
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xfff8f9fc),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.library_books_outlined,
                                      size: 36,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Chưa có khóa học nào",
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _selectedCourses.length,
                              itemBuilder: (context, index) {
                                final course = _selectedCourses[index];
                                return _buildMobileCourseItem(course, index);
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildMobileCourseItem(CourseItemDetail course, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
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
          IconButton(
            onPressed: () => _removeCourse(index),
            icon: const Icon(Icons.close, size: 18),
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required List<Widget> children,
    String? title,
    Widget? trailing,
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
                      fontSize: 16,
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
}

/// ============================================
/// MOBILE COURSE SELECTOR BOTTOM SHEET
/// ============================================
class _MobileCourseSelectorSheet extends StatefulWidget {
  final List<Map<String, dynamic>> availableCourses;
  final Set<int> selectedCourseIds;
  final Function(List<Map<String, dynamic>> courses) onCoursesSelected;

  const _MobileCourseSelectorSheet({
    required this.availableCourses,
    required this.selectedCourseIds,
    required this.onCoursesSelected,
  });

  @override
  State<_MobileCourseSelectorSheet> createState() =>
      _MobileCourseSelectorSheetState();
}

class _MobileCourseSelectorSheetState
    extends State<_MobileCourseSelectorSheet> {
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
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            /// HANDLE
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            /// HEADER
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    "Chọn khóa học",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (_selected.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        final selectedCourses =
                            widget.availableCourses
                                .where(
                                  (c) => _selected.contains(
                                    c['courseId'] ?? c['id'],
                                  ),
                                )
                                .toList();
                        widget.onCoursesSelected(selectedCourses);
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Xác nhận (${_selected.length})",
                        style: const TextStyle(color: Color(0xff1a90ff)),
                      ),
                    ),
                ],
              ),
            ),

            /// SEARCH
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
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
            ),
            const SizedBox(height: 8),

            /// LIST
            Expanded(
              child:
                  _filtered.isEmpty
                      ? Center(
                        child: Text(
                          "Không tìm thấy khóa học",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                      : ListView.builder(
                        controller: scrollController,
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
                          );
                        },
                      ),
            ),
          ],
        );
      },
    );
  }
}
