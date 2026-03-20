import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  final MentorCourseService _courseService = MentorCourseService();
  final DepartmentService _departmentService = DepartmentService();

  late TabController _tabController;
  bool _isSaving = false;

  // Form fields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Department selector
  List<DepartmentModel> _departments = [];
  DepartmentModel? _selectedDepartment;
  bool _loadingDepartments = false;

  // Deadline config
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

    // Load departments list — separate try-catch so auth failure doesn't block form
    List<DepartmentModel> departments = [];
    try {
      final result = await _departmentService.searchDepartments(page: 0, size: 100);
      departments = result['departments'] as List<DepartmentModel>;
    } catch (e) {
      log("Load departments failed: $e");
    }

    // Get current user's department from auth/me
    // Department info is in auth/me response itself — use it even if departments list fails
    try {
      final userData = await AuthService.getMe();
      // auth/me already contains departmentId + departmentName + departmentCode
      final userDeptId = userData['departmentId'] as int?;
      final userDeptName = userData['departmentName'] as String?;

      if (userDeptId != null && userDeptName != null) {
        log("auth/me department: id=$userDeptId, name=$userDeptName");

        // Try to match from loaded departments list first
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

        // If departments list didn't load, create a synthetic department from auth/me
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

      log("Creating course with: title=${request.title}, departmentId=${request.departmentId?.value}, deadlineType=${request.deadlineType}");

      final created = await _courseService.createCourse(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tạo khóa học thành công!"), backgroundColor: Colors.green),
        );
        context.go('/mentor/courses/${created.id.value}?title=${Uri.encodeComponent(created.title)}');
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
        const Flexible(
          child: Text(
            "Tạo khóa học mới",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
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
      body: Column(
        children: [
          /// BREADCRUMB
          Padding(
            padding: const EdgeInsets.only(top: 30, left: 30, right: 30),
            child: Row(
              children: [
                Expanded(child: _buildBreadcrumb()),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () => context.go('/mentor/courses'),
                  child: const Text("Hủy"),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveCourse,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: const Text("Tạo khóa học"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff1a90ff),
                    foregroundColor: Colors.white,
                  ),
                ),
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
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          /// LEFT + RIGHT column layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// LEFT: Main info
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Thông tin cơ bản",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      /// TITLE
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: "Tên khóa học *",
                          hintText: "Nhập tên khóa học",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      /// DESCRIPTION
                      TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: "Mô tả",
                          hintText: "Mô tả nội dung khóa học",
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 5,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 20),

              /// RIGHT: Settings
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Cài đặt",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      /// DEPARTMENT
                      const Text(
                        "Phòng ban",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      if (_loadingDepartments)
                        const Center(child: CircularProgressIndicator())
                      else
                        DropdownButtonFormField<DepartmentModel>(
                          value: _selectedDepartment,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          hint: const Text("Chọn phòng ban (không bắt buộc)"),
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
                      const Divider(),
                      const SizedBox(height: 12),

                      /// DEADLINE TYPE
                      const Text(
                        "Kiểu deadline",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<DeadlineType>(
                        value: _deadlineType,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: DeadlineType.values.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Text(t.label),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _deadlineType = value ?? DeadlineType.RELATIVE);
                        },
                      ),

                      /// DEADLINE VALUE (conditional)
                      const SizedBox(height: 16),
                      if (_deadlineType == DeadlineType.RELATIVE) ...[
                        const Text(
                          "Số ngày deadline (sau khi đăng ký)",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
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
                                controller: TextEditingController(text: '$_defaultDeadlineDays'),
                                onChanged: (v) {
                                  final parsed = int.tryParse(v);
                                  if (parsed != null && parsed > 0) {
                                    setState(() => _defaultDeadlineDays = parsed);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text("ngày"),
                          ],
                        ),
                      ] else ...[
                        const Text(
                          "Ngày deadline cố định",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _fixedDeadline ?? DateTime.now().add(const Duration(days: 30)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() => _fixedDeadline = picked);
                            }
                          },
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(
                            _fixedDeadline != null
                                ? '${_fixedDeadline!.day}/${_fixedDeadline!.month}/${_fixedDeadline!.year}'
                                : 'Chọn ngày',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
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
              const Text(
                "Cấu trúc khóa học",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Tạo khóa học trước để thêm chương")),
                  );
                },
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
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.library_books_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text(
                    "Chưa có chương nào",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tạo khóa học và quay lại trang chỉnh sửa để thêm chương.",
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
