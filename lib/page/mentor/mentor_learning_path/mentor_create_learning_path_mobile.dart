import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/core/theme/app_colors.dart';
import 'package:smet/core/utils/animations.dart';
import 'package:smet/model/learning_path_model.dart';
import 'package:smet/service/mentor/learning_path_service.dart';
import 'package:smet/service/common/global_notification_service.dart';

/// Mentor Create/Edit Learning Path - Mobile Layout
/// Nâng cấp UI: Animated header, modern form, course timeline, skeleton loading.
class MentorCreateLearningPathMobile extends StatefulWidget {
  final String? editId;

  const MentorCreateLearningPathMobile({super.key, this.editId});

  @override
  State<MentorCreateLearningPathMobile> createState() =>
      _MentorCreateLearningPathMobileState();
}

class _MentorCreateLearningPathMobileState
    extends State<MentorCreateLearningPathMobile>
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

      // Backend đã trả moduleCount và lessonCount trong API courses rồi.
      // Hiện tại dùng luôn dữ liệu từ backend (lấy từ countModulesAndLessons query).
      final enrichedCourses = courses.map((course) {
        return {
          ...course,
          'moduleCount': course['moduleCount'] ?? 0,
          'lessonCount': course['lessonCount'] ?? 0,
        };
      }).toList();

      setState(() {
        _availableCourses = enrichedCourses;
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
      GlobalNotificationService.show(
        context: context,
        message: 'Lỗi tải lộ trình: $e',
        type: NotificationType.error,
      );
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

        final currentDetail = await _service.getLearningPathDetail(
          _editingPathId!,
        );

        final selectedCourseIds =
            _selectedCourses.map((c) => c.courseId.value).toSet();

        for (final course in currentDetail.courses) {
          if (!selectedCourseIds.contains(course.courseId.value)) {
            await _service.removeCourseFromLearningPath(
              _editingPathId!,
              course.relationId,
            );
          }
        }

        // Deduplicate _selectedCourses: keep 1 entry per courseId, prefer saved (relationId>0) over new (relationId=0)
        final dedupedMap = <int, CourseItemDetail>{};
        for (final c in _selectedCourses) {
          final existing = dedupedMap[c.courseId.value];
          if (existing == null || (existing.relationId.value == 0 && c.relationId.value > 0)) {
            dedupedMap[c.courseId.value] = c;
          }
        }
        final deduped = dedupedMap.values.toList();

        // Build upsert list
        final upsertList = <Map<String, dynamic>>[];
        for (int i = 0; i < deduped.length; i++) {
          final course = deduped[i];
          if (course.relationId.value > 0) {
            upsertList.add({
              'relationId': course.relationId.value,
              'orderIndex': i,
            });
          } else {
            upsertList.add({
              'courseId': course.courseId.value,
              'orderIndex': i,
            });
          }
        }
        await _service.upsertCourses(_editingPathId!, upsertList);
      } else {
        final created = await _service.createLearningPath(
          _titleController.text.trim(),
          _descriptionController.text.trim(),
        );
        final createdId = Long(_parseLongFromMap(created['id']));
        _editingPathId = createdId;

        // Build upsert list for new path (all courses have relationId=0, use courseId)
        // Deduplicate to prevent duplicate entries if user somehow adds same course twice
        final upsertList = <Map<String, dynamic>>[];
        final seenCourseIds = <int>{};
        for (int i = 0; i < _selectedCourses.length; i++) {
          final courseId = _selectedCourses[i].courseId.value;
          if (seenCourseIds.contains(courseId)) continue;
          seenCourseIds.add(courseId);
          upsertList.add({
            'courseId': courseId,
            'orderIndex': upsertList.length,
          });
        }
        await _service.upsertCourses(createdId, upsertList);
      }

      GlobalNotificationService.show(
        context: context,
        message: _isEditMode ? 'Cập nhật thành công!' : 'Tạo lộ trình thành công!',
        type: NotificationType.success,
      );
      context.go('/mentor/learning-paths');
    } catch (e) {
      setState(() => _isSaving = false);
      GlobalNotificationService.show(
        context: context,
        message: 'Lỗi: $e',
        type: NotificationType.error,
      );
    }
  }

  void _showCourseSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => _MobileCourseSelectorSheet(
            availableCourses: _availableCourses,
            selectedCourseIds:
                _selectedCourses.map((c) => c.courseId.value).toSet(),
            onCoursesSelected: (courses) async {
              // Lọc ra chỉ khóa học CHƯA có trong _selectedCourses (tránh trùng lặp khi mở lại dialog)
              final existingIds = _selectedCourses
                  .map((c) => c.courseId.value)
                  .toSet();
              final newCourses = courses
                  .where((c) => !existingIds.contains(_parseLongFromMap(c['id'])))
                  .toList();

              if (newCourses.isEmpty) {
                Navigator.pop(context);
                return;
              }

              if (_editingPathId != null) {
                setState(() {
                  final newItems = newCourses.asMap().entries.map((entry) {
                    return CourseItemDetail(
                      relationId: Long(0),
                      courseId: Long(_parseLongFromMap(entry.value['id'])),
                      title: entry.value['title'] ?? 'Khoa hoc',
                      mentorName: entry.value['mentorName'],
                      moduleCount: entry.value['moduleCount'] ?? 0,
                      lessonCount: _parseInt(entry.value['lessonCount']),
                      orderIndex: _selectedCourses.length + entry.key,
                    );
                  }).toList();
                  _selectedCourses = [..._selectedCourses, ...newItems];
                });
                return;
              }

              setState(() {
                _selectedCourses = newCourses.asMap().entries.map((entry) {
                  return CourseItemDetail(
                    relationId: Long(0),
                    courseId: Long(_parseLongFromMap(entry.value['id'])),
                    title: entry.value['title'] ?? 'Khoa hoc',
                    mentorName: entry.value['mentorName'],
                    moduleCount: _parseInt(entry.value['moduleCount']),
                    lessonCount: _parseInt(entry.value['lessonCount']),
                    orderIndex: _selectedCourses.length + entry.key,
                  );
                }).toList();
              });
            },
          ),
    );
  }

  Future<void> _removeCourse(int index) async {
    final course = _selectedCourses[index];

    // Chỉ gọi API xóa nếu có relationId thực (đã save vào DB)
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
          courseId: _selectedCourses[i].courseId,
          relationId: _selectedCourses[i].relationId,
          title: _selectedCourses[i].title,
          mentorName: _selectedCourses[i].mentorName,
          moduleCount: _selectedCourses[i].moduleCount,
          lessonCount: _selectedCourses[i].lessonCount,
          orderIndex: i,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Column(
        children: [
          /// Animated Header
          FadeTransition(
            opacity: _fadeAnimation,
            child: _buildHeader(),
          ),

          /// Content
          Expanded(
            child: _isLoading
                ? _buildLoading()
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// Info Card
                          _buildInfoCard(),
                          const SizedBox(height: 20),

                          /// Courses Card
                          _buildCoursesCard(),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
          child: Column(
            children: [
              /// Top bar
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/mentor/learning-paths'),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditMode ? 'Chỉnh sửa lộ trình' : 'Tạo lộ trình mới',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _isEditMode
                              ? 'Cập nhật thông tin lộ trình'
                              : 'Xây dựng lộ trình học tập mới',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildSaveButton(),
                ],
              ),

              const SizedBox(height: 16),

              /// Stats row
              if (!_isLoading)
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        icon: Icons.menu_book_rounded,
                        value: '${_selectedCourses.length}',
                        label: 'Khóa học',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniStat(
                        icon: Icons.layers_outlined,
                        value:
                            '${_selectedCourses.fold(0, (sum, c) => sum + (c.lessonCount ?? c.moduleCount ?? 0))}',
                        label: 'Bài học',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniStat(
                        icon: Icons.linear_scale_rounded,
                        value: '${(_selectedCourses.length * 33).clamp(0, 100)}%',
                        label: 'Tiến độ',
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isSaving ? null : _save,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_rounded,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        _isEditMode ? 'Lưu' : 'Tạo',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      children: [
        _LoadingCard(),
        const SizedBox(height: 20),
        _LoadingCard(),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Card header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.info_outline,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Thông tin lộ trình",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                /// Title field
                _ModernTextField(
                  controller: _titleController,
                  label: "Tiêu đề lộ trình",
                  hint: "VD: Lộ trình Java Backend cho người mới",
                  icon: Icons.title_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Vui lòng nhập tiêu đề";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                /// Description field
                _ModernTextField(
                  controller: _descriptionController,
                  label: "Mô tả",
                  hint: "Mô tả ngắn về lộ trình học tập...",
                  icon: Icons.description_outlined,
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Card header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.menu_book,
                      color: AppColors.accentPurple, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Khóa học trong lộ trình",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textDark,
                        ),
                      ),
                      if (_selectedCourses.isNotEmpty)
                        Text(
                          "Kéo để sắp xếp thứ tự",
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _loadingCourses ? null : _showCourseSelector,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.add,
                                color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              "Thêm",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
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
          ),

          const SizedBox(height: 16),

          /// Course list
          if (_loadingCourses)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_selectedCourses.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.bgSlateLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.library_books_outlined,
                        size: 32,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      "Chưa có khóa học nào",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Thêm khóa học để xây dựng lộ trình học tập",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _showCourseSelector,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Chọn khóa học"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildCourseTimeline(),
        ],
      ),
    );
  }

  Future<void> _onCoursesReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _selectedCourses.removeAt(oldIndex);
      _selectedCourses.insert(newIndex, item);
      for (int i = 0; i < _selectedCourses.length; i++) {
        _selectedCourses[i] = CourseItemDetail(
          courseId: _selectedCourses[i].courseId,
          relationId: _selectedCourses[i].relationId,
          title: _selectedCourses[i].title,
          mentorName: _selectedCourses[i].mentorName,
          moduleCount: _selectedCourses[i].moduleCount,
          lessonCount: _selectedCourses[i].lessonCount,
          orderIndex: i,
        );
      }
    });

    if (_editingPathId != null) {
      // Kiểm tra có course nào chưa có relationId (chưa save) thì không gọi API
      final hasUnsavedCourse = _selectedCourses.any((c) => c.relationId.value == 0);
      if (hasUnsavedCourse) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning_amber_outlined, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(child: Text("Vui lòng lưu lộ trình trước khi sắp xếp")),
                ],
              ),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
        // Rollback: reload từ backend
        final detail = await _service.getLearningPathDetail(_editingPathId!);
        setState(() {
          _selectedCourses = detail.courses;
        });
        return;
      }

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
        // Rollback: reload từ backend
        final detail = await _service.getLearningPathDetail(_editingPathId!);
        setState(() {
          _selectedCourses = detail.courses;
        });
      }
    }
  }

  Widget _buildCourseTimeline() {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      itemCount: _selectedCourses.length,
      onReorder: _onCoursesReorder,
      itemBuilder: (context, index) {
        final course = _selectedCourses[index];
        return _TimelineCourseItem(
          key: ValueKey(
            course.relationId.value != 0
                ? course.relationId.value
                : course.courseId.value,
          ),
          course: course,
          index: index,
          isLast: index == _selectedCourses.length - 1,
          onRemove: () => _removeCourse(index),
        );
      },
    );
  }
}

// ─── Timeline Course Item ────────────────────────────────────────────────────

class _TimelineCourseItem extends StatefulWidget {
  final CourseItemDetail course;
  final int index;
  final bool isLast;
  final VoidCallback onRemove;

  const _TimelineCourseItem({
    super.key,
    required this.course,
    required this.index,
    required this.isLast,
    required this.onRemove,
  });

  @override
  State<_TimelineCourseItem> createState() => _TimelineCourseItemState();
}

class _TimelineCourseItemState extends State<_TimelineCourseItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Timeline line + dot
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${widget.index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            if (!widget.isLast)
              Container(
                width: 2,
                height: 60,
                color: AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 12),

        /// Course card
        Expanded(
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: AnimatedContainer(
              duration: AppAnimations.fast,
              margin: EdgeInsets.only(bottom: widget.isLast ? 0 : 16),
              decoration: BoxDecoration(
                color: _isHovered
                    ? AppColors.primary.withValues(alpha: 0.03)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isHovered
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.border,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Course info (chiếm phần lớn chiều ngang)
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.course.mentorName != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.person_outline,
                                    size: 13, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Expanded(
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
                              ],
                            ),
                          ],
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.layers_outlined,
                                  size: 13, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                "${widget.course.lessonCount ?? widget.course.moduleCount ?? 0} chương",
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

                    /// Kéo + X: gom một cụm bên phải, cách nhau rõ ràng (tránh bấm nhầm)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ReorderableDragStartListener(
                          index: widget.index,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 6,
                            ),
                            child: Icon(
                              Icons.drag_handle,
                              color: AppColors.textMuted,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        AnimatedContainer(
                          duration: AppAnimations.fast,
                          decoration: BoxDecoration(
                            color: _isHovered
                                ? AppColors.badgeRedBg
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: widget.onRemove,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: _isHovered
                                      ? AppColors.error
                                      : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Modern TextField ────────────────────────────────────────────────────────

class _ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final String? Function(String?)? validator;

  const _ModernTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
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
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
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
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

// ─── Mini Stat ────────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Loading Card ─────────────────────────────────────────────────────────────

class _LoadingCard extends StatefulWidget {
  @override
  State<_LoadingCard> createState() => _LoadingCardState();
}

class _LoadingCardState extends State<_LoadingCard>
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
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: _animation.value),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 14,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: _animation.value),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...List.generate(2, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: _animation.value * 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )),
            ],
          ),
        );
      },
    );
  }
}

// ─── Mobile Course Selector Bottom Sheet ────────────────────────────────────

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
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              /// Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              /// Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          const Icon(Icons.library_books,
                              color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Chọn khóa học",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          if (_selected.isNotEmpty)
                            Text(
                              "Đã chọn ${_selected.length} khóa học",
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),

              /// Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
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
                      prefixIcon: Icon(Icons.search,
                          color: AppColors.textMuted, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              /// Course list
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off_rounded,
                                size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            const Text(
                              "Không tìm thấy khóa học",
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
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final course = _filtered[index];
                          final courseId = course['id'];
                          int courseIdInt;
                          if (courseId is int) {
                            courseIdInt = courseId;
                          } else if (courseId is double) {
                            courseIdInt = courseId.toInt();
                          } else if (courseId is String) {
                            courseIdInt = int.tryParse(courseId) ?? 0;
                          } else {
                            courseIdInt = 0;
                          }
                          final alreadyAdded = _selected.contains(courseIdInt);
                          return _CourseSelectItem(
                            course: course,
                            isSelected: _selected.contains(courseIdInt),
                            enabled: !alreadyAdded,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selected.add(courseIdInt);
                                } else {
                                  _selected.remove(courseIdInt);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),

              /// Bottom action
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
                    Expanded(
                      child: Text(
                        _selected.isEmpty
                            ? "Chưa chọn khóa học nào"
                            : "${_selected.length} khóa học đã chọn",
                        style: TextStyle(
                          color: _selected.isEmpty
                              ? AppColors.textMuted
                              : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _selected.isEmpty
                          ? null
                          : () {
                              // Chỉ lấy courses có trong _selected (parse ID trước khi so sánh)
                              final selectedCourses = <Map<String, dynamic>>[];
                              for (final course in widget.availableCourses) {
                                final cid = course['id'];
                                int courseId;
                                if (cid is int) {
                                  courseId = cid;
                                } else if (cid is double) {
                                  courseId = cid.toInt();
                                } else if (cid is String) {
                                  courseId = int.tryParse(cid) ?? 0;
                                } else {
                                  courseId = 0;
                                }
                                if (courseId != 0 && _selected.contains(courseId)) {
                                  selectedCourses.add(course);
                                }
                              }
                              widget.onCoursesSelected(selectedCourses);
                              Navigator.pop(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.border,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Xác nhận"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CourseSelectItem extends StatefulWidget {
  final Map<String, dynamic> course;
  final bool isSelected;
  final bool enabled;
  final ValueChanged<bool?> onChanged;

  const _CourseSelectItem({
    required this.course,
    required this.isSelected,
    required this.enabled,
    required this.onChanged,
  });

  @override
  State<_CourseSelectItem> createState() => _CourseSelectItemState();
}

class _CourseSelectItemState extends State<_CourseSelectItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isAdded = !widget.enabled;

    return AnimatedOpacity(
      duration: AppAnimations.fast,
      opacity: isAdded ? 0.55 : 1.0,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.primary.withValues(alpha: 0.05)
                : _isHovered && !isAdded
                    ? AppColors.bgSlateLight
                    : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : isAdded
                      ? AppColors.border
                      : AppColors.border,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: isAdded ? null : () => widget.onChanged(!widget.isSelected),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: AppAnimations.fast,
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: widget.isSelected
                            ? AppColors.primary
                            : isAdded
                                ? AppColors.success.withValues(alpha: 0.2)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: widget.isSelected
                              ? AppColors.primary
                              : isAdded
                                  ? AppColors.success
                                  : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: widget.isSelected
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : isAdded
                              ? const Icon(Icons.check_circle_outline,
                                  size: 14, color: AppColors.success)
                              : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.course['title'] ?? 'Khóa học',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: isAdded
                                        ? AppColors.textMuted
                                        : AppColors.textDark,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isAdded) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Đã thêm',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (widget.course['mentorName'] != null) ...[
                                const Icon(Icons.person_outline,
                                    size: 12, color: AppColors.textMuted),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    widget.course['mentorName']!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              const Icon(Icons.layers_outlined,
                                  size: 12, color: AppColors.textMuted),
                              const SizedBox(width: 3),
                              Text(
                                "${widget.course['lessonCount'] ?? widget.course['moduleCount'] ?? 0} chương",
                                style: const TextStyle(
                                  fontSize: 11,
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
      ),
    );
  }
}
