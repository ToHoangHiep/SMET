import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smet/model/assignable_user_model.dart';
import 'package:smet/service/admin/user_assignment/user_assignment_service.dart';
import 'package:smet/service/common/base_url.dart';

class Department {
  final int id;
  final String name;

  Department({required this.id, required this.name});

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

// ============================================================
// _UserListTile - Item widget cho danh sach user
// ============================================================
class _UserListTile extends StatelessWidget {
  final AssignableUser user;
  final bool isSelected;
  final Color primaryColor;
  final VoidCallback onTap;

  const _UserListTile({
    required this.user,
    required this.isSelected,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected ? primaryColor.withValues(alpha: 0.05) : Colors.transparent,
        child: Row(
          children: [
            _CheckboxIndicator(isSelected: isSelected, primaryColor: primaryColor),
            const SizedBox(width: 12),
            _UserAvatar(user: user, primaryColor: primaryColor),
            const SizedBox(width: 14),
            Expanded(child: _UserInfo(user: user)),
            _UserStats(user: user, primaryColor: primaryColor),
          ],
        ),
      ),
    );
  }
}

class _CheckboxIndicator extends StatelessWidget {
  final bool isSelected;
  final Color primaryColor;

  const _CheckboxIndicator({required this.isSelected, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: isSelected ? primaryColor : Colors.transparent,
        border: Border.all(
          color: isSelected ? primaryColor : Colors.grey.shade300,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : null,
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final AssignableUser user;
  final Color primaryColor;

  const _UserAvatar({required this.user, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withValues(alpha: 0.15),
            primaryColor.withValues(alpha: 0.05),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: primaryColor.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Center(
        child: Text(
          user.initials,
          style: TextStyle(color: primaryColor, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _UserInfo extends StatelessWidget {
  final AssignableUser user;

  const _UserInfo({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.displayName,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF111827), fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF137FEC), fontSize: 12),
        ),
        if (user.departmentName != null && user.departmentName!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.apartment, size: 12, color: Color(0xFF137FEC)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  user.departmentName!,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF137FEC), fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _UserStats extends StatelessWidget {
  final AssignableUser user;
  final Color primaryColor;

  const _UserStats({required this.user, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _StatBadge(
          icon: Icons.school_outlined,
          count: user.enrolledCourseCount,
          label: 'khóa',
          primaryColor: primaryColor,
        ),
        const SizedBox(height: 4),
        _StatBadge(
          icon: Icons.route_outlined,
          count: user.learningPathCount,
          label: 'LP',
          primaryColor: primaryColor,
        ),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color primaryColor;

  const _StatBadge({
    required this.icon,
    required this.count,
    required this.label,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: primaryColor),
          const SizedBox(width: 3),
          Text(
            '$count $label',
            style: TextStyle(fontSize: 10, color: primaryColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// AssignableUserDialog - Dialog chon user co phan trang + tim kiem
// ============================================================
class AssignableUserDialog extends StatefulWidget {
  final Color primaryColor;
  final String title;
  final List<AssignableUser>? preSelectedUsers;
  final String? roleFilter;
  /// Optional custom fetch function for project-scoped user selection.
  /// When provided, this replaces the default UserAssignmentService call.
  final Future<AssignablePageResult> Function({
    String? keyword,
    String? role,
    int? departmentId,
    int? page,
    int? size,
  })? customUserFetcher;
  /// Optional static user list. When provided, this list is used directly
  /// instead of fetching from API. Supports local search only (no pagination).
  final List<AssignableUser>? customUsers;

  const AssignableUserDialog({
    super.key,
    required this.primaryColor,
    this.title = 'Chọn người được gán',
    this.preSelectedUsers,
    this.roleFilter,
    this.customUserFetcher,
    this.customUsers,
  });

  static Future<List<AssignableUser>?> show({
    required BuildContext context,
    required Color primaryColor,
    String title = 'Chọn người được gán',
    List<AssignableUser>? preSelectedUsers,
    String? roleFilter,
    Future<AssignablePageResult> Function({
      String? keyword,
      String? role,
      int? departmentId,
      int? page,
      int? size,
    })? customUserFetcher,
    List<AssignableUser>? customUsers,
  }) {
    return showDialog<List<AssignableUser>>(
      context: context,
      builder: (context) => AssignableUserDialog(
        primaryColor: primaryColor,
        title: title,
        preSelectedUsers: preSelectedUsers,
        roleFilter: roleFilter,
        customUserFetcher: customUserFetcher,
        customUsers: customUsers,
      ),
    );
  }

  @override
  State<AssignableUserDialog> createState() => _AssignableUserDialogState();
}

class _AssignableUserDialogState extends State<AssignableUserDialog> {
  final UserAssignmentService _service = UserAssignmentService();
  final TextEditingController _searchController = TextEditingController();

  List<AssignableUser> _users = [];
  List<AssignableUser> _selectedUsers = [];
  List<Department> _departments = [];
  int? _selectedDepartmentId;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  int _currentPage = 0;
  bool _hasNext = true;
  String _searchQuery = '';
  Timer? _debounce;
  bool _useStaticList = false;
  List<AssignableUser> _staticUsers = [];

  @override
  void initState() {
    super.initState();
    _selectedUsers = List.from(widget.preSelectedUsers ?? []);
    _useStaticList = widget.customUsers != null;
    _staticUsers = widget.customUsers ?? [];
    _loadDepartments();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      if (token == null) return;

      final res = await http.get(
        Uri.parse('$baseUrl/departments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> content =
            (data['data'] ?? data['content'] ?? data ?? []) as List<dynamic>;
        if (mounted) {
          setState(() {
            _departments = content
                .map((e) => Department.fromJson(e as Map<String, dynamic>))
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading departments: $e');
    }
  }

  Future<void> _loadUsers({bool append = false}) async {
    if (_useStaticList) {
      _applyStaticSearch();
      return;
    }

    if (append) {
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      AssignablePageResult result;
      if (widget.customUserFetcher != null) {
        result = await widget.customUserFetcher!(
          keyword: _searchQuery.isNotEmpty ? _searchQuery : null,
          role: widget.roleFilter,
          departmentId: _selectedDepartmentId,
          page: append ? _currentPage : 0,
          size: 20,
        );
      } else {
        result = await _service.getAssignableUsers(
          keyword: _searchQuery.isNotEmpty ? _searchQuery : null,
          role: widget.roleFilter,
          departmentId: _selectedDepartmentId,
          page: append ? _currentPage : 0,
          size: 20,
        );
      }

      setState(() {
        if (append) {
          _users.addAll(result.data);
          _isLoadingMore = false;
        } else {
          _users = result.data;
          _isLoading = false;
        }
        _hasNext = result.hasNext;
        _currentPage = result.page + 1;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _error = 'Không thể tải danh sách người dùng';
      });
    }
  }

  void _applyStaticSearch() {
    setState(() {
      _isLoading = true;
    });
    final query = _searchQuery.toLowerCase();
    final filtered = query.isEmpty
        ? _staticUsers
        : _staticUsers.where((u) {
            return u.fullName.toLowerCase().contains(query) ||
                u.email.toLowerCase().contains(query);
          }).toList();
    setState(() {
      _users = filtered;
      _isLoading = false;
      _hasNext = false;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasNext) return;
    await _loadUsers(append: true);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    setState(() {
      _searchQuery = value;
    });
    if (_useStaticList) {
      _applyStaticSearch();
    } else {
      _debounce = Timer(const Duration(milliseconds: 400), () {
        setState(() {
          _currentPage = 0;
          _users = [];
        });
        _loadUsers();
      });
    }
  }

  void _onDepartmentChanged(int? value) {
    setState(() {
      _selectedDepartmentId = value;
      _currentPage = 0;
      _users = [];
    });
    _loadUsers();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedDepartmentId = null;
      _currentPage = 0;
      _users = [];
    });
    _loadUsers();
  }

  void _toggleUser(AssignableUser user) {
    setState(() {
      final exists = _selectedUsers.any((u) => u.userId == user.userId);
      if (exists) {
        _selectedUsers.removeWhere((u) => u.userId == user.userId);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  bool _isUserSelected(AssignableUser user) {
    return _selectedUsers.any((u) => u.userId == user.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 750),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilterBar(),
            const Divider(height: 1),
            _buildUserList(),
            const Divider(height: 1),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final hasFilters = _selectedDepartmentId != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _buildDepartmentDropdown(),
          const Spacer(),
          if (hasFilters)
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Xoa loc'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDepartmentDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _selectedDepartmentId,
          hint: const Text('Phong ban'),
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
          items: [
            const DropdownMenuItem(value: null, child: Text('Tat ca phong ban')),
            ..._departments.map(
              (dept) => DropdownMenuItem(
                value: dept.id,
                child: Text(dept.name, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: _onDepartmentChanged,
          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
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
              Icons.assignment_ind_outlined,
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
                  'Chọn nhiều người để gán',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFAFBFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm theo tên, email...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, size: 18, color: Colors.grey[400]),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildUserList() {
    if (_isLoading) {
      return Container(
        height: 350,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Container(
        height: 350,
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Colors.red[600])),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _loadUsers(),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_users.isEmpty) {
      return Container(
        height: 350,
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

    return Container(
      height: 350,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.extentAfter < 200 &&
              !_isLoadingMore &&
              _hasNext) {
            _loadMore();
          }
          return false;
        },
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _users.length + (_isLoadingMore ? 1 : 0),
          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
          itemBuilder: (context, index) {
            if (index >= _users.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final user = _users[index];
            return _UserListTile(
              user: user,
              isSelected: _isUserSelected(user),
              primaryColor: widget.primaryColor,
              onTap: () => _toggleUser(user),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFBFC),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Đã chọn: ${_selectedUsers.length} người',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          Row(
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6B7280),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Hủy'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _selectedUsers.isEmpty
                    ? null
                    : () => Navigator.pop(context, _selectedUsers),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[200],
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Xác nhận (${_selectedUsers.length})'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
