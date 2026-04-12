import 'package:flutter/material.dart';
import 'package:smet/service/admin/department_management/api_department_management.dart';
import 'dart:developer';

class DepartmentMembersTab extends StatefulWidget {
  final int departmentId;
  final Color primaryColor;

  const DepartmentMembersTab({
    super.key,
    required this.departmentId,
    required this.primaryColor,
  });

  @override
  State<DepartmentMembersTab> createState() => _DepartmentMembersTabState();
}

class _DepartmentMembersTabState extends State<DepartmentMembersTab> {
  final DepartmentService _service = DepartmentService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  
  String _searchQuery = '';
  String? _selectedRole;
  int _currentPage = 0;
  int _totalPages = 1;
  int _totalElements = 0;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers({bool loadMore = false}) async {
    if (loadMore) {
      if (_isLoadingMore || _currentPage >= _totalPages - 1) return;
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentPage = 0;
      });
    }

    try {
      final result = await _service.getDepartmentMembers(
        departmentId: widget.departmentId,
        keyword: _searchQuery.isEmpty ? null : _searchQuery,
        role: _selectedRole,
        page: loadMore ? _currentPage + 1 : 0,
        size: _pageSize,
      );
      
      final members = result['members'] as List<dynamic>? ?? [];
      final totalPages = result['totalPages'] as int? ?? 1;
      final totalElements = result['totalElements'] as int? ?? 0;
      
      log("Loaded ${members.length} members for department ${widget.departmentId}, total: $totalElements");

      if (mounted) {
        setState(() {
          if (loadMore) {
            _members.addAll(members.cast<Map<String, dynamic>>());
            _isLoadingMore = false;
          } else {
            _members = members.cast<Map<String, dynamic>>();
            _isLoading = false;
          }
          _currentPage = loadMore ? _currentPage + 1 : 0;
          _totalPages = totalPages;
          _totalElements = totalElements;
        });
      }
    } catch (e) {
      log("LOAD MEMBERS ERROR: $e");
      if (mounted) {
        setState(() {
          _error = 'Không thể tải danh sách nhân viên';
          _isLoading = false;
          _isLoadingMore = false;
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

  Widget _buildMembersLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryRow(),
        const SizedBox(height: 16),
        _buildSearchAndFilter(),
        const SizedBox(height: 16),
        if (_members.isEmpty)
          _buildEmpty()
        else
          Expanded(
            child: _buildMembersList(),
          ),
        if (_members.isNotEmpty) _buildPagination(),
      ],
    );
  }

  Widget _buildSummaryRow() {
    final roleCounts = <String, int>{};
    for (final member in _members) {
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

  Widget _buildMembersList() {
    return ListView.separated(
      itemCount: _members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final member = _members[index];
        return _MemberCard(
          member: member,
          primaryColor: widget.primaryColor,
        );
      },
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 0 ? () => _loadMembers() : null,
            icon: const Icon(Icons.chevron_left),
            color: widget.primaryColor,
            disabledColor: Colors.grey[300],
          ),
          const SizedBox(width: 8),
          Text(
            'Trang ${_currentPage + 1} / $_totalPages',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(width: 8),
          if (_isLoadingMore)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              onPressed: _currentPage < _totalPages - 1 ? () => _loadMembers(loadMore: true) : null,
              icon: const Icon(Icons.chevron_right),
              color: widget.primaryColor,
              disabledColor: Colors.grey[300],
            ),
        ],
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

  const _MemberCard({required this.member, required this.primaryColor});

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
}
