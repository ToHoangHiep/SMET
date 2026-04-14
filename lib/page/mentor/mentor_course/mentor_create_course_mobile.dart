import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/shared/widgets/rich_text_editor.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/model/department_model.dart';
import 'package:smet/service/admin/department_management/api_department_management.dart';
import 'package:smet/service/common/auth_service.dart';
import 'package:smet/service/mentor/course_service.dart';
import 'package:smet/service/common/global_notification_service.dart';

import 'dart:developer';

/// Mentor Create Course - Mobile Layout
/// UI mềm mại, hiện đại với Rich Text Editor.
class MentorCreateCourseMobile extends StatefulWidget {
  const MentorCreateCourseMobile({super.key});

  @override
  State<MentorCreateCourseMobile> createState() =>
      _MentorCreateCourseMobileState();
}

class _MentorCreateCourseMobileState extends State<MentorCreateCourseMobile>
    with SingleTickerProviderStateMixin {
  static const _primary = Color(0xFF6366F1);
  static const _primaryLight = Color(0xFF818CF8);
  static const _bgLight = Color(0xFFF3F6FC);
  static const _cardBorder = Color(0xFFE8ECF4);
  static const _textDark = Color(0xFF0F172A);
  static const _textMedium = Color(0xFF64748B);
  static const _textLight = Color(0xFF94A3B8);
  static const _success = Color(0xFF22C55E);

  final MentorCourseService _courseService = MentorCourseService();

  late TabController _tabController;
  late QuillController _quillController;
  bool _isSaving = false;

  final _titleController = TextEditingController();

  List<DepartmentModel> _departments = [];
  DepartmentModel? _selectedDepartment;
  bool _loadingDepartments = false;

  DeadlineType _deadlineType = DeadlineType.RELATIVE;
  int _defaultDeadlineDays = 20;
  DateTime? _fixedDeadline;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _quillController = QuillController.basic();
    _loadDepartments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    setState(() => _loadingDepartments = true);
    try {
      final userData = await AuthService.getMe();
      final userDeptId = userData['departmentId'] as int?;
      final userDeptName = userData['departmentName'] as String?;
      if (userDeptId != null && userDeptName != null) {
        final synthetic = DepartmentModel(
          id: userDeptId,
          name: userDeptName,
          code: userData['departmentCode']?.toString() ?? '',
          isActive: true,
        );
        setState(() {
          _departments = [synthetic];
          _selectedDepartment = synthetic;
          _loadingDepartments = false;
        });
        return;
      }
    } catch (e) {
      log("Could not get current user from auth/me: $e");
    }
    setState(() {
      _departments = [];
      _selectedDepartment = null;
      _loadingDepartments = false;
    });
  }

  Future<void> _saveCourse() async {
    if (_titleController.text.trim().isEmpty) {
      GlobalNotificationService.show(
        context: context,
        message: 'Vui lòng nhập tên khóa học',
        type: NotificationType.warning,
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final plainDescription = _quillController.document.toPlainText().trim();
      String? fixedDeadlineStr;
      if (_deadlineType == DeadlineType.FIXED && _fixedDeadline != null) {
        fixedDeadlineStr = _fixedDeadline!.toIso8601String();
      }
      final request = CreateCourseRequest(
        title: _titleController.text.trim(),
        description: plainDescription.isNotEmpty ? plainDescription : null,
        deadlineType: _deadlineType.name,
        defaultDeadlineDays:
            _deadlineType == DeadlineType.RELATIVE
                ? _defaultDeadlineDays
                : null,
        fixedDeadline: fixedDeadlineStr,
      );
      await _courseService.createCourse(request);
      if (mounted) {
        GlobalNotificationService.show(
          context: context,
          message: 'Tạo khóa học thành công!',
          type: NotificationType.success,
        );
        context.go(
          '/mentor/courses?refresh=${DateTime.now().millisecondsSinceEpoch}',
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      GlobalNotificationService.show(
        context: context,
        message: e.toString(),
        type: NotificationType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: _textDark, size: 20),
          onPressed: () => context.go('/mentor/courses'),
        ),
        title: const Text(
          "Tạo khóa học mới",
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w800,
            fontSize: 17,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            child: _AnimatedSaveButton(
              primaryColor: _primary,
              isSaving: _isSaving,
              onPressed: _saveCourse,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildTabBar(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildInfoTab(), _buildStructureTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
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
                SizedBox(width: 8),
                Text("Thông tin"),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_tree_outlined, size: 18),
                SizedBox(width: 8),
                Text("Cấu trúc"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Thông tin cơ bản
          _buildSoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader("Thông tin cơ bản", Icons.book_outlined),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: _fieldInput(
                    "Tên khóa học *",
                    icon: Icons.school_outlined,
                  ),
                ),
                const SizedBox(height: 14),
                _fieldLabelRow("Mô tả khóa học", Icons.description_outlined),
                const SizedBox(height: 8),
                RichTextEditorWidget(
                  hintText: "Nhập mô tả về khóa học...",
                  primaryColor: _primary,
                  maxHeight: 140,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Phòng ban
          _buildSoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader("Phòng ban", Icons.apartment_outlined),
                const SizedBox(height: 14),
                _buildDepartmentBadge(),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Deadline
          _buildSoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader("Cài đặt deadline", Icons.timer_outlined),
                const SizedBox(height: 14),
                _buildDeadlineTypeSelector(),
                const SizedBox(height: 14),
                if (_deadlineType == DeadlineType.RELATIVE) ...[
                  Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Icon(
                                Icons.numbers,
                                size: 18,
                                color: _textLight,
                              ),
                            ),
                            prefixIconColor: _textLight,
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
                              borderSide: BorderSide(
                                color: _primary,
                                width: 1.5,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                          ),
                          controller: TextEditingController(
                            text: '$_defaultDeadlineDays',
                          ),
                          onChanged: (v) {
                            final parsed = int.tryParse(v);
                            if (parsed != null && parsed > 0)
                              setState(() => _defaultDeadlineDays = parsed);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "ngày sau khi đăng ký",
                          style: TextStyle(fontSize: 14, color: _textMedium),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  _DatePickerButton(
                    selectedDate: _fixedDeadline,
                    primaryColor: _primary,
                    onPicked: (date) {
                      setState(() => _fixedDeadline = date);
                    },
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildDepartmentBadge() {
    if (_loadingDepartments) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _cardBorder),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
            ),
            const SizedBox(width: 12),
            Text(
              "Đang xác định phòng ban...",
              style: TextStyle(fontSize: 15, color: _textMedium),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
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
                  _selectedDepartment?.name ?? "Không xác định được",
                  style: TextStyle(
                    fontSize: 15,
                    color:
                        _selectedDepartment != null ? _textDark : _textMedium,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_selectedDepartment != null)
                  Text(
                    _selectedDepartment!.code,
                    style: TextStyle(fontSize: 11, color: _textLight),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 12, color: _success),
                const SizedBox(width: 4),
                Text(
                  "Auto",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _DeadlineTypeOption(
            label: "Tương đối",
            icon: Icons.schedule,
            isSelected: _deadlineType == DeadlineType.RELATIVE,
            onTap: () => setState(() => _deadlineType = DeadlineType.RELATIVE),
            primaryColor: _primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _DeadlineTypeOption(
            label: "Ngày cố định",
            icon: Icons.event,
            isSelected: _deadlineType == DeadlineType.FIXED,
            onTap: () => setState(() => _deadlineType = DeadlineType.FIXED),
            primaryColor: _primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStructureTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _primary.withValues(alpha: 0.12),
                          _primaryLight.withValues(alpha: 0.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_tree_outlined,
                      color: _primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Cấu trúc khóa học",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildEmptyStructureState(),
        ],
      ),
    );
  }

  Widget _buildEmptyStructureState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, _primary.withValues(alpha: 0.01)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _primary.withValues(alpha: 0.1),
                  _primaryLight.withValues(alpha: 0.04),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _primary.withValues(alpha: 0.08),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(
              Icons.library_books_outlined,
              size: 40,
              color: _primary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Chưa có chương nào",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 300,
            child: Text(
              "Tạo khóa học và quay lại trang chỉnh sửa để thêm chương và bài học.",
              style: TextStyle(fontSize: 14, color: _textMedium, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          // Steps
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _cardBorder),
            ),
            child: Column(
              children: [
                _buildStepRow(
                  1,
                  "Điền thông tin",
                  Icons.info_outline,
                  _primary,
                ),
                const SizedBox(height: 10),
                _buildStepRow(
                  2,
                  "Tạo khóa học",
                  Icons.add_circle_outline,
                  _primary,
                ),
                const SizedBox(height: 10),
                _buildStepRow(
                  3,
                  "Thêm chương & bài học",
                  Icons.bookmark_add_outlined,
                  _primaryLight,
                ),
                const SizedBox(height: 10),
                _buildStepRow(
                  4,
                  "Xuất bản",
                  Icons.rocket_launch_outlined,
                  _success,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow(int step, String text, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              "$step",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: _textMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ─── HELPERS ───

  InputDecoration _fieldInput(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon:
          icon != null
              ? Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Icon(icon, color: _textLight, size: 20),
              )
              : null,
      prefixIconColor: _textLight,
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
        borderSide: BorderSide(color: _primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _primary.withValues(alpha: 0.12),
                _primaryLight.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _primary, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _textDark,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _fieldLabelRow(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _textLight),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _textMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildSoftCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ══════════════════════════════════════════════════════
// SUB-WIDGETS
// ══════════════════════════════════════════════════════

class _AnimatedSaveButton extends StatefulWidget {
  final Color primaryColor;
  final bool isSaving;
  final VoidCallback onPressed;

  const _AnimatedSaveButton({
    required this.primaryColor,
    required this.isSaving,
    required this.onPressed,
  });

  @override
  State<_AnimatedSaveButton> createState() => _AnimatedSaveButtonState();
}

class _AnimatedSaveButtonState extends State<_AnimatedSaveButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) => setState(() => _isHovered = false),
      onTapCancel: () => setState(() => _isHovered = false),
      onTap: widget.isSaving ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              widget.isSaving
                  ? widget.primaryColor.withValues(alpha: 0.6)
                  : (_isHovered
                      ? widget.primaryColor.withValues(alpha: 0.85)
                      : widget.primaryColor),
          borderRadius: BorderRadius.circular(12),
          boxShadow:
              _isHovered
                  ? [
                    BoxShadow(
                      color: widget.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child:
            widget.isSaving
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
                    const Icon(Icons.add, size: 18, color: Colors.white),
                    const SizedBox(width: 4),
                    const Text(
                      "Tạo",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

class _DeadlineTypeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color primaryColor;

  const _DeadlineTypeOption({
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
          color:
              isSelected
                  ? primaryColor.withValues(alpha: 0.1)
                  : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
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
            const SizedBox(width: 8),
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

class _DatePickerButton extends StatelessWidget {
  final DateTime? selectedDate;
  final Color primaryColor;
  final ValueChanged<DateTime> onPicked;

  const _DatePickerButton({
    required this.selectedDate,
    required this.primaryColor,
    required this.onPicked,
  });

  String _format(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate:
              selectedDate ?? DateTime.now().add(const Duration(days: 30)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder:
              (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: primaryColor,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: const Color(0xFF0F172A),
                  ),
                ),
                child: child!,
              ),
        );
        if (picked != null) onPicked(picked);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                selectedDate != null
                    ? primaryColor.withValues(alpha: 0.5)
                    : const Color(0xFFE8ECF4),
            width: selectedDate != null ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color:
                  selectedDate != null ? primaryColor : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedDate != null
                    ? _format(selectedDate!)
                    : 'Chọn ngày deadline',
                style: TextStyle(
                  fontSize: 15,
                  color:
                      selectedDate != null
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF94A3B8),
                  fontWeight:
                      selectedDate != null
                          ? FontWeight.w500
                          : FontWeight.normal,
                ),
              ),
            ),
            if (selectedDate != null)
              GestureDetector(
                onTap: () => onPicked(DateTime(1900)),
                child: Icon(Icons.clear, size: 18, color: Colors.grey[400]),
              ),
          ],
        ),
      ),
    );
  }
}
