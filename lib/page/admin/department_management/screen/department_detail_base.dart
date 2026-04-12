import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:smet/model/department_model.dart';
import 'package:smet/service/admin/department_management/api_department_management.dart';
import 'package:smet/page/admin/department_management/widgets/shell/department_info_header.dart';
import 'package:smet/page/admin/department_management/widgets/department_courses_tab.dart';
import 'package:smet/page/admin/department_management/widgets/department_members_tab.dart';
import 'package:smet/page/admin/department_management/widgets/department_settings_tab.dart';
import 'package:smet/page/admin/department_management/widgets/department_projects_tab.dart';

class DepartmentDetailPage extends StatefulWidget {
  final int departmentId;

  const DepartmentDetailPage({super.key, required this.departmentId});

  @override
  State<DepartmentDetailPage> createState() => _DepartmentDetailPageState();
}

class _DepartmentDetailPageState extends State<DepartmentDetailPage>
    with SingleTickerProviderStateMixin {
  final DepartmentService _departmentService = DepartmentService();
  DepartmentModel? _department;
  bool _isLoading = true;
  String? _error;
  int _selectedTabIndex = 0;
  int _membersTabRefreshKey = 0;

  final Color _primaryColor = const Color(0xFF6366F1);
  final Color _bgLight = const Color(0xFFF3F6FC);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dept = await _departmentService.getDepartmentById(widget.departmentId);
      setState(() {
        _department = dept;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải thông tin phòng ban';
        _isLoading = false;
      });
    }
  }

  Future<void> _afterSettingsSaved() async {
    await _loadData();
    if (mounted) {
      setState(() => _membersTabRefreshKey++);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Trang quản trị chỉ hỗ trợ trên Web",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return ColoredBox(
      color: _bgLight,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6366F1)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Colors.red[600])),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_department == null) {
      return const Center(child: Text('Không tìm thấy phòng ban'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        return isWide ? _buildWebLayout() : _buildMobileLayout();
      },
    );
  }

  Widget _buildWebLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 320,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DepartmentInfoHeader(
                  department: _department!,
                  primaryColor: _primaryColor,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTabBar(),
                const SizedBox(height: 20),
                Expanded(child: _buildTabContent()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DepartmentInfoHeader(
            department: _department!,
            primaryColor: _primaryColor,
          ),
          const SizedBox(height: 20),
          _buildTabBar(),
          const SizedBox(height: 16),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = [
      ('Khóa học', Icons.school_outlined, 0),
      ('Nhân viên', Icons.people_outlined, 1),
      ('Dự án', Icons.work_outline, 2),
      ('Quản lý', Icons.settings_outlined, 3),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: tabs.map((tab) {
          final (label, icon, idx) = tab;
          return Expanded(
            child: _TabButton(
              label: label,
              icon: icon,
              isSelected: _selectedTabIndex == idx,
              primaryColor: _primaryColor,
              onTap: () => setState(() => _selectedTabIndex = idx),
              showBorder: _selectedTabIndex == idx,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _selectedTabIndex == 0
          ? DepartmentCoursesTab(
              key: const ValueKey('courses'),
              departmentId: widget.departmentId,
              primaryColor: _primaryColor,
            )
          : _selectedTabIndex == 1
              ? DepartmentMembersTab(
                  key: ValueKey(
                    'members_${widget.departmentId}_$_membersTabRefreshKey',
                  ),
                  departmentId: widget.departmentId,
                  primaryColor: _primaryColor,
                )
              : _selectedTabIndex == 2
                  ? DepartmentProjectsTab(
                      key: ValueKey('projects_${widget.departmentId}'),
                      departmentId: widget.departmentId,
                      primaryColor: _primaryColor,
                    )
                  : DepartmentSettingsTab(
                      key: const ValueKey('settings'),
                      departmentId: widget.departmentId,
                      primaryColor: _primaryColor,
                      onSaved: _afterSettingsSaved,
                    ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color primaryColor;
  final VoidCallback onTap;
  final bool showBorder;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.primaryColor,
    required this.onTap,
    required this.showBorder,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: showBorder
              ? Border(bottom: BorderSide(color: primaryColor, width: 2))
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? primaryColor : Colors.grey[400],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? primaryColor : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
