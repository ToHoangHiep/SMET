import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/core/theme/app_colors.dart';
import 'package:smet/core/utils/animations.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/model/learning_path_model.dart';
import 'package:smet/service/mentor/learning_path_service.dart';

/// Mentor Create/Edit Learning Path - Web Layout
/// Nâng cấp UI: drag-drop course cards với hover, live preview, dialog nâng cấp.
class MentorCreateLearningPathWeb extends StatefulWidget {
  final String? editId;

  const MentorCreateLearningPathWeb({super.key, this.editId});

  @override
  State<MentorCreateLearningPathWeb> createState() =>
      _MentorCreateLearningPathWebState();
}

class _MentorCreateLearningPathWebState
    extends State<MentorCreateLearningPathWeb>
    with SingleTickerProviderStateMixin {
  final LearningPathService _service = LearningPathService();
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditMode = false;
  Long? _editingPathId;

  List<Map<String, dynamic>> _availableCourses = [];
  bool _loadingCourses = true;

  List<CourseItemDetail> _selectedCourses = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.editId != null && widget.editId!.isNotEmpty;
    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
    _loadAvailableCourses();
    if (_isEditMode) {
      _loadExistingPath();
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text("Lỗi tải khóa học: $e")),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text("Lỗi tải lộ trình: $e")),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      if (_isEditMode && _editingPathId != null) {
        await _service.updateLearningPath(
          _editingPathId!,
          _titleController.text.trim(),
          _descriptionController.text.trim(),
        );
      } else {
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
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(_isEditMode
                    ? "Cập nhật thành công!"
                    : "Tạo lộ trình thành công!"),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text("Lỗi: $e")),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
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
                        relationId: Long(0),
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

    if (_editingPathId != null && course.relationId.value != 0) {
      try {
        await _service.removeCourseFromLearningPath(
          _editingPathId!,
          course.relationId,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text("Xóa thất bại: $e")),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _selectedCourses.removeAt(index);
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

    if (_editingPathId != null) {
      try {
        final orders = _selectedCourses
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text("Reorder thất bại: $e")),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Column(
        children: [
          /// Animated Page Header
          FadeTransition(
            opacity: _fadeAnimation,
            child: _buildPageHeader(),
          ),

          /// Content
          Expanded(
            child:
                _isLoading
                    ? _buildLoading()
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

                              /// RIGHT - LIVE PREVIEW
                              Expanded(flex: 2, child: _buildLivePreviewCard()),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(30, 30, 30, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.add_road_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SharedBreadcrumb(
                  items: [
                    const BreadcrumbItem(
                        label: "Lộ trình", route: "/mentor/learning-paths"),
                    BreadcrumbItem(
                      label:
                          _isEditMode ? "Chỉnh sửa lộ trình" : "Tạo lộ trình mới",
                    ),
                  ],
                  primaryColor: AppColors.primary,
                  fontSize: 13,
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 6),
                Text(
                  _isEditMode ? 'Chỉnh sửa lộ trình' : 'Tạo lộ trình mới',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => context.go('/mentor/learning-paths'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Hủy"),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _isSaving ? null : _save,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _isEditMode ? 'Lưu thay đổi' : 'Tạo lộ trình',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return ListView(
      padding: const EdgeInsets.all(30),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  _LoadingCardWeb(),
                  const SizedBox(height: 24),
                  _LoadingCardWeb(),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(flex: 2, child: _LoadingCardWeb()),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return _ModernCard(
      icon: Icons.info_outline_rounded,
      iconColor: AppColors.primary,
      iconBgColor: AppColors.primary.withValues(alpha: 0.08),
      title: "Thông tin lộ trình",
      child: Column(
        children: [
          /// Title field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel(
                icon: Icons.title_rounded,
                label: "Tiêu đề lộ trình",
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: "VD: Lộ trình Java Backend cho người mới",
                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  filled: true,
                  fillColor: AppColors.bgSlateLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.error, width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Vui lòng nhập tiêu đề";
                  }
                  return null;
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          /// Description field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel(
                icon: Icons.description_outlined,
                label: "Mô tả",
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: "Mô tả ngắn về lộ trình học tập...",
                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  filled: true,
                  fillColor: AppColors.bgSlateLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                maxLines: 4,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesCard() {
    return _ModernCard(
      icon: Icons.menu_book_rounded,
      iconColor: AppColors.accentPurple,
      iconBgColor: AppColors.accentPurple.withValues(alpha: 0.08),
      title: "Khóa học trong lộ trình",
      trailing: _AddCourseButton(
        onPressed: _loadingCourses ? null : _showCourseSelector,
      ),
      child:
          _loadingCourses
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _selectedCourses.isEmpty
                  ? _buildEmptyCourses()
                  : _buildCourseList(),
    );
  }

  Widget _buildEmptyCourses() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.bgSlateLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.library_books_outlined,
                    size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            "Chưa có khóa học nào",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Thêm khóa học để xây dựng lộ trình học tập cho học viên",
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _showCourseSelector,
            icon: const Icon(Icons.add, size: 18),
            label: const Text("Thêm khóa học"),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseList() {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _selectedCourses.length,
      onReorder: _reorderCourses,
      itemBuilder: (context, index) {
        final course = _selectedCourses[index];
        return _CourseCardWeb(
          key: ValueKey(
            course.relationId.value != 0
                ? course.relationId.value
                : course.courseId.value,
          ),
          course: course,
          index: index,
          onRemove: () => _removeCourse(index),
        );
      },
    );
  }

  Widget _buildLivePreviewCard() {
    final titleText = _titleController.text.isEmpty
        ? "Tiêu đề lộ trình"
        : _titleController.text;
    final descText = _descriptionController.text.isEmpty
        ? "Mô tả lộ trình học tập..."
        : _descriptionController.text;
    final totalModules =
        _selectedCourses.fold(0, (sum, c) => sum + (c.moduleCount ?? 0));

    return _ModernCard(
      icon: Icons.preview_rounded,
      iconColor: AppColors.success,
      iconBgColor: AppColors.success.withValues(alpha: 0.08),
      title: "Xem trước lộ trình",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Preview card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          const Icon(Icons.route_rounded,
                              color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        titleText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  descText,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _PreviewChip(
                      icon: Icons.menu_book_rounded,
                      label: "${_selectedCourses.length} khóa học",
                    ),
                    const SizedBox(width: 8),
                    _PreviewChip(
                      icon: Icons.layers_outlined,
                      label: "$totalModules bài học",
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// Course order preview
          if (_selectedCourses.isNotEmpty) ...[
            const _FieldLabel(
              icon: Icons.format_list_numbered_rounded,
              label: "Thứ tự khóa học",
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgSlateLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: List.generate(_selectedCourses.length, (i) {
                  final course = _selectedCourses[i];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: i < _selectedCourses.length - 1 ? 8 : 0,
                    ),
                    child: _OrderItem(course: course, index: i),
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Modern Card ─────────────────────────────────────────────────────────────

class _ModernCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final Widget? trailing;
  final Widget child;

  const _ModernCard({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Card header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
          ),

          /// Card content
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ─── Course Card Web ─────────────────────────────────────────────────────────

class _CourseCardWeb extends StatefulWidget {
  final CourseItemDetail course;
  final int index;
  final VoidCallback onRemove;

  const _CourseCardWeb({
    super.key,
    required this.course,
    required this.index,
    required this.onRemove,
  });

  @override
  State<_CourseCardWeb> createState() => _CourseCardWebState();
}

class _CourseCardWebState extends State<_CourseCardWeb> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _isHovered
              ? AppColors.primary.withValues(alpha: 0.02)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.border,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        transform: Matrix4.identity()
          ..translate(0.0, _isHovered ? -1.0 : 0.0),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Order badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    "${widget.index + 1}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              /// Course info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.course.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (widget.course.mentorName != null) ...[
                          Icon(Icons.person_outline,
                              size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              widget.course.mentorName!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (widget.course.moduleCount != null) ...[
                          Icon(Icons.layers_outlined,
                              size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            "${widget.course.moduleCount} bài học",
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              /// Module badge (tách khỏi cụm kéo + xóa)
              if (widget.course.moduleCount != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "${widget.course.moduleCount} bài",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentPurple,
                    ),
                  ),
                ),
              ],

              /// Kéo + X: cùng một hàng, SizedBox cố định giữa hai nút
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ReorderableDragStartListener(
                    index: widget.index,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.grab,
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _isHovered
                              ? AppColors.primary.withValues(alpha: 0.06)
                              : AppColors.bgSlateLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.drag_indicator_rounded,
                          color: _isHovered
                              ? AppColors.primary
                              : AppColors.textMuted,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _RemoveButton(
                    isHovered: _isHovered,
                    onPressed: widget.onRemove,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemoveButton extends StatefulWidget {
  final bool isHovered;
  final VoidCallback onPressed;

  const _RemoveButton({required this.isHovered, required this.onPressed});

  @override
  State<_RemoveButton> createState() => _RemoveButtonState();
}

class _RemoveButtonState extends State<_RemoveButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: "Xóa khỏi lộ trình",
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: AppAnimations.fast,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isHovered ? AppColors.badgeRedBg : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isHovered
                    ? AppColors.error.withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
            ),
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: _isHovered ? AppColors.error : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Add Course Button ───────────────────────────────────────────────────────

class _AddCourseButton extends StatefulWidget {
  final VoidCallback? onPressed;

  const _AddCourseButton({required this.onPressed});

  @override
  State<_AddCourseButton> createState() => _AddCourseButtonState();
}

class _AddCourseButtonState extends State<_AddCourseButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: widget.onPressed != null
                ? AppColors.primaryGradient
                : null,
            color: widget.onPressed == null ? AppColors.border : null,
            borderRadius: BorderRadius.circular(10),
            boxShadow: widget.onPressed != null && _isHovered
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add,
                  size: 16,
                  color: widget.onPressed != null
                      ? Colors.white
                      : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                "Thêm khóa học",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.onPressed != null
                      ? Colors.white
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Field Label ─────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FieldLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}

// ─── Preview Chip ────────────────────────────────────────────────────────────

class _PreviewChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PreviewChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Order Item ───────────────────────────────────────────────────────────────

class _OrderItem extends StatelessWidget {
  final CourseItemDetail course;
  final int index;

  const _OrderItem({required this.course, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              "${index + 1}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            course.title,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textDark,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── Loading Card Web ─────────────────────────────────────────────────────────

class _LoadingCardWeb extends StatefulWidget {
  @override
  State<_LoadingCardWeb> createState() => _LoadingCardWebState();
}

class _LoadingCardWebState extends State<_LoadingCardWeb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(4, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                height: i == 0 || i == 1 ? 48 : 16,
                width: i == 2 ? 200 : double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: _animation.value * 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )),
          ),
        );
      },
    );
  }
}

// ─── Course Selector Dialog ───────────────────────────────────────────────────

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 640,
        constraints: const BoxConstraints(maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        const Icon(Icons.library_books,
                            color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Chọn khóa học",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _selected.isEmpty
                              ? "Chọn các khóa học để thêm vào lộ trình"
                              : "${_selected.length} khóa học đã được chọn",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            /// Search
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.bgSlateLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: "Tìm kiếm khóa học...",
                    hintStyle:
                        TextStyle(color: AppColors.textMuted, fontSize: 14),
                    prefixIcon:
                        Icon(Icons.search, color: AppColors.textMuted, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                size: 18, color: AppColors.textMuted),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                  ),
                ),
              ),
            ),

            /// Course list
            Flexible(
              child: _filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_rounded,
                              size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          const Text(
                            "Không tìm thấy khóa học nào",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final course = _filtered[index];
                        final courseId = course['id'];
                        final isSelected = _selected.contains(courseId);
                        return _DialogCourseItem(
                          course: course,
                          isSelected: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selected.add(courseId);
                              } else {
                                _selected.remove(courseId);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),

            /// Actions
            Container(
              padding: EdgeInsets.fromLTRB(
                  20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_selected.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${_selected.length} đã chọn",
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    Text(
                      "Chưa chọn khóa học nào",
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 13),
                    ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    child: const Text("Hủy"),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: _selected.isNotEmpty
                          ? AppColors.primaryGradient
                          : null,
                      color: _selected.isEmpty ? AppColors.border : null,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: _selected.isNotEmpty
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: _selected.isEmpty
                            ? null
                            : () {
                                final selectedCourses =
                                    widget.availableCourses
                                        .where(
                                          (c) =>
                                              _selected
                                                  .contains(c['courseId'] ?? c['id']),
                                        )
                                        .toList();
                                widget.onCoursesSelected(selectedCourses);
                                Navigator.pop(context);
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 10),
                          child: Text(
                            "Xác nhận",
                            style: TextStyle(
                              color: _selected.isNotEmpty
                                  ? Colors.white
                                  : AppColors.textMuted,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogCourseItem extends StatefulWidget {
  final Map<String, dynamic> course;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;

  const _DialogCourseItem({
    required this.course,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  State<_DialogCourseItem> createState() => _DialogCourseItemState();
}

class _DialogCourseItemState extends State<_DialogCourseItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : _isHovered
                  ? AppColors.bgSlateLight
                  : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isSelected
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.border,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => widget.onChanged(!widget.isSelected),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: AppAnimations.fast,
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: widget.isSelected ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: widget.isSelected
                            ? AppColors.primary
                            : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: widget.isSelected
                        ? const Icon(Icons.check,
                            size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.course['title'] ?? 'Khóa học',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (widget.course['mentorName'] != null) ...[
                              Icon(Icons.person_outline,
                                  size: 12, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                widget.course['mentorName']!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            Icon(Icons.layers_outlined,
                                size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              "${widget.course['moduleCount'] ?? 0} bài học",
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
