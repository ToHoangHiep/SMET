import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/model/department_model.dart';
import 'package:smet/service/admin/department_management/api_department_management.dart';
import 'package:smet/service/common/auth_service.dart';
import 'package:smet/service/mentor/course_service.dart';
import 'package:smet/service/common/global_notification_service.dart';

import 'dart:developer';

/// Mentor Create Course - Web Layout
class MentorCreateCourseWeb extends StatefulWidget {
  const MentorCreateCourseWeb({super.key});

  @override
  State<MentorCreateCourseWeb> createState() => _MentorCreateCourseWebState();
}

class _MentorCreateCourseWebState extends State<MentorCreateCourseWeb>
    with SingleTickerProviderStateMixin {
  // Align with app's consistent primary color (0xFF6366F1 indigo)
  static const _primary = Color(0xFF6366F1);
  static const _bgLight = Color(0xFFF3F6FC);
  static const _cardBorder = Color(0xFFE8ECF4);
  static const _textDark = Color(0xFF0F172A);
  static const _textMedium = Color(0xFF64748B);
  static const _textLight = Color(0xFF94A3B8);

  final MentorCourseService _courseService = MentorCourseService();
  final DepartmentService _departmentService = DepartmentService();

  late TabController _tabController;
  bool _isSaving = false;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<DepartmentModel> _departments = [];  // kept for future use (e.g. filtering)
  DepartmentModel? _selectedDepartment;
  bool _loadingDepartments = false;

  DeadlineType _deadlineType = DeadlineType.RELATIVE;
  int _defaultDeadlineDays = 20;
  DateTime? _fixedDeadline;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDepartments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
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
        log("Auto-selected department from auth/me: id=$userDeptId, name=$userDeptName");
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
      String? fixedDeadlineStr;
      if (_deadlineType == DeadlineType.FIXED && _fixedDeadline != null) {
        fixedDeadlineStr = _fixedDeadline!.toIso8601String();
      }

      final request = CreateCourseRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        deadlineType: _deadlineType.name,
        defaultDeadlineDays: _deadlineType == DeadlineType.RELATIVE
            ? _defaultDeadlineDays
            : null,
        fixedDeadline: fixedDeadlineStr,
      );

      log("Creating course: title=${request.title}, deadlineType=${request.deadlineType}");

      await _courseService.createCourse(request);

      if (mounted) {
        GlobalNotificationService.show(
          context: context,
          message: 'Tạo khóa học thành công!',
          type: NotificationType.success,
        );
        context.go('/mentor/courses?refresh=${DateTime.now().millisecondsSinceEpoch}');
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

  InputDecoration _field(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Padding(
        padding: const EdgeInsets.only(left: 12, right: 8),
        child: Icon(icon, color: _textLight, size: 20),
      ) : null,
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
              children: [
                _buildInfoTab(),
                _buildStructureTab(),
              ],
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
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
                  borderRadius: BorderRadius.circular(16),
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
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                        letterSpacing: -0.3,
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
          child: const Text("Hủy", style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveCourse,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.add_circle_outline, size: 18),
          label: const Text(
            "Tạo khóa học",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
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
                  TextField(
                    controller: _titleController,
                    decoration: _field("Tên khóa học *", icon: Icons.school_outlined),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _descriptionController,
                    decoration: _field("Mô tả khóa học", icon: Icons.description_outlined),
                    maxLines: 5,
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
                  _fieldLabel("Phòng ban", Icons.business_outlined),
                  const SizedBox(height: 10),
                  if (_loadingDepartments)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _cardBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.business, color: _textLight, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedDepartment?.name ?? "Đang xác định phòng ban...",
                              style: TextStyle(
                                fontSize: 15,
                                color: _selectedDepartment != null ? _textDark : _textMedium,
                                fontWeight: _selectedDepartment != null ? FontWeight.w500 : FontWeight.normal,
                              ),
                            ),
                          ),
                          Icon(Icons.lock_outline, size: 16, color: _textLight),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),
                  _dividerGradient(),
                  const SizedBox(height: 24),

                  // Deadline type
                  _fieldLabel("Kiểu deadline", Icons.schedule_outlined),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<DeadlineType>(
                    value: _deadlineType,
                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 8),
                        child: Icon(Icons.schedule, color: _textLight, size: 20),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: DeadlineType.values.map((t) {
                      return DropdownMenuItem(value: t, child: Text(t.label));
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _deadlineType = value ?? DeadlineType.RELATIVE);
                    },
                  ),

                  const SizedBox(height: 20),
                  if (_deadlineType == DeadlineType.RELATIVE) ...[
                    _fieldLabel("Số ngày deadline (sau khi đăng ký)", Icons.timer_outlined),
                    const SizedBox(height: 10),
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
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                            controller: TextEditingController(text: '$_defaultDeadlineDays'),
                            onChanged: (v) {
                              final parsed = int.tryParse(v);
                              if (parsed != null && parsed > 0) {
                                setState(() => _defaultDeadlineDays = parsed);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "ngày",
                          style: TextStyle(fontSize: 14, color: _textMedium),
                        ),
                      ],
                    ),
                  ] else ...[
                    _fieldLabel("Ngày deadline cố định", Icons.calendar_today_outlined),
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

  Widget _buildSoftCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _textDark,
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
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _textMedium),
        ),
      ],
    );
  }

  Widget _dividerGradient() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            _cardBorder,
            Colors.transparent,
          ],
        ),
      ),
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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_tree_outlined, color: _primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    "Cấu trúc khóa học",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                ],
              ),
              _AddChapterButton(
                primaryColor: _primary,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
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
                  _primary.withValues(alpha: 0.08),
                  _primary.withValues(alpha: 0.04),
                ],
              ),
              shape: BoxShape.circle,
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
              fontWeight: FontWeight.w600,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Tạo khóa học và quay lại trang chỉnh sửa để thêm chương.",
            style: TextStyle(
              fontSize: 14,
              color: _textMedium,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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

  String _format(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 30)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: primaryColor,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: const Color(0xFF0F172A),
                ),
              ),
              child: child!,
            );
          },
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
            color: selectedDate != null ? primaryColor.withValues(alpha: 0.5) : const Color(0xFFE8ECF4),
            width: selectedDate != null ? 1.5 : 1,
          ),
          boxShadow: selectedDate != null
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
              color: selectedDate != null ? primaryColor : const Color(0xFF94A3B8),
            ),
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
                child: Icon(Icons.clear, size: 18, color: Colors.grey[400]),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddChapterButton extends StatefulWidget {
  final Color primaryColor;
  final VoidCallback onPressed;

  const _AddChapterButton({
    required this.primaryColor,
    required this.onPressed,
  });

  @override
  State<_AddChapterButton> createState() => _AddChapterButtonState();
}

class _AddChapterButtonState extends State<_AddChapterButton> {
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
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          ),
          icon: Icon(Icons.add, size: 18),
          label: const Text(
            "Thêm Chương",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
