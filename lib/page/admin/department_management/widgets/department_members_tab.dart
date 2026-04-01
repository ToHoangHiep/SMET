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
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final members = await _service.getDepartmentMembers(widget.departmentId);
      log("Loaded ${members.length} members for department ${widget.departmentId}");
      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      log("LOAD MEMBERS ERROR: $e");
      setState(() {
        _error = 'Không thể tải danh sách nhân viên';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoading();
    }

    if (_error != null) {
      return _buildError();
    }

    if (_members.isEmpty) {
      return _buildEmpty();
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
            onPressed: _loadMembers,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có nhân viên nào',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Phòng ban này chưa có nhân viên nào.',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  /// Build horizontal scrollable list of member cards
  Widget _buildMembersLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.primaryColor.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                Icons.people,
                size: 18,
                color: widget.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Tổng cộng: ',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '${_members.length} nhân viên',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.primaryColor,
                ),
              ),
              const SizedBox(width: 24),
              ..._buildRoleSummaryChips(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Horizontal scrollable list
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _members.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final member = _members[index];
              return _MemberCard(
                member: member,
                primaryColor: widget.primaryColor,
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build role summary chips: [3 Admin] [5 PM] [2 Mentor] [10 User]
  List<Widget> _buildRoleSummaryChips() {
    final roleCounts = <String, int>{};
    for (final member in _members) {
      final role = _normalizeRole(member['role'] ?? member['roleName'] ?? '');
      roleCounts[role] = (roleCounts[role] ?? 0) + 1;
    }

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

    return roleOrder
        .where((r) => (roleCounts[r] ?? 0) > 0)
        .map((role) {
          final count = roleCounts[role]!;
          final color = roleColors[role]!;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
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
            ),
          );
        })
        .toList();
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

  const _MemberCard({
    required this.member,
    required this.primaryColor,
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
        width: 220,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + name row
            Row(
              children: [
                _buildAvatar(),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayName.isNotEmpty ? _displayName : 'Không tên',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${member['userName'] ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Role chip (horizontal)
            _buildRoleChip(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final initials = _getInitials();
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _roleColor.withValues(alpha: 0.15),
            _roleColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _roleColor.withValues(alpha: 0.2),
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _roleColor,
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _roleColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _roleColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _roleColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _role,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _roleColor.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
