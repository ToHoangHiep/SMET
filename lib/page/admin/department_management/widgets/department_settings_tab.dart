import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:smet/model/user_model.dart' as user_model;
import 'package:smet/model/department_model.dart';
import 'package:smet/page/admin/department_management/widgets/dialog/user_selection_dialog.dart';
import 'package:smet/page/admin/department_management/widgets/dialog/transfer_course_dialog.dart';
import 'package:smet/page/admin/user_management/widgets/dialog/reassignment_dialog.dart';
import 'package:smet/page/shared/widgets/app_toast.dart';
import 'package:smet/service/common/global_notification_service.dart';
import 'package:smet/service/admin/department_management/api_department_management.dart';
import 'package:smet/service/common/user_selection_service.dart';

/// Tab cài đặt phòng ban: chỉnh tên, mã, PM, thành viên — dùng cùng API PATCH như form cập nhật cũ.
class DepartmentSettingsTab extends StatefulWidget {
  final int departmentId;
  final Color primaryColor;
  final VoidCallback onSaved;

  const DepartmentSettingsTab({
    super.key,
    required this.departmentId,
    required this.primaryColor,
    required this.onSaved,
  });

  @override
  State<DepartmentSettingsTab> createState() => _DepartmentSettingsTabState();
}

class _DepartmentSettingsTabState extends State<DepartmentSettingsTab> {
  final DepartmentService _departmentService = DepartmentService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _managerFallbackController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;
  String? _error;
  bool _isActive = true;
  user_model.UserModel? _selectedManager;
  final List<user_model.UserModel> _selectedEmployees = [];
  List<DepartmentModel> _departments = [];

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _managerFallbackController.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  Future<void> _loadFormData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _hasChanges = false;
    });

    try {
      // Load departments for reassignment dialog
      final deptResult = await _departmentService.searchDepartments(page: 0, size: 100);

      final department =
          await _departmentService.getDepartmentById(widget.departmentId);
      if (department == null) {
        setState(() {
          _error = 'Không tìm thấy phòng ban';
          _isLoading = false;
        });
        return;
      }

      List<user_model.UserModel> managers = [];
      try {
        managers = await fetchSelectableUsers(
          UserSelectionContext.departmentProjectManager,
        );
      } catch (e) {
        log('DepartmentSettingsTab: load managers: $e');
      }

      final match = managers
          .where((u) => u.id == department.projectManagerId)
          .toList();
      final manager = match.isEmpty ? null : match.first;

      List<Map<String, dynamic>> departmentMembers = [];
      try {
        final result = await _departmentService.getDepartmentMembers(
          departmentId: department.id,
          page: 0,
          size: 1000,
        );
        departmentMembers = (result['members'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      } catch (e) {
        log('DepartmentSettingsTab: load members: $e');
      }

      final selectedEmployees = <user_model.UserModel>[];
      for (final member in departmentMembers) {
        final role = member['role'] as String?;
        if (role != 'PROJECT_MANAGER' && role != 'ADMIN') {
          selectedEmployees.add(
            user_model.UserModel(
              id: member['id'] as int,
              userName: member['userName'] as String?,
              firstName: member['firstName'] ?? '',
              lastName: member['lastName'] as String?,
              email: member['email'] ?? '',
              phone: '',
              role: _parseRole(role ?? 'USER'),
              departmentId: member['departmentId'] as int?,
              department: member['departmentName'] as String?,
              lastUpdated: DateTime.now(),
            ),
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _departments = (deptResult['departments'] as List?)?.cast<DepartmentModel>() ?? [];
        _nameController.text = department.name;
        _codeController.text = department.code;
        _isActive = department.isActive;
        _selectedManager = manager;
        if (manager == null) {
          _managerFallbackController.text =
              department.projectManagerName ?? '';
        } else {
          _managerFallbackController.clear();
        }
        _selectedEmployees
          ..clear()
          ..addAll(selectedEmployees);
        _isLoading = false;
      });
    } catch (e) {
      log('DepartmentSettingsTab _loadFormData: $e');
      if (mounted) {
        setState(() {
          _error = 'Không thể tải dữ liệu phòng ban';
          _isLoading = false;
        });
      }
    }
  }

  user_model.UserRole _parseRole(String role) {
    switch (role) {
      case 'ADMIN':
        return user_model.UserRole.ADMIN;
      case 'PROJECT_MANAGER':
        return user_model.UserRole.PROJECT_MANAGER;
      case 'MENTOR':
        return user_model.UserRole.MENTOR;
      default:
        return user_model.UserRole.USER;
    }
  }

  Future<void> _pickManager() async {
    List<user_model.UserModel> managers;
    try {
      managers = await fetchSelectableUsers(
        UserSelectionContext.departmentProjectManager,
      );
    } catch (e) {
      if (!mounted) return;
      context.showAppToast('Lỗi lấy danh sách: $e', variant: AppToastVariant.error);
      return;
    }

    if (!mounted) return;

    final selected = await UserSelectionDialog.selectManager(
      context: context,
      primaryColor: widget.primaryColor,
      managers: managers,
      currentManager: _selectedManager,
      excludeDepartmentId: widget.departmentId,
    );

    if (selected == null) return;

    setState(() {
      _selectedManager = selected;
      _managerFallbackController.clear();
    });
    _markChanged();
  }

  Future<void> _pickEmployees() async {
    List<user_model.UserModel> availableUsers;
    try {
      availableUsers = await fetchSelectableUsers(
        UserSelectionContext.departmentMembers,
      );
    } catch (e) {
      if (!mounted) return;
      context.showAppToast('Lỗi lấy danh sách: $e', variant: AppToastVariant.error);
      return;
    }

    if (!mounted) return;

    final result = await UserSelectionDialog.selectMembers(
      context: context,
      primaryColor: widget.primaryColor,
      members: availableUsers,
      preSelectedMembers: _selectedEmployees,
      excludeDepartmentId: widget.departmentId,
    );

    if (result == null) return;

    setState(() {
      _selectedEmployees
        ..clear()
        ..addAll(result);
    });
    _markChanged();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedManager == null) {
      if (!mounted) return;
      context.showAppToast(
        'Vui lòng chọn người quản lý',
        variant: AppToastVariant.info,
      );
      return;
    }

    setState(() => _isSaving = true);

    final pmId = _selectedManager!.id;
    final mentorList = _selectedEmployees
        .where((e) => e.role.name == 'MENTOR')
        .map((e) => e.id)
        .toList();
    final userList = _selectedEmployees
        .where((e) => e.role.name == 'USER')
        .map((e) => e.id)
        .toList();

    final updated = await _departmentService.updateDepartment(
      id: widget.departmentId,
      name: _nameController.text.trim(),
      code: _codeController.text.trim(),
      isActive: _isActive,
      projectManagerId: pmId,
      mentorIds: mentorList.isNotEmpty ? mentorList : null,
      userIds: userList.isNotEmpty ? userList : null,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (updated == null) {
      context.showAppToast(
        'Cập nhật thất bại',
        variant: AppToastVariant.error,
      );
      return;
    }

    context.showAppToast(
      'Đã cập nhật phòng ban thành công',
      variant: AppToastVariant.success,
    );
    widget.onSaved();
    await _loadFormData();
  }

  void _resetChanges() {
    _loadFormData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(0, 48, 24, 24),
        child: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Colors.red[600])),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadFormData,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 0, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(),
            const SizedBox(height: 20),
            _buildBasicInfoSection(),
            const SizedBox(height: 16),
            _buildManagerSection(),
            const SizedBox(height: 16),
            _buildStatusSection(),
            const SizedBox(height: 16),
            _buildTeamSection(),
            const SizedBox(height: 28),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.settings_outlined,
            color: widget.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cài đặt phòng ban',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Cập nhật thông tin, quản lý nhân sự và trạng thái phòng ban',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        if (_hasChanges)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, size: 14, color: Colors.orange.shade600),
                const SizedBox(width: 6),
                Text(
                  'Có thay đổi',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF2F7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, {String? subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: widget.primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Thông tin cơ bản', Icons.business_outlined,
              subtitle: 'Tên và mã định danh phòng ban'),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildNameField()),
              const SizedBox(width: 16),
              Expanded(child: _buildCodeField()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tên phòng ban',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          onChanged: (_) => _markChanged(),
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'VD: Phòng Kỹ thuật',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: const Color(0xFFFAFBFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
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
              borderSide: BorderSide(color: widget.primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Không được để trống';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mã phòng ban',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _codeController,
          onChanged: (_) => _markChanged(),
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'VD: DEV, QA, HR',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: const Color(0xFFFAFBFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
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
              borderSide: BorderSide(color: widget.primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Không được để trống';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildManagerSection() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Người quản lý', Icons.person_pin_outlined,
              subtitle: 'Người phụ trách quản lý phòng ban này'),
          const SizedBox(height: 16),
          _buildManagerPicker(),
        ],
      ),
    );
  }

  Widget _buildManagerPicker() {
    final hasManager = _selectedManager != null ||
        _managerFallbackController.text.isNotEmpty;
    final displayText = _selectedManager != null
        ? _selectedManager!.fullName
        : _managerFallbackController.text.isNotEmpty
            ? _managerFallbackController.text
            : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _pickManager,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: hasManager
                ? widget.primaryColor.withValues(alpha: 0.04)
                : const Color(0xFFFAFBFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasManager
                  ? widget.primaryColor.withValues(alpha: 0.35)
                  : const Color(0xFFE5E7EB),
              width: hasManager ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              _buildManagerAvatar(hasManager),
              const SizedBox(width: 14),
              Expanded(
                child: _buildManagerInfo(displayText),
              ),
              _buildManagerAction(hasManager),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManagerAvatar(bool hasManager) {
    if (_selectedManager != null) {
      final color = const Color(0xFF10B981);
      final initials = '${_selectedManager!.firstName.isNotEmpty ? _selectedManager!.firstName[0] : ''}'
          '${(_selectedManager!.lastName ?? '').isNotEmpty ? _selectedManager!.lastName![0] : ''}';
      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            initials.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person_add_outlined,
        color: Colors.grey[400],
        size: 22,
      ),
    );
  }

  Widget _buildManagerInfo(String? displayText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          displayText ?? 'Chọn người quản lý',
          style: TextStyle(
            fontSize: 14,
            fontWeight: hasManager ? FontWeight.w600 : FontWeight.w400,
            color: hasManager ? const Color(0xFF0F172A) : Colors.grey[400],
          ),
        ),
        if (displayText != null && _selectedManager != null) ...[
          const SizedBox(height: 3),
          Row(
            children: [
              _buildRoleBadge(_selectedManager!.role.displayName),
              if (_selectedManager!.department != null) ...[
                const SizedBox(width: 6),
                Text(
                  _selectedManager!.department!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ],
          ),
        ] else ...[
          const SizedBox(height: 2),
          Text(
            'Nhấn để chọn PM quản lý phòng ban',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildManagerAction(bool hasManager) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: hasManager
            ? widget.primaryColor.withValues(alpha: 0.08)
            : widget.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasManager
              ? widget.primaryColor.withValues(alpha: 0.2)
              : widget.primaryColor.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasManager ? Icons.edit_outlined : Icons.add_outlined,
            size: 15,
            color: widget.primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            hasManager ? 'Đổi' : 'Chọn',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  bool get hasManager =>
      _selectedManager != null || _managerFallbackController.text.isNotEmpty;

  Widget _buildStatusSection() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Trạng thái hoạt động', Icons.toggle_on_outlined,
              subtitle: 'Bật/tắt trạng thái phòng ban'),
          const SizedBox(height: 16),
          _buildStatusToggle(),
        ],
      ),
    );
  }

  Widget _buildStatusToggle() {
    return Row(
      children: [
        Expanded(
          child: _buildStatusOption(
            value: true,
            icon: Icons.check_circle_outline,
            label: 'Hoạt động',
            description: 'Phòng ban đang được sử dụng',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusOption(
            value: false,
            icon: Icons.pause_circle_outline,
            label: 'Không hoạt động',
            description: 'Phòng ban tạm ngưng',
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusOption({
    required bool value,
    required IconData icon,
    required String label,
    required String description,
    required Color color,
  }) {
    final isSelected = _isActive == value;
    return InkWell(
      onTap: () {
        setState(() => _isActive = value);
        _markChanged();
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.4) : const Color(0xFFE5E7EB),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? color : Colors.grey[300],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : const Color(0xFF6B7280),
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check, size: 18, color: color),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? color.withValues(alpha: 0.7) : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSection() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildSectionTitle(
                  'Thành viên & Mentor',
                  Icons.group_outlined,
                  subtitle: 'Nhân viên và mentor thuộc phòng ban',
                ),
              ),
              const SizedBox(width: 12),
              _MemberAddButton(
                primaryColor: widget.primaryColor,
                onTap: _pickEmployees,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_selectedEmployees.isEmpty)
            _buildEmptyTeam()
          else
            _buildTeamGrid(),
        ],
      ),
    );
  }

  Widget _buildEmptyTeam() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.group_add_outlined,
              size: 28,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Chưa có thành viên nào',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Nhấn "Thêm" để bổ sung nhân viên và mentor',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _selectedEmployees.map((e) => _buildMemberChip(e)).toList(),
    );
  }

  Widget _buildMemberChip(user_model.UserModel member) {
    final isMentor = member.role.name == 'MENTOR';
    final color = isMentor ? const Color(0xFF7C3AED) : const Color(0xFF10B981);
    final bgColor = isMentor ? const Color(0xFFF5F3FF) : const Color(0xFFECFDF5);
    final borderColor = isMentor ? const Color(0xFFDDD6FE) : const Color(0xFFA7F3D0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isMentor) {
            _showChangeMentorDepartmentDialog(member);
          } else {
            setState(() {
              _selectedEmployees.removeWhere((e) => e.id == member.id);
            });
            _markChanged();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.only(left: 10, right: 6, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MemberAvatarChip(
                member: member,
                color: color,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    member.fullName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  _buildRoleBadge(member.role.displayName),
                ],
              ),
              const SizedBox(width: 4),
              if (isMentor)
                Tooltip(
                  message: 'Chuyển phòng ban',
                  child: InkWell(
                    onTap: () => _showChangeMentorDepartmentDialog(member),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.swap_horiz,
                        size: 16,
                        color: Colors.purple[300],
                      ),
                    ),
                  ),
                ),
              Tooltip(
                message: 'Xóa khỏi phòng ban',
                child: InkWell(
                  onTap: () async {
                    await TransferCourseDialog.show(
                      context: context,
                      mentor: member,
                      departmentId: widget.departmentId,
                      primaryColor: widget.primaryColor,
                      onComplete: () {
                        setState(() {
                          _selectedEmployees.removeWhere((e) => e.id == member.id);
                        });
                        _markChanged();
                      },
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showChangeMentorDepartmentDialog(user_model.UserModel mentor) async {
    await ReassignmentDialog.show(
      context: context,
      mentor: mentor,
      departments: _departments.where((d) => d.id != widget.departmentId).toList(),
      primaryColor: widget.primaryColor,
      onComplete: () async {
        await _loadFormData();
        if (context.mounted) {
          GlobalNotificationService.show(
            context: context,
            message: 'Chuyển phòng ban thành công!',
            type: NotificationType.success,
          );
        }
      },
    );
  }

  Widget _buildRoleBadge(String role) {
    final isMentor = role.toUpperCase() == 'MENTOR';
    final color = isMentor ? const Color(0xFF7C3AED) : const Color(0xFF10B981);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF2F7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_hasChanges) ...[
            Text(
              'Bạn có thay đổi chưa lưu',
              style: TextStyle(
                fontSize: 13,
                color: Colors.orange.shade600,
              ),
            ),
            const Spacer(),
          ] else ...[
            const Spacer(),
          ],
          OutlinedButton(
            onPressed: _hasChanges ? _resetChanges : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[600],
              disabledForegroundColor: Colors.grey[300],
              side: BorderSide(
                color: _hasChanges ? const Color(0xFFE5E7EB) : Colors.grey.shade200,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Đặt lại'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: (_isSaving || !_hasChanges) ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: widget.primaryColor.withValues(alpha: 0.3),
              disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Lưu thay đổi',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MemberAddButton extends StatefulWidget {
  final Color primaryColor;
  final VoidCallback onTap;

  const _MemberAddButton({
    required this.primaryColor,
    required this.onTap,
  });

  @override
  State<_MemberAddButton> createState() => _MemberAddButtonState();
}

class _MemberAddButtonState extends State<_MemberAddButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _isHovered
                    ? widget.primaryColor.withValues(alpha: 0.08)
                    : widget.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isHovered
                      ? widget.primaryColor.withValues(alpha: 0.4)
                      : widget.primaryColor.withValues(alpha: 0.25),
                  width: _isHovered ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_add_outlined,
                    size: 16,
                    color: widget.primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Thêm',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.primaryColor,
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

class _MemberAvatarChip extends StatelessWidget {
  final user_model.UserModel member;
  final Color color;

  const _MemberAvatarChip({
    required this.member,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isMentor = member.role.name == 'MENTOR';
    final initials = '${member.firstName.isNotEmpty ? member.firstName[0] : ''}'
        '${(member.lastName ?? '').isNotEmpty ? member.lastName![0] : ''}';

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: isMentor
            ? Icon(Icons.school, size: 15, color: color)
            : Text(
                initials.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
