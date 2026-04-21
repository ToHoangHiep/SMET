import 'package:flutter/material.dart';
import 'package:smet/model/department_model.dart';
import 'package:smet/service/admin/department_management/api_department_management.dart';
import 'package:smet/page/admin/department_management/widgets/dialog/change_member_department_dialog.dart';
import 'dart:developer';

class DepartmentMembersTab extends StatefulWidget {
  final int departmentId;
  final Color primaryColor;
  final List<DepartmentModel>? allDepartments;
  final VoidCallback? onRefresh;

  const DepartmentMembersTab({
    super.key,
    required this.departmentId,
    required this.primaryColor,
    this.allDepartments,
    this.onRefresh,
  });

  @override
  State<DepartmentMembersTab> createState() => _DepartmentMembersTabState();
}

class _DepartmentMembersTabState extends State<DepartmentMembersTab> {
  final DepartmentService _service = DepartmentService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _members = [];
  bool _isLoading = false;
  String? _error;

  String _searchQuery = '';
  String? _selectedRole;
  int _totalElements = 0;

  List<DepartmentModel> _allDepartments = [];

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _loadAllDepartments();
  }

  Future<void> _loadAllDepartments() async {
    try {
      final result = await _service.searchDepartments(page: 0, size: 100);
      if (mounted) {
        setState(() {
          _allDepartments = result['departments'] as List<DepartmentModel>? ?? [];
        });
      }
    } catch (e) {
      log("LOAD ALL DEPARTMENTS ERROR: $e");
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _service.getDepartmentMembers(
        departmentId: widget.departmentId,
      );

      final members = result['members'] as List<dynamic>? ?? [];
      final totalElements = result['totalElements'] as int? ?? 0;

      log("Loaded ${members.length} members for department ${widget.departmentId}, total: $totalElements");

      if (mounted) {
        setState(() {
          _members = members.cast<Map<String, dynamic>>();
          _isLoading = false;
          _totalElements = totalElements;
        });
      }
    } catch (e) {
      log("LOAD MEMBERS ERROR: $e");
      if (mounted) {
        setState(() {
          _error = 'Không thể tải danh sách nhân viên';
          _isLoading = false;
        });
      }
    }
  }

  void _onSearch(String value) {
    setState(() => _searchQuery = value);
    _loadMembers();
  }

  void _onRoleFilterChanged(String? role) {
    setState(() => _selectedRole = role);
    _loadMembers();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoading();
    }

    if (_error != null) {
      return _buildError();
    }

    return _buildMembersLayout();
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(0, 24, 24, 24),
      child: Align(
        alignment: Alignment.centerLeft,
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(color: Colors.red[600]),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _loadMembers(),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredMembers {
    return _members.where((m) {
      final query = _searchQuery.toLowerCase();
      if (query.isNotEmpty) {
        final name = '${m['firstName'] ?? ''} ${m['lastName'] ?? ''} ${m['userName'] ?? ''} ${m['email'] ?? ''}'.toLowerCase();
        if (!name.contains(query)) return false;
      }
      if (_selectedRole != null) {
        final role = (m['role'] ?? m['roleName'] ?? '').toString().toUpperCase();
        if (role != _selectedRole) return false;
      }
      return true;
    }).toList();
  }

  Widget _buildMembersLayout() {
    final filtered = _filteredMembers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryRow(),
        const SizedBox(height: 16),
        _buildSearchAndFilter(),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          _buildEmpty()
        else
          Expanded(
            child: _buildMembersListWith(filtered),
          ),
      ],
    );
  }

  Widget _buildMembersListWith(List<Map<String, dynamic>> members) {
    return ListView.separated(
      itemCount: members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final member = members[index];
        return _MemberCard(
          member: member,
          primaryColor: widget.primaryColor,
          allDepartments: _allDepartments,
          currentDepartmentId: widget.departmentId,
          onDepartmentChanged: () {
            _loadMembers();
            widget.onRefresh?.call();
          },
        );
      },
    );
  }

  Widget _buildSummaryRow() {
    final roleCounts = <String, int>{};
    for (final member in _filteredMembers) {
      final role = _normalizeRole(member['role'] ?? member['roleName'] ?? '');
      roleCounts[role] = (roleCounts[role] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: widget.primaryColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.people, size: 18, color: widget.primaryColor),
          const SizedBox(width: 8),
          Text(
            'Tổng cộng: ',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          Text(
            '$_totalElements nhân viên',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: widget.primaryColor,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(child: _buildRoleSummaryChips(roleCounts)),
        ],
      ),
    );
  }

  Widget _buildRoleSummaryChips(Map<String, int> roleCounts) {
    final roleOrder = ['ADMIN', 'PROJECT_MANAGER', 'MENTOR', 'USER'];
    final roleLabels = {
      'ADMIN': 'Admin',
      'PROJECT_MANAGER': 'Quản lý',
      'MENTOR': 'Mentor',
      'USER': 'Nhân viên',
    };
    final roleColors = {
      'ADMIN': Colors.red,
      'PROJECT_MANAGER': Colors.purple,
      'MENTOR': Colors.orange,
      'USER': Colors.blue,
    };

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: roleOrder
          .where((r) => (roleCounts[r] ?? 0) > 0)
          .map((role) {
            final count = roleCounts[role]!;
            final color = roleColors[role]!;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$count ${roleLabels[role]}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: color.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            );
          })
          .toList(),
    );
  }

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        SizedBox(
          width: 300,
          child: TextField(
            controller: _searchController,
            onChanged: _onSearch,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm nhân viên...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded, color: Colors.grey[400], size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _onSearch('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: widget.primaryColor, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _selectedRole,
              hint: Text('Tất cả vai trò', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              items: [
                DropdownMenuItem<String?>(value: null, child: Text('Tất cả vai trò')),
                DropdownMenuItem<String?>(value: 'ADMIN', child: Text('Admin')),
                DropdownMenuItem<String?>(value: 'PROJECT_MANAGER', child: Text('Quản lý')),
                DropdownMenuItem<String?>(value: 'MENTOR', child: Text('Mentor')),
                DropdownMenuItem<String?>(value: 'USER', child: Text('Nhân viên')),
              ],
              onChanged: _onRoleFilterChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy nhân viên',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedRole != null
                  ? 'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm'
                  : 'Phòng ban này chưa có nhân viên nào.',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  String _normalizeRole(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 'ADMIN';
      case 'PROJECT_MANAGER':
      case 'PROJECT MANAGER':
      case 'PM':
        return 'PROJECT_MANAGER';
      case 'MENTOR':
        return 'MENTOR';
      default:
        return 'USER';
    }
  }
}

class _MemberCard extends StatefulWidget {
  final Map<String, dynamic> member;
  final Color primaryColor;
  final List<DepartmentModel> allDepartments;
  final int currentDepartmentId;
  final VoidCallback? onDepartmentChanged;

  const _MemberCard({
    super.key,
    required this.member,
    required this.primaryColor,
    required this.allDepartments,
    required this.currentDepartmentId,
    this.onDepartmentChanged,
  });

  @override
  State<_MemberCard> createState() => _MemberCardState();
}

class _MemberCardState extends State<_MemberCard> {
  bool _isHovered = false;

  String get _displayName {
    final firstName = member['firstName'] ?? '';
    final lastName = member['lastName'] ?? '';
    final userName = member['userName'] ?? '';
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '$firstName $lastName'.trim();
    }
    return userName;
  }

  String get _role {
    final r = member['role'] ?? member['roleName'] ?? '';
    switch (r.toUpperCase()) {
      case 'ADMIN':
        return 'Admin';
      case 'PROJECT_MANAGER':
      case 'PROJECT MANAGER':
      case 'PM':
        return 'Quản lý';
      case 'MENTOR':
        return 'Mentor';
      default:
        return 'Nhân viên';
    }
  }

  Color get _roleColor {
    final r = member['role'] ?? member['roleName'] ?? '';
    switch (r.toUpperCase()) {
      case 'ADMIN':
        return Colors.red;
      case 'PROJECT_MANAGER':
      case 'PROJECT MANAGER':
      case 'PM':
        return Colors.purple;
      case 'MENTOR':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  Map<String, dynamic> get member => widget.member;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? widget.primaryColor.withValues(alpha: 0.35)
                : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? widget.primaryColor.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: _isHovered ? 14 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayName.isNotEmpty ? _displayName : 'Không tên',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${member['userName'] ?? ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                  if (member['email'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      member['email'].toString(),
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ],
              ),
            ),
            _buildRoleChip(),
            const SizedBox(width: 8),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final initials = _getInitials();
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _roleColor.withValues(alpha: 0.15),
            _roleColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _roleColor.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _roleColor),
        ),
      ),
    );
  }

  String _getInitials() {
    final firstName = member['firstName'] ?? '';
    final lastName = member['lastName'] ?? '';
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}$lastName[0]'.toUpperCase();
    } else if (firstName.isNotEmpty && firstName.length >= 2) {
      return firstName.substring(0, 2).toUpperCase();
    } else if (lastName.isNotEmpty) {
      return lastName.substring(0, lastName.length.clamp(0, 2)).toUpperCase();
    } else {
      final userName = member['userName'] ?? '';
      return userName.isNotEmpty
          ? userName.substring(0, userName.length.clamp(0, 2)).toUpperCase()
          : '?';
    }
  }

  Widget _buildRoleChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _roleColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _roleColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: _roleColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            _role,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _roleColor.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  bool get _canChangeDepartment {
    final r = member['role'] ?? member['roleName'] ?? '';
    return r.toUpperCase() == 'USER' || r.toUpperCase() == 'MENTOR';
  }

  Widget _buildActionButtons() {
    if (!_canChangeDepartment) return const SizedBox.shrink();

    final isMentor = (member['role'] ?? member['roleName'] ?? '').toUpperCase() == 'MENTOR';
    final color = isMentor ? Colors.orange : widget.primaryColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showChangeDepartmentDialog,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: 16,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Đổi pb',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showChangeDepartmentDialog() async {
    final currentDeptId = widget.member['departmentId'] ??
        widget.member['department']?['id'] ??
        widget.currentDepartmentId;

    final matchedDept = widget.allDepartments.cast<DepartmentModel?>().firstWhere(
          (d) => d?.id == currentDeptId,
          orElse: () => null,
        );

    await ChangeMemberDepartmentDialog.show(
      context: context,
      member: member,
      allDepartments: widget.allDepartments,
      primaryColor: widget.primaryColor,
      currentDepartmentId: currentDeptId,
      currentDepartmentName: matchedDept?.name ?? 'Phòng ban hiện tại',
      onSuccess: widget.onDepartmentChanged,
    );
  }
}
