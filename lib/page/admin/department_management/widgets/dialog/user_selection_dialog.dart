import 'package:flutter/material.dart';
import 'package:smet/model/user_model.dart';

enum UserSelectionType {
  manager,      // Chỉ Project Manager
  members,      // Mentor và User
  projectLead,  // Chỉ User (cho project)
  projectMentor, // Chỉ Mentor (cho project)
  all,          // Tất cả
}

class UserSelectionDialog extends StatefulWidget {
  final Color primaryColor;
  final String title;
  final UserSelectionType selectionType;
  final List<UserModel> users;
  final bool isMultiSelect;
  final List<UserModel> preSelectedUsers;
  final int? excludeDepartmentId;
  final bool allowAssigned; // Cho phép filter assigned

  const UserSelectionDialog({
    super.key,
    required this.primaryColor,
    required this.title,
    required this.selectionType,
    required this.users,
    this.isMultiSelect = false,
    this.preSelectedUsers = const [],
    this.excludeDepartmentId,
    this.allowAssigned = false,
  });

  static Future<UserModel?> selectManager({
    required BuildContext context,
    required Color primaryColor,
    required List<UserModel> managers,
    UserModel? currentManager,
    int? excludeDepartmentId,
  }) async {
    return showDialog<UserModel>(
      context: context,
      builder: (context) => UserSelectionDialog(
        primaryColor: primaryColor,
        title: 'Chọn người quản lý',
        selectionType: UserSelectionType.manager,
        users: managers,
        preSelectedUsers: currentManager != null ? [currentManager] : [],
        excludeDepartmentId: excludeDepartmentId,
        allowAssigned: true,
      ),
    );
  }

  static Future<List<UserModel>?> selectMembers({
    required BuildContext context,
    required Color primaryColor,
    required List<UserModel> members,
    List<UserModel>? preSelectedMembers,
    int? excludeDepartmentId,
  }) async {
    return showDialog<List<UserModel>>(
      context: context,
      builder: (context) => UserSelectionDialog(
        primaryColor: primaryColor,
        title: 'Thêm thành viên',
        selectionType: UserSelectionType.members,
        users: members,
        isMultiSelect: true,
        preSelectedUsers: preSelectedMembers ?? [],
        excludeDepartmentId: excludeDepartmentId,
        allowAssigned: true,
      ),
    );
  }

  static Future<UserModel?> selectProjectLead({
    required BuildContext context,
    required Color primaryColor,
    required List<UserModel> leads,
    UserModel? currentLead,
  }) async {
    return showDialog<UserModel>(
      context: context,
      builder: (context) => UserSelectionDialog(
        primaryColor: primaryColor,
        title: 'Chọn trưởng nhóm',
        selectionType: UserSelectionType.projectLead,
        users: leads,
        preSelectedUsers: currentLead != null ? [currentLead] : [],
      ),
    );
  }

  static Future<UserModel?> selectProjectMentor({
    required BuildContext context,
    required Color primaryColor,
    required List<UserModel> mentors,
    UserModel? currentMentor,
  }) async {
    return showDialog<UserModel>(
      context: context,
      builder: (context) => UserSelectionDialog(
        primaryColor: primaryColor,
        title: 'Chọn người hướng dẫn',
        selectionType: UserSelectionType.projectMentor,
        users: mentors,
        preSelectedUsers: currentMentor != null ? [currentMentor] : [],
      ),
    );
  }

  @override
  State<UserSelectionDialog> createState() => _UserSelectionDialogState();
}

class _UserSelectionDialogState extends State<UserSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late String _roleFilter;
  String _assignedFilter = 'all'; // 'all' | 'assigned' | 'unassigned'
  List<UserModel> _selectedUsers = [];

  @override
  void initState() {
    super.initState();
    _selectedUsers = List.from(widget.preSelectedUsers);
    _initRoleFilter();
  }

  void _initRoleFilter() {
    switch (widget.selectionType) {
      case UserSelectionType.manager:
        _roleFilter = 'PROJECT_MANAGER';
        break;
      case UserSelectionType.members:
        _roleFilter = 'MENTOR';
        break;
      case UserSelectionType.projectLead:
        _roleFilter = 'USER';
        break;
      case UserSelectionType.projectMentor:
        _roleFilter = 'MENTOR';
        break;
      case UserSelectionType.all:
        _roleFilter = 'ALL';
        break;
    }
  }

  @override
  void didUpdateWidget(covariant UserSelectionDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset assigned filter khi role thay đổi để tránh confusion
    if (oldWidget.selectionType != widget.selectionType) {
      _initRoleFilter();
      _assignedFilter = 'all';
      _searchQuery = '';
      _searchController.clear();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserModel> get _filteredUsers {
    return widget.users.where((user) {
      // Search filter
      final searchLower = _searchQuery.toLowerCase();
      final matchesSearch = searchLower.isEmpty ||
          user.fullName.toLowerCase().contains(searchLower) ||
          user.email.toLowerCase().contains(searchLower) ||
          (user.userName?.toLowerCase().contains(searchLower) ?? false);

      // Role filter
      final matchesRole = _roleFilter == 'ALL' || user.role.name == _roleFilter;

      // Department filter: khi cho phép assigned (chọn user từ phòng ban khác),
      // hiện tất cả user, không lọc theo department
      bool matchesDepartment = true;
      if (!widget.allowAssigned && widget.selectionType != UserSelectionType.manager) {
        final isPreSelected = widget.preSelectedUsers.any((u) => u.id == user.id);
        matchesDepartment = widget.excludeDepartmentId == null ||
            user.departmentId == null ||
            user.departmentId == widget.excludeDepartmentId ||
            isPreSelected;
      }

      // Assigned filter: chỉ áp dụng khi cho phép lọc theo assigned
      bool matchesAssigned = true;
      if (widget.allowAssigned) {
        final isAssigned = user.departmentId != null;
        if (_assignedFilter == 'assigned') {
          matchesAssigned = isAssigned;
        } else if (_assignedFilter == 'unassigned') {
          matchesAssigned = !isAssigned;
        }
        // 'all' thì không lọc
      }

      return matchesSearch && matchesRole && matchesDepartment && matchesAssigned;
    }).toList();
  }

  List<Map<String, String>> get _roleOptions {
    switch (widget.selectionType) {
      case UserSelectionType.manager:
        return [
          {'value': 'PROJECT_MANAGER', 'label': 'Quản lý dự án'},
        ];
      case UserSelectionType.members:
        return [
          {'value': 'MENTOR', 'label': 'Người hướng dẫn'},
          {'value': 'USER', 'label': 'Nhân viên'},
        ];
      case UserSelectionType.projectLead:
        return [
          {'value': 'USER', 'label': 'Nhân viên'},
        ];
      case UserSelectionType.projectMentor:
        return [
          {'value': 'MENTOR', 'label': 'Người hướng dẫn'},
        ];
      case UserSelectionType.all:
        return [
          {'value': 'ALL', 'label': 'Tất cả vai trò'},
          {'value': 'ADMIN', 'label': 'Quản trị viên'},
          {'value': 'PROJECT_MANAGER', 'label': 'Quản lý dự án'},
          {'value': 'MENTOR', 'label': 'Người hướng dẫn'},
          {'value': 'USER', 'label': 'Nhân viên'},
        ];
    }
  }

  void _toggleUser(UserModel user) {
    setState(() {
      if (widget.isMultiSelect) {
        final exists = _selectedUsers.any((u) => u.id == user.id);
        if (exists) {
          _selectedUsers.removeWhere((u) => u.id == user.id);
        } else {
          _selectedUsers.add(user);
        }
      } else {
        _selectedUsers = [user];
      }
    });
  }

  bool _isSelected(UserModel user) {
    return _selectedUsers.any((u) => u.id == user.id);
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _filteredUsers;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildSearchAndFilter(),
            const Divider(height: 1),
            _buildUserList(filteredUsers),
            const Divider(height: 1),
            _buildFooter(filteredUsers.length),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.isMultiSelect ? Icons.group_add_outlined : Icons.person_add_outlined,
              color: widget.primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.isMultiSelect
                      ? 'Chọn nhiều thành viên'
                      : 'Chọn một người',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFBFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm theo tên, email...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, size: 18, color: Colors.grey[400]),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFBFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _roleFilter,
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      items: _roleOptions
                          .map((item) => DropdownMenuItem(
                                value: item['value'],
                                child: Text(
                                  item['label']!,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _roleFilter = value;
                        _assignedFilter = 'all'; // Reset assigned filter khi đổi role
                      });
                    }
                  },
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (widget.allowAssigned) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Lọc theo:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                _buildAssignedChip('Tất cả', 'all'),
                const SizedBox(width: 8),
                _buildAssignedChip('Đã có phòng ban', 'assigned'),
                const SizedBox(width: 8),
                _buildAssignedChip('Chưa có phòng ban', 'unassigned'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAssignedChip(String label, String value) {
    final isSelected = _assignedFilter == value;
    return InkWell(
      onTap: () => setState(() => _assignedFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? widget.primaryColor.withValues(alpha: 0.12)
              : const Color(0xFFFAFBFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? widget.primaryColor.withValues(alpha: 0.4)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? widget.primaryColor : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildUserList(List<UserModel> filteredUsers) {
    if (filteredUsers.isEmpty) {
      return Container(
        height: 300,
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                'Không tìm thấy người dùng',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 350,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: filteredUsers.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (context, index) {
          final user = filteredUsers[index];
          final isSelected = _isSelected(user);

          return _UserListTile(
            user: user,
            isSelected: isSelected,
            isMultiSelect: widget.isMultiSelect,
            primaryColor: widget.primaryColor,
            onTap: () => _toggleUser(user),
          );
        },
      ),
    );
  }

  Widget _buildFooter(int totalFiltered) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.isMultiSelect
                ? 'Đã chọn: ${_selectedUsers.length} người'
                : (totalFiltered > 0 ? 'Có $totalFiltered người' : ''),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Row(
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6B7280),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Hủy'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _selectedUsers.isEmpty
                    ? null
                    : () => Navigator.pop(
                          context,
                          widget.isMultiSelect ? _selectedUsers : _selectedUsers.firstOrNull,
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[200],
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(widget.isMultiSelect ? 'Xác nhận (${_selectedUsers.length})' : 'Xác nhận'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserListTile extends StatefulWidget {
  final UserModel user;
  final bool isSelected;
  final bool isMultiSelect;
  final Color primaryColor;
  final VoidCallback onTap;

  const _UserListTile({
    required this.user,
    required this.isSelected,
    required this.isMultiSelect,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  State<_UserListTile> createState() => _UserListTileState();
}

class _UserListTileState extends State<_UserListTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? widget.primaryColor.withValues(alpha: 0.06)
              : _isHovered
                  ? const Color(0xFFF8F9FB)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: widget.primaryColor.withValues(alpha: 0.2),
                  width: 1,
                )
              : null,
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _buildSelectionIndicator(),
                const SizedBox(width: 12),
                _UserAvatar(user: widget.user, primaryColor: widget.primaryColor),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.user.fullName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF111827),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _RoleBadge(role: widget.user.role),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildInfoChip(
                            icon: Icons.alternate_email_outlined,
                            text: widget.user.email,
                            color: const Color(0xFF6B7280),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          _buildInfoChip(
                            icon: Icons.apartment_outlined,
                            text: widget.user.department?.isNotEmpty == true
                                ? widget.user.department!
                                : 'Chưa phân phòng',
                            color: widget.user.department?.isNotEmpty == true
                                ? const Color(0xFF374151)
                                : const Color(0xFF9CA3AF),
                          ),
                          const SizedBox(width: 6),
                          if (widget.user.departmentId != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 10,
                                    color: const Color(0xFF10B981),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Đã gán',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: const Color(0xFF10B981),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!widget.isMultiSelect && isSelected)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: widget.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionIndicator() {
    final isSelected = widget.isSelected;
    final color = isSelected ? widget.primaryColor : const Color(0xFFD1D5DB);

    if (widget.isMultiSelect) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: isSelected ? widget.primaryColor : Colors.transparent,
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: isSelected
            ? const Icon(Icons.check, size: 15, color: Colors.white)
            : null,
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: isSelected ? widget.primaryColor : Colors.transparent,
        border: Border.all(color: color, width: 1.5),
        shape: BoxShape.circle,
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 13, color: Colors.white)
          : null,
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final UserModel user;
  final Color primaryColor;

  const _UserAvatar({required this.user, required this.primaryColor});

  Color get _avatarColor {
    switch (user.role) {
      case UserRole.ADMIN:
        return const Color(0xFF6366F1);
      case UserRole.PROJECT_MANAGER:
        return const Color(0xFF10B981);
      case UserRole.MENTOR:
        return const Color(0xFFF59E0B);
      case UserRole.USER:
        return primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _avatarColor;
    final initials = '${user.firstName.isNotEmpty ? user.firstName[0] : ''}'
        '${(user.lastName ?? '').isNotEmpty ? user.lastName![0] : ''}';

    return Container(
      width: 44,
      height: 44,
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
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final UserRole role;

  const _RoleBadge({required this.role});

  Color get _backgroundColor {
    switch (role) {
      case UserRole.ADMIN:
        return const Color(0xFFEEF2FF);
      case UserRole.PROJECT_MANAGER:
        return const Color(0xFFECFDF5);
      case UserRole.MENTOR:
        return const Color(0xFFFEF3C7);
      case UserRole.USER:
        return const Color(0xFFF3F4F6);
    }
  }

  Color get _textColor {
    switch (role) {
      case UserRole.ADMIN:
        return const Color(0xFF4F46E5);
      case UserRole.PROJECT_MANAGER:
        return const Color(0xFF059669);
      case UserRole.MENTOR:
        return const Color(0xFFD97706);
      case UserRole.USER:
        return const Color(0xFF6B7280);
    }
  }

  String get _label {
    switch (role) {
      case UserRole.ADMIN:
        return 'Admin';
      case UserRole.PROJECT_MANAGER:
        return 'PM';
      case UserRole.MENTOR:
        return 'Mentor';
      case UserRole.USER:
        return 'User';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
