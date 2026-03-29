import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/model/department_model.dart';
import 'package:smet/service/admin/department_management/api_department_management.dart';
import 'package:smet/service/common/auth_service.dart';
import 'package:smet/service/mentor/course_service.dart';

import 'dart:developer';

/// Mentor Create Course - Web Layout
class MentorCreateCourseWeb extends StatefulWidget {
  const MentorCreateCourseWeb({super.key});

  @override
  State<MentorCreateCourseWeb> createState() => _MentorCreateCourseWebState();
}

class _MentorCreateCourseWebState extends State<MentorCreateCourseWeb>
    with SingleTickerProviderStateMixin {
  static const _primary = Color(0xFF137FEC);

  final MentorCourseService _courseService = MentorCourseService();
  final DepartmentService _departmentService = DepartmentService();

  late TabController _tabController;
  bool _isSaving = false;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

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

    List<DepartmentModel> departments = [];
    try {
      final result = await _departmentService.searchDepartments(page: 0, size: 100);
      departments = result['departments'] as List<DepartmentModel>;
    } catch (e) {
      log("Load departments failed: $e");
    }

    try {
      final userData = await AuthService.getMe();
      final userDeptId = userData['departmentId'] as int?;
      final userDeptName = userData['departmentName'] as String?;

      if (userDeptId != null && userDeptName != null) {
        log("auth/me department: id=$userDeptId, name=$userDeptName");

        DepartmentModel? currentDept;
        if (departments.isNotEmpty) {
          currentDept = departments.cast<DepartmentModel?>().firstWhere(
            (d) => d?.id == userDeptId,
            orElse: () => null,
          );
        }

        if (currentDept != null) {
          log("Auto-selected department from list: ${currentDept.name}");
          setState(() {
            _departments = departments;
            _selectedDepartment = currentDept;
            _loadingDepartments = false;
          });
          return;
        }

        final synthetic = DepartmentModel(
          id: userDeptId,
          name: userDeptName,
          code: userData['departmentCode']?.toString() ?? '',
          isActive: true,
        );
        log("Using department from auth/me (list not accessible): id=$userDeptId, name=$userDeptName");
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
      _departments = departments;
      _selectedDepartment = null;
      _loadingDepartments = false;
    });
  }

  Future<void> _saveCourse() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập tên khóa học")),
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
        departmentId: _selectedDepartment != null
            ? Long(_selectedDepartment!.id)
            : null,
        deadlineType: _deadlineType.name,
        defaultDeadlineDays: _deadlineType == DeadlineType.RELATIVE
            ? _defaultDeadlineDays
            : null,
        fixedDeadline: fixedDeadlineStr,
      );

      log("Creating course: title=${request.title}, departmentId=${request.departmentId?.value}, deadlineType=${request.deadlineType}");

      await _courseService.createCourse(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Tạo khóa học thành công!"),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
        context.go('/mentor/courses?refresh=${DateTime.now().millisecondsSinceEpoch}');
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: $e"), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  InputDecoration _field(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF94A3B8), size: 20) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _primary, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      body: Column(
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 30, 30, 0),
            child: BreadcrumbPageHeader(
              pageTitle: "Tạo khóa học mới",
              pageIcon: Icons.add_box_rounded,
              breadcrumbs: const [
                BreadcrumbItem(label: "Khóa học", route: "/mentor/courses"),
                BreadcrumbItem(label: "Tạo khóa học mới"),
              ],
              primaryColor: _primary,
              actions: [
                OutlinedButton(
                  onPressed: () => context.go('/mentor/courses'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text("Hủy"),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveCourse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save, size: 18),
                  label: const Text(
                    "Tạo khóa học",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

          // TAB BAR
          Padding(
            padding: const EdgeInsets.only(top: 20, left: 30, right: 30),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF64748B),
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
                        SizedBox(width: 6),
                        Text("Thông tin khóa học"),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_tree_outlined, size: 18),
                        SizedBox(width: 6),
                        Text("Cấu trúc khóa học"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT: Main info
          Expanded(
            flex: 2,
            child: _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader("Thông tin cơ bản", Icons.book_outlined),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _titleController,
                    decoration: _field("Tên khóa học *", icon: Icons.school_outlined),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: _field("Mô tả khóa học", icon: Icons.description_outlined),
                    maxLines: 5,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 20),

          // RIGHT: Settings
          Expanded(
            child: _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader("Cài đặt", Icons.settings_outlined),
                  const SizedBox(height: 20),

                  // Department
                  _fieldLabel("Phòng ban", Icons.business_outlined),
                  const SizedBox(height: 8),
                  if (_loadingDepartments)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
                        ),
                      ),
                    )
                  else
                    DropdownButtonFormField<DepartmentModel>(
                      value: _selectedDepartment,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: Color(0xFFFAFAFA),
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<DepartmentModel>(
                          value: null,
                          child: Text("Không chọn phòng ban"),
                        ),
                        ..._departments.map((d) => DropdownMenuItem(
                          value: d,
                          child: Text(d.name, overflow: TextOverflow.ellipsis),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedDepartment = value);
                      },
                    ),

                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFE5E7EB), thickness: 1),
                  const SizedBox(height: 16),

                  // Deadline type
                  _fieldLabel("Kiểu deadline", Icons.schedule_outlined),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<DeadlineType>(
                    value: _deadlineType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      filled: true,
                      fillColor: Color(0xFFFAFAFA),
                    ),
                    items: DeadlineType.values.map((t) {
                      return DropdownMenuItem(value: t, child: Text(t.label));
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _deadlineType = value ?? DeadlineType.RELATIVE);
                    },
                  ),

                  const SizedBox(height: 16),
                  if (_deadlineType == DeadlineType.RELATIVE) ...[
                    _fieldLabel("Số ngày deadline (sau khi đăng ký)", Icons.numbers),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SizedBox(
                          width: 90,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.numbers, size: 18, color: Color(0xFF94A3B8)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: _primary, width: 2),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFFAFAFA),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                        const Text(
                          "ngày",
                          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ] else ...[
                    _fieldLabel("Ngày deadline cố định", Icons.calendar_today),
                    const SizedBox(height: 8),
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

  Widget _fieldLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
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
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_tree_outlined, color: _primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Cấu trúc khóa học",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Tạo khóa học trước để thêm chương"),
                      backgroundColor: Color(0xFFF59E0B),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  "Thêm Chương",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.library_books_outlined,
                    size: 36,
                    color: Color(0xFFCBD5E1),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Chưa có chương nào",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Tạo khóa học và quay lại trang chỉnh sửa để thêm chương.",
                  style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selectedDate != null ? primaryColor : const Color(0xFFE5E7EB),
            width: selectedDate != null ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
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
                child: const Icon(Icons.clear, size: 18, color: Color(0xFF94A3B8)),
              ),
          ],
        ),
      ),
    );
  }
}
