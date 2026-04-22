import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/page/shared/widgets/rich_text_editor.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/model/department_model.dart';
import 'package:smet/service/admin/department_management/api_department_management.dart';
import 'package:smet/service/common/auth_service.dart';
import 'package:smet/service/mentor/course_service.dart';
import 'package:smet/service/common/global_notification_service.dart';

import 'dart:developer';

/// Mentor Create Course - Web Layout
/// UI mềm mại, hiện đại với Rich Text Editor.
class MentorCreateCourseWeb extends StatefulWidget {
  const MentorCreateCourseWeb({super.key});

  @override
  State<MentorCreateCourseWeb> createState() => _MentorCreateCourseWebState();
}

class _MentorCreateCourseWebState extends State<MentorCreateCourseWeb>
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
        log(
          "Auto-selected department from auth/me: id=$userDeptId, name=$userDeptName",
        );
        setState(() {
          _selectedDepartment = synthetic;
          _loadingDepartments = false;
        });
        return;
      }
    } catch (e) {
      log("Could not get current user from auth/me: $e");
    }
    setState(() {
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
      log(
        "Creating course: title=${request.title}, deadlineType=${request.deadlineType}",
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
      body: Column(
        children: [
          // PAGE HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 30, 30, 0),
            child: _buildPageHeader(),
          ),

          // TAB BAR
          Padding(
            padding: const EdgeInsets.only(top: 24, left: 30, right: 30),
            child: _buildTabBar(),
          ),

          // TAB CONTENT
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

  Widget _buildPageHeader() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _primary.withValues(alpha: 0.06),
            _primary.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SharedBreadcrumb(
            items: const [
              BreadcrumbItem(label: "Khóa học", route: "/mentor/courses"),
              BreadcrumbItem(label: "Tạo khóa học mới"),
            ],
            primaryColor: _primary,
            fontSize: 13,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.add_box_rounded, color: _primary, size: 28),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Tạo khóa học mới",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Điền thông tin cơ bản và cài đặt để tạo một khóa học mới cho học viên.",
                      style: TextStyle(
                        fontSize: 14,
                        color: _textMedium,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              _buildHeaderActions(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      children: [
        OutlinedButton(
          onPressed: () => context.go('/mentor/courses'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _textMedium,
            side: const BorderSide(color: _cardBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            backgroundColor: Colors.white,
          ),
          child: const Text(
            "Hủy",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 12),
        _AnimatedCreateButton(
          primaryColor: _primary,
          isSaving: _isSaving,
          onPressed: _saveCourse,
        ),
      ],
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
                Text("Thông tin khóa học"),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_tree_outlined, size: 18),
                SizedBox(width: 8),
                Text("Cấu trúc khóa học"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT: Main info
          Expanded(
            flex: 2,
            child: _buildSoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader("Thông tin cơ bản", Icons.book_outlined),
                  const SizedBox(height: 24),
                  _fieldLabel("Tên khóa học *", Icons.school_outlined),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: _fieldInput(
                      "Tên khóa học *",
                      icon: Icons.school_outlined,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _fieldLabelRow("Mô tả khóa học", Icons.description_outlined),
                  const SizedBox(height: 8),
                  RichTextEditorWidget(
                    controller: _quillController,
                    hintText:
                        "Nhập mô tả chi tiết về khóa học, nội dung, và mục tiêu học tập...",
                    primaryColor: _primary,
                    maxHeight: 200,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 24),

          // RIGHT: Settings
          Expanded(
            child: _buildSoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader("Cài đặt", Icons.settings_outlined),
                  const SizedBox(height: 24),

                  // Department
                  _fieldLabelRow("Phòng ban", Icons.business_outlined),
                  const SizedBox(height: 10),
                  _buildDepartmentBadge(),

                  const SizedBox(height: 24),
                  _dividerGradient(),
                  const SizedBox(height: 24),

                  // Deadline type
                  _fieldLabelRow("Kiểu deadline", Icons.schedule_outlined),
                  const SizedBox(height: 10),
                  _buildDeadlineTypeSelector(),

                  const SizedBox(height: 20),
                  if (_deadlineType == DeadlineType.RELATIVE) ...[
                    _fieldLabelRow("Số ngày deadline", Icons.timer_outlined),
                    const SizedBox(height: 10),
                    _buildDeadlineDaysField(),
                  ] else ...[
                    _fieldLabelRow(
                      "Ngày deadline cố định",
                      Icons.calendar_today_outlined,
                    ),
                    const SizedBox(height: 10),
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
          ),
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

  Widget _buildDeadlineDaysField() {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: TextField(
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Icon(Icons.numbers, size: 18, color: _textLight),
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
                borderSide: BorderSide(color: _primary, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
            ),
            controller: TextEditingController(text: '$_defaultDeadlineDays'),
            onChanged: (v) {
              final parsed = int.tryParse(v);
              if (parsed != null && parsed > 0)
                setState(() => _defaultDeadlineDays = parsed);
            },
          ),
        ),
        const SizedBox(width: 12),
        Text(
          "ngày sau khi đăng ký",
          style: TextStyle(fontSize: 14, color: _textMedium),
        ),
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _primary.withValues(alpha: 0.12),
                          _primaryLight.withValues(alpha: 0.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.account_tree_outlined,
                      color: _primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Cấu trúc khóa học",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        "Sau khi tạo khóa học, bạn có thể thêm chương và bài học.",
                        style: TextStyle(fontSize: 13, color: _textMedium),
                      ),
                    ],
                  ),
                ],
              ),
              _AnimatedAddButton(
                primaryColor: _primary,
                label: "Thêm Chương",
                icon: Icons.add,
                onPressed: () {
                  GlobalNotificationService.show(
                    context: context,
                    message: 'Tạo khóa học trước để thêm chương',
                    type: NotificationType.warning,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildEmptyStructureState(),
        ],
      ),
    );
  }

  Widget _buildEmptyStructureState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
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
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
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
              size: 44,
              color: _primary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            "Chưa có chương nào",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _textDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 380,
            child: Text(
              "Tạo khóa học và quay lại trang chỉnh sửa để xây dựng cấu trúc với các chương, bài học và bài kiểm tra.",
              style: TextStyle(fontSize: 14, color: _textMedium, height: 1.6),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          // Steps
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _cardBorder),
            ),
            child: Column(
              children: [
                _buildStepRow(
                  1,
                  "Điền thông tin khóa học",
                  Icons.info_outlined,
                  _primary,
                ),
                const SizedBox(height: 12),
                _buildStepRow(
                  2,
                  "Tạo khóa học",
                  Icons.add_circle_outline,
                  _primary,
                ),
                const SizedBox(height: 12),
                _buildStepRow(
                  3,
                  "Thêm chương và bài học",
                  Icons.bookmark_add_outlined,
                  _primaryLight,
                ),
                const SizedBox(height: 12),
                _buildStepRow(
                  4,
                  "Tạo quiz & xuất bản",
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
          width: 28,
          height: 28,
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
        const SizedBox(width: 12),
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: _textMedium,
            fontWeight: FontWeight.w500,
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
          width: 36,
          height: 36,
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
          child: Icon(icon, color: _primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _textDark,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text, IconData icon) {
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

  Widget _dividerGradient() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, _cardBorder, Colors.transparent],
        ),
      ),
    );
  }

  Widget _buildSoftCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
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

class _AnimatedCreateButton extends StatefulWidget {
  final Color primaryColor;
  final bool isSaving;
  final VoidCallback onPressed;

  const _AnimatedCreateButton({
    required this.primaryColor,
    required this.isSaving,
    required this.onPressed,
  });

  @override
  State<_AnimatedCreateButton> createState() => _AnimatedCreateButtonState();
}

class _AnimatedCreateButtonState extends State<_AnimatedCreateButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton.icon(
          onPressed: widget.isSaving ? null : widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _isHovered
                    ? widget.primaryColor.withValues(alpha: 0.85)
                    : widget.primaryColor,
            foregroundColor: Colors.white,
            elevation: _isHovered ? 4 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          icon:
              widget.isSaving
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Icon(Icons.add_circle_outline, size: 18),
          label: Text(
            "Tạo khóa học",
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      ),
    );
  }
}

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
            backgroundColor:
                _isHovered
                    ? widget.primaryColor
                    : widget.primaryColor.withValues(alpha: 0.1),
            foregroundColor: _isHovered ? Colors.white : widget.primaryColor,
            elevation: _isHovered ? 2 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          ),
          icon: Icon(widget.icon, size: 18),
          label: Text(
            widget.label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
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
        padding: const EdgeInsets.symmetric(vertical: 14),
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
          boxShadow:
              selectedDate != null
                  ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
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
                selectedDate != null ? _format(selectedDate!) : 'Chọn ngày',
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
