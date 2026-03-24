import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/project_manager/project/screen/project_management_web.dart';
import 'package:smet/page/project_manager/project/screen/project_management_mobile.dart';
import 'package:smet/service/common/auth_service.dart';
import 'package:smet/model/project_model.dart';
import 'package:smet/service/project/project_service.dart';
import 'package:smet/service/project/project_member_service.dart';
import 'package:smet/service/admin/department_management/api_department_management.dart';
import 'dart:developer';

class ProjectManagementPage extends StatefulWidget {
  const ProjectManagementPage({super.key});

  @override
  State<ProjectManagementPage> createState() => _ProjectManagementPageState();
}

class _ProjectManagementPageState extends State<ProjectManagementPage> {
  String _currentUserName = 'Project Manager';
  int? _currentUserId;
  int? _currentDepartmentId;
  String?
  _currentDepartmentName; // Tên phòng ban (từ /auth/me hoặc getDepartmentByProjectManagerId) khi PM không gọi được GET /departments
  bool _isLoadingEmployees = false;

  // API Data
  List<ProjectModel> _projects = [];
  bool _isLoadingProjects = false;
  bool _isSubmitting = false;
  String _nameQuery = '';
  String _statusFilter = 'Tất cả';
  int _currentPage = 0;
  final int _rowsPerPage = 10;
  bool _isCreateMode = false;
  bool _isUpdateMode = false;
  String? _editingProjectId;
  final TextEditingController _createNameController = TextEditingController();
  final TextEditingController _createDescriptionController =
      TextEditingController();
  final TextEditingController _createManagerController =
      TextEditingController();
  String _createStatus = 'INACTIVE';
  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedLeaderId; // Leader của dự án
  String?
  _selectedLeaderName; // Tên trưởng nhóm (để hiển thị khi không có _leadOptions)
  List<Map<String, dynamic>> _selectedMembers = [];

  // Separate lists for Lead, Members
  List<Map<String, dynamic>> _leadOptions = [];
  List<Map<String, dynamic>> _memberOptions = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadProjects();
  }

  Future<void> _loadProjects({bool resetPage = false}) async {
    if (resetPage) {
      _currentPage = 0;
    }
    setState(() => _isLoadingProjects = true);
    try {
      // Chuyển đổi status filter sang format backend
      String? statusFilter;
      if (_statusFilter != 'Tất cả') {
        if (_statusFilter == 'Nháp') {
          statusFilter = 'INACTIVE';
        } else if (_statusFilter == 'Đang thực hiện') {
          statusFilter = 'ACTIVE';
        } else if (_statusFilter == 'Hoàn thành') {
          statusFilter = 'COMPLETED';
        }
      }

      final projects = await ProjectService.getAll(
        keyword: _nameQuery.isNotEmpty ? _nameQuery : null,
        status: statusFilter,
        page: _currentPage,
        size: _rowsPerPage,
      );
      setState(() {
        _projects = projects;
      });
    } catch (e) {
      debugPrint('Error loading projects: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải dự án: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingProjects = false);
      }
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userData = await AuthService.getMe();

      // Debug: log toàn bộ keys của userData
      log("USER DATA KEYS: ${userData.keys.toList()}");
      log("DEPARTMENT FIELD: ${userData['department']}");
      log("DEPARTMENT TYPE: ${userData['department'].runtimeType}");

      // Lấy userId trước
      final currentUserId = userData['id'] as int?;
      log("Current User ID: $currentUserId");

      // Thử lấy departmentId và departmentName từ userData trước
      int? deptId;
      String? deptName;
      if (userData['departmentId'] != null) {
        deptId = userData['departmentId'] as int?;
        log("Got departmentId from direct field: $deptId");
      }
      // Backend UserDto trả về departmentName trực tiếp (flat field)
      deptName = userData['departmentName']?.toString();
      if (deptName != null && deptName.isNotEmpty) {
        log("Got departmentName from /auth/me: $deptName");
      }
      // Fallback: thử từ object department (nếu có)
      final department = userData['department'];
      if (department is Map) {
        log("Department raw: $department");
        if (deptId == null) deptId = department['id'] as int?;
        deptName ??= department['name']?.toString();
        log("Got departmentName from department object: $deptName");
      }

      // Nếu vẫn không có departmentId, tìm department có projectManagerId = currentUserId
      if (deptId == null && currentUserId != null) {
        try {
          final deptService = DepartmentService();
          final dept = await deptService.getDepartmentByProjectManagerId(
            currentUserId,
          );
          if (dept != null) {
            deptId = dept.id;
            deptName ??= dept.name;
            log(
              "Got departmentId from projectManager lookup: $deptId, name: $deptName",
            );
          }
        } catch (e) {
          log("Error finding department by projectManagerId: $e");
        }
      }

      log(
        "FINAL - ID: $currentUserId, DepartmentId: $deptId, DepartmentName: $deptName",
      );

      setState(() {
        _currentUserName =
            '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'
                .trim();
        if (_currentUserName.isEmpty) {
          _currentUserName = userData['userName'] ?? 'Project Manager';
        }
        _currentUserId = currentUserId;
        _currentDepartmentId = deptId;
        _currentDepartmentName = deptName;
      });

      // Sau khi có departmentId, load employees
      if (deptId != null) {
        _loadEmployees();
      }
    } catch (e) {
      debugPrint('Error loading current user: $e');
      setState(() {
        _currentUserName = 'Project Manager';
      });
    }
  }

  Future<void> _loadEmployees() async {
    if (_currentDepartmentId == null) return;

    setState(() => _isLoadingEmployees = true);
    try {
      // API mới: /api/users/for-project?departmentId=xxx
      final allUsers = await ProjectMemberService.getUsersForProject(
        departmentId: _currentDepartmentId!,
      );

      log("========== LOAD USERS FOR PROJECT ==========");
      log("Total users: ${allUsers.length}");

      setState(() {
        // Tất cả user đều có thể làm leader hoặc member
        _leadOptions = allUsers;
        _memberOptions = allUsers;
      });
    } catch (e) {
      debugPrint('Error loading employees: $e');
    } finally {
      setState(() => _isLoadingEmployees = false);
    }
  }

  @override
  void dispose() {
    _createNameController.dispose();
    _createDescriptionController.dispose();
    _createManagerController.dispose();
    super.dispose();
  }

  void handleLogout() => context.go('/login');

  void handleProfileTap() => context.go('/profile');

  void setNameQuery(String v) => setState(() {
    _nameQuery = v;
    _loadProjects(resetPage: true);
  });
  void setStatusFilter(String v) => setState(() {
    _statusFilter = v;
    _loadProjects(resetPage: true);
  });
  void setCurrentPage(int v) => setState(() {
    _currentPage = v;
    _loadProjects();
  });
  void setCreateStatus(String v) => setState(() => _createStatus = v);

  void openEditProjectScreen(ProjectModel project) async {
    setState(() {
      _isUpdateMode = true;
      _isCreateMode = false;
      _editingProjectId = project.id.toString();
      _createNameController.text = project.title;
      _createDescriptionController.text = project.description ?? '';
      _createStatus = project.status.name;
      _selectedLeaderId = project.leaderId > 0 ? project.leaderId : null;
      _selectedLeaderName = project.leaderName;

      // Chuyển memberIds thành danh sách Map để hiển thị
      _selectedMembers = [];
      if (project.memberIds != null) {
        for (final memberId in project.memberIds!) {
          _selectedMembers.add({
            'id': memberId,
            'name':
                project.memberNames != null &&
                        project.memberIds!.indexOf(memberId) <
                            project.memberNames!.length
                    ? project.memberNames![project.memberIds!.indexOf(memberId)]
                    : 'User $memberId',
            'email': '',
          });
        }
      }
    });

    log(
      "Project loaded - LeaderId: ${project.leaderId}, Members: ${project.memberIds}",
    );
  }

  /// Mở dialog xem chi tiết dự án (read-only). Có nút "Cập nhật" để chuyển sang chỉnh sửa.
  void _showProjectView(ProjectModel project) {
    final departmentName = _currentDepartmentName ?? 'Không xác định';
    final statusLabel = project.status.label;
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.folder_outlined, color: const Color(0xFF6366F1)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    project.title,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (project.description != null &&
                      project.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        project.description!,
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                    ),
                  _buildViewRow('Phòng ban', departmentName),
                  _buildViewRow(
                    'Trưởng nhóm',
                    project.leaderName ?? 'User ${project.leaderId}',
                  ),
                  _buildViewRow('Trạng thái', statusLabel),
                  if (project.memberIds != null &&
                      project.memberIds!.isNotEmpty)
                    _buildViewRow(
                      'Thành viên',
                      project.memberNames != null &&
                              project.memberNames!.isNotEmpty
                          ? project.memberNames!.join(', ')
                          : '${project.memberIds!.length} thành viên',
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  openEditProjectScreen(project);
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Cập nhật'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildViewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Future<void> _loadProjectMembers(int projectId) async {
    try {
      // API mới trả về leaderId và memberIds trực tiếp trong project
      final project = await ProjectService.getById(projectId);
      log(
        "Loaded project details: leaderId=${project.leaderId}, memberIds=${project.memberIds}",
      );

      setState(() {
        _selectedLeaderId = project.leaderId > 0 ? project.leaderId : null;
        _selectedLeaderName = project.leaderName;

        // Chuyển memberIds thành danh sách Map để hiển thị
        _selectedMembers = [];
        if (project.memberIds != null) {
          for (final memberId in project.memberIds!) {
            _selectedMembers.add({
              'id': memberId,
              'name': 'User $memberId',
              'email': '',
            });
          }
        }
      });

      log("Parsed - LeaderId: $_selectedLeaderId, Members: $_selectedMembers");
    } catch (e) {
      log("Error loading project members: $e");
    }
  }

  void openCreateProjectScreen() => setState(() {
    _isCreateMode = true;
    _isUpdateMode = false;
    _editingProjectId = null;
    _createNameController.clear();
    _createDescriptionController.clear();
    _createManagerController.clear();
    _createStatus = 'INACTIVE';
    _startDate = null;
    _endDate = null;
    _selectedLeaderId = null;
    _selectedLeaderName = null;
    _selectedMembers = [];
  });

  void closeFormScreen() => setState(() {
    _isCreateMode = false;
    _isUpdateMode = false;
    _editingProjectId = null;
  });

  void submitCreateProject() async {
    if (_createNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên dự án'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_currentDepartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bạn chưa được gán phòng ban. Vui lòng liên hệ quản trị viên.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedLeaderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn Trưởng nhóm'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Chuẩn bị danh sách memberIds
      final memberIds =
          _selectedMembers.isNotEmpty
              ? _selectedMembers
                  .map((m) => int.parse(m['id'].toString()))
                  .toList()
              : null;

      // Tạo project - Backend mới yêu cầu leaderId và memberIds
      final project = await ProjectService.create(
        title: _createNameController.text,
        description:
            _createDescriptionController.text.isNotEmpty
                ? _createDescriptionController.text
                : null,
        departmentId: _currentDepartmentId!,
        leaderId: _selectedLeaderId!,
        memberIds: memberIds,
        status: _createStatus,
      );

      // Reload danh sách project
      await _loadProjects();

      setState(() {
        _isCreateMode = false;
        _currentPage = 1;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tạo dự án thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error creating project: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tạo dự án: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void submitUpdateProject() async {
    if (_editingProjectId == null) return;

    if (_selectedLeaderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn Trưởng nhóm'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Lấy departmentId từ project đang edit
      final editingProject = _projects.firstWhere(
        (p) => p.id.toString() == _editingProjectId,
      );

      // Chuẩn bị danh sách memberIds
      final memberIds =
          _selectedMembers.isNotEmpty
              ? _selectedMembers
                  .map((m) => int.parse(m['id'].toString()))
                  .toList()
              : null;

      // Cập nhật project - Backend mới yêu cầu leaderId và memberIds
      await ProjectService.update(
        id: int.parse(_editingProjectId!),
        title: _createNameController.text,
        description:
            _createDescriptionController.text.isNotEmpty
                ? _createDescriptionController.text
                : null,
        departmentId: editingProject.departmentId,
        leaderId: _selectedLeaderId!,
        memberIds: memberIds,
      );

      // Cập nhật status riêng (nếu cần)
      if (_createStatus != editingProject.status.name) {
        await ProjectService.updateStatus(
          int.parse(_editingProjectId!),
          _createStatus,
        );
      }

      // Reload danh sách project
      await _loadProjects();

      setState(() {
        _isUpdateMode = false;
        _editingProjectId = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật dự án'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating project: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi cập nhật dự án: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> handleDeleteProject(ProjectModel project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: const Text('Xóa dự án'),
            content: Text(
              'Bạn có chắc muốn xóa dự án "${project.title}" không?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Xóa'),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      try {
        await ProjectService.delete(project.id);
        await _loadProjects();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa dự án'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error deleting project: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi xóa dự án: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget buildPageHeader() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.folder_special,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Danh sách dự án',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            Text(
              'Quản lý và theo dõi các dự án của bạn',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
        const Spacer(),
        if (!_isCreateMode && !_isUpdateMode)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF137FEC).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: openCreateProjectScreen,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF137FEC),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Tạo dự án',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    ),
  );

  Widget buildFormCard() => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isUpdateMode ? Icons.edit_note : Icons.add_box,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isUpdateMode ? 'Cập nhật dự án' : 'Tạo dự án mới',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isUpdateMode
                            ? 'Chỉnh sửa thông tin dự án'
                            : 'Điền thông tin để tạo dự án mới',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: closeFormScreen,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildAnimatedSection(
                  icon: Icons.info_outline,
                  iconColor: const Color(0xFF6366F1),
                  title: 'Thông tin chung',
                  child: Column(
                    children: [
                      _buildModernTextField(
                        controller: _createNameController,
                        label: 'Tên dự án',
                        hint: 'Nhập tên dự án...',
                        prefixIcon: Icons.folder_outlined,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildInfoCard(
                              label: 'Phòng ban',
                              value: _currentDepartmentName ?? 'Chưa gán phòng ban',
                              icon: Icons.business_outlined,
                              color: const Color(0xFF6366F1),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: _buildInfoCard(
                              label: 'Quản lý',
                              value:
                                  _currentUserName.isNotEmpty
                                      ? _currentUserName
                                      : 'Đang tải...',
                              icon: Icons.person_outlined,
                              color: const Color(0xFF10B981),
                              avatarText:
                                  _currentUserName.isNotEmpty
                                      ? _currentUserName[0].toUpperCase()
                                      : '?',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: _buildModernDropdown()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildModernTextField(
                        controller: _createDescriptionController,
                        label: 'Mô tả dự án',
                        hint: 'Mô tả ngắn gọn về mục tiêu và phạm vi dự án...',
                        prefixIcon: Icons.description_outlined,
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildAnimatedSection(
                  icon: Icons.person_outline,
                  iconColor: const Color(0xFF8B5CF6),
                  title: 'Trưởng nhóm',
                  subtitle: 'Chọn trưởng nhóm dự án',
                  child:
                      _isLoadingEmployees
                          ? _buildLoadingShimmer()
                          : _buildLeaderSelector(),
                ),
                const SizedBox(height: 20),
                _buildAnimatedSection(
                  icon: Icons.people_outline,
                  iconColor: const Color(0xFF10B981),
                  title: 'Thành viên nhóm',
                  subtitle: 'Chọn thành viên tham gia dự án',
                  child: _buildMembersSection(),
                ),
                const SizedBox(height: 32),
                _buildActionButtons(),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  // Modern TextField với animation
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(prefixIcon, color: const Color(0xFF6366F1), size: 20),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  // Info Card hiển thị thông tin
  Widget _buildInfoCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    String? avatarText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              if (avatarText != null)
                CircleAvatar(
                  radius: 16,
                  backgroundColor: color,
                  child: Text(
                    avatarText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color.withOpacity(0.9),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Modern Dropdown
  Widget _buildModernDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trạng thái',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: DropdownButtonFormField<String>(
            value: _createStatus,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(_createStatus).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getStatusIcon(_createStatus),
                  color: _getStatusColor(_createStatus),
                  size: 18,
                ),
              ),
            ),
            items: [
              _buildStatusItem('INACTIVE', 'Không hoạt động', Colors.grey),
              _buildStatusItem('ACTIVE', 'Hoạt động', Colors.blue),
              _buildStatusItem('COMPLETED', 'Hoàn thành', Colors.green),
            ],
            onChanged: (v) => setCreateStatus(v!),
          ),
        ),
      ],
    );
  }

  DropdownMenuItem<String> _buildStatusItem(
    String value,
    String label,
    Color color,
  ) {
    return DropdownMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return Colors.blue;
      case 'COMPLETED':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'ACTIVE':
        return Icons.play_circle_outline;
      case 'COMPLETED':
        return Icons.check_circle_outline;
      default:
        return Icons.pause_circle_outline;
    }
  }

  // Animated Section Card
  Widget _buildAnimatedSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  // Loading shimmer
  Widget _buildLoadingShimmer() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 80,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Leader Selector
  Widget _buildLeaderSelector() {
    return InkWell(
      onTap: _showLeaderPicker,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFFFAF5FF), const Color(0xFFF3E8FF)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                _selectedLeaderId != null
                    ? const Color(0xFF8B5CF6)
                    : const Color(0xFFE5E7EB),
            width: _selectedLeaderId != null ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child:
                  _selectedLeaderId != null
                      ? CircleAvatar(
                        key: const ValueKey('selected'),
                        backgroundColor: const Color(0xFF8B5CF6),
                        radius: 20,
                        child: Text(
                          _getLeaderName(_selectedLeaderId!).isNotEmpty
                              ? _getLeaderName(
                                _selectedLeaderId!,
                              )[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                      : Container(
                        key: const ValueKey('empty'),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.person_add_outlined,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedLeaderId != null
                        ? _getLeaderName(_selectedLeaderId!)
                        : 'Chọn trưởng nhóm',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color:
                          _selectedLeaderId != null
                              ? const Color(0xFF1F2937)
                              : Colors.grey[400],
                    ),
                  ),
                  if (_selectedLeaderId == null)
                    Text(
                      'Nhấn để chọn người quản lý',
                      style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF8B5CF6),
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Members Section
  Widget _buildMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedMembers.isNotEmpty) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.group,
                        color: Color(0xFF10B981),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedMembers.length} thành viên đã chọn',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      _selectedMembers
                          .map((member) => _buildMemberChip(member))
                          .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        _buildAddMemberButton(),
      ],
    );
  }

  Widget _buildMemberChip(Map<String, dynamic> member) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFF10B981),
            child: Text(
              (member['name'] as String?)?.isNotEmpty == true
                  ? member['name']![0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            member['name'] ?? '',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => setState(() => _selectedMembers.remove(member)),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddMemberButton() {
    return InkWell(
      onTap: () => _showMembersPicker(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF10B981),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.person_add_outlined,
                color: Color(0xFF10B981),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Thêm thành viên',
              style: TextStyle(
                color: Color(0xFF10B981),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Action Buttons
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: TextButton(
            onPressed: closeFormScreen,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Hủy bỏ',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF137FEC).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed:
                _isSubmitting
                    ? null
                    : (_isUpdateMode
                        ? submitUpdateProject
                        : submitCreateProject),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF137FEC),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child:
                _isSubmitting
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isUpdateMode ? Icons.save : Icons.add_circle_outline,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isUpdateMode ? 'Cập nhật' : 'Tạo dự án',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildFormField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          isStartDate
              ? (_startDate ?? DateTime.now())
              : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Widget _buildSelectButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: Colors.grey[400]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedPersonCard(
    Map<String, dynamic> person,
    VoidCallback onChange,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF8B5CF6),
            radius: 24,
            child: Text(
              (person['name'] as String?)?.isNotEmpty == true
                  ? person['name']![0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person['name'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                if ((person['email'] as String?)?.isNotEmpty == true)
                  Text(
                    person['email'] ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChange,
            child: const Text(
              'Change',
              style: TextStyle(
                color: Color(0xFF8B5CF6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLeaderPicker() {
    if (_currentDepartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn phòng ban trước')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (ctx) => _LeaderPickerSheetContent(
            departmentId: _currentDepartmentId!,
            pageSize: 10,
            onSelectLeader: (user) {
              final id = user['id'];
              final idInt = id is int ? id : int.tryParse(id.toString());
              if (idInt == null) return;
              final firstName = user['firstName'] ?? '';
              final lastName = user['lastName'] ?? '';
              final fullName = '$firstName $lastName'.trim();
              setState(() {
                _selectedLeaderId = idInt;
                _selectedLeaderName = fullName;
              });
            },
          ),
    );
  }

  String _getLeaderName(int id) {
    if (_selectedLeaderName != null && _selectedLeaderId == id) {
      return _selectedLeaderName!;
    }
    final pm = _leadOptions.where((e) => e['id'] == id).firstOrNull;
    if (pm != null) {
      final firstName = pm['firstName'] ?? '';
      final lastName = pm['lastName'] ?? '';
      return '$firstName $lastName'.trim();
    }
    return 'User $id';
  }

  void _showMembersPicker() {
    if (_currentDepartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn phòng ban trước')),
      );
      return;
    }
    final excludeIds = <int>[
      if (_selectedLeaderId != null) _selectedLeaderId!,
      ..._selectedMembers
          .map((e) => int.tryParse(e['id']?.toString() ?? '') ?? 0)
          .where((id) => id > 0),
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (ctx) => _MemberPickerSheetContent(
            departmentId: _currentDepartmentId!,
            excludeUserIds: excludeIds,
            pageSize: 10,
            onSelectMember: (user) {
              final id = user['id'];
              final firstName = user['firstName'] ?? '';
              final lastName = user['lastName'] ?? '';
              final fullName = '$firstName $lastName'.trim();
              final email = user['email'] ?? '';
              setState(
                () => _selectedMembers.add({
                  'id': id,
                  'name': fullName,
                  'email': email,
                }),
              );
            },
          ),
    );
  }

  Widget buildTableSection() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        // Search and Filter Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFFFAFBFC), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: TextField(
                    onChanged: setNameQuery,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm dự án...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.search,
                          color: const Color(0xFF6366F1),
                          size: 18,
                        ),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _statusFilter,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    borderRadius: BorderRadius.circular(12),
                    items: [
                      _buildFilterItem(
                        'Tất cả',
                        Icons.dashboard_outlined,
                        Colors.grey,
                      ),
                      _buildFilterItem(
                        'Không hoạt động',
                        Icons.pause_circle_outline,
                        Colors.grey,
                      ),
                      _buildFilterItem(
                        'Hoạt động',
                        Icons.play_circle_outline,
                        Colors.blue,
                      ),
                      _buildFilterItem(
                        'Hoàn thành',
                        Icons.check_circle_outline,
                        Colors.green,
                      ),
                    ],
                    onChanged: (v) => setStatusFilter(v!),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Content
        if (_isLoadingProjects)
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Đang tải dữ liệu...',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          )
        else if (_projects.isEmpty)
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.folder_open,
                    size: 48,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Chưa có dự án nào',
                  style: TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nhấn "Tạo dự án" để thêm dự án mới',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
          )
        else
          _buildProjectsList(),
      ],
    ),
  );

  DropdownMenuItem<String> _buildFilterItem(
    String label,
    IconData icon,
    Color color,
  ) {
    return DropdownMenuItem(
      value: label,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildProjectsList() {
    // Chuyển đổi filter status sang enum name để so sánh
    String? filterStatusEnum;
    if (_statusFilter != 'Tất cả') {
      if (_statusFilter == 'Không hoạt động') {
        filterStatusEnum = 'INACTIVE';
      } else if (_statusFilter == 'Hoạt động') {
        filterStatusEnum = 'ACTIVE';
      } else if (_statusFilter == 'Hoàn thành') {
        filterStatusEnum = 'COMPLETED';
      }
    }

    final filteredProjects =
        _projects.where((p) {
          final matchesName =
              _nameQuery.isEmpty ||
              p.title.toLowerCase().contains(_nameQuery.toLowerCase());
          final matchesStatus =
              filterStatusEnum == null || p.status.name == filterStatusEnum;
          return matchesName && matchesStatus;
        }).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredProjects.length,
      padding: const EdgeInsets.only(bottom: 16),
      itemBuilder: (context, index) {
        final project = filteredProjects[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 200 + (index * 50)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: _buildProjectCard(project),
        );
      },
    );
  }

  Widget _buildProjectCard(ProjectModel project) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (project.status) {
      case ProjectStatus.INACTIVE:
        statusColor = Colors.grey;
        statusLabel = 'Không hoạt động';
        statusIcon = Icons.pause_circle_outline;
        break;
      case ProjectStatus.ACTIVE:
        statusColor = Colors.blue;
        statusLabel = 'Hoạt động';
        statusIcon = Icons.play_circle_outline;
        break;
      case ProjectStatus.COMPLETED:
        statusColor = Colors.green;
        statusLabel = 'Hoàn thành';
        statusIcon = Icons.check_circle_outline;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _showProjectView(project),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Project Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor.withOpacity(0.1),
                        statusColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.folder_outlined,
                    color: statusColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Project Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        project.description?.isNotEmpty ?? false
                            ? project.description!
                            : 'Không có mô tả',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 14, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  statusLabel,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (project.memberIds != null &&
                              project.memberIds!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.people,
                                    size: 14,
                                    color: Color(0xFF8B5CF6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${project.memberIds!.length} thành viên',
                                    style: const TextStyle(
                                      color: Color(0xFF8B5CF6),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      icon: Icons.edit_outlined,
                      color: const Color(0xFF6366F1),
                      onTap: () => openEditProjectScreen(project),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.delete_outline,
                      color: Colors.red,
                      onTap: () => handleDeleteProject(project),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  Widget buildProjectList() => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.folder_open, size: 64, color: Color(0xFFE5E7EB)),
          SizedBox(height: 16),
          Text(
            'Chưa có dự án nào',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (kIsWeb || constraints.maxWidth > 850) {
              return ProjectManagementWeb(
                pageHeader: buildPageHeader(),
                formCard: buildFormCard(),
                tableSection: buildTableSection(),
                showForm: _isCreateMode || _isUpdateMode,
                userName: _currentUserName,
                onLogout: handleLogout,
                onProfileTap: handleProfileTap,
              );
            } else {
              return ProjectManagementMobile(
                pageHeader: buildPageHeader(),
                formCard: buildFormCard(),
                projectList: buildProjectList(),
                showForm: _isCreateMode || _isUpdateMode,
                userName: _currentUserName,
                onLogout: handleLogout,
              );
            }
          },
        ),
      ),
    );
  }
}

/// Sheet chọn Trưởng nhóm với search + phân trang (API /users/for-project)
class _LeaderPickerSheetContent extends StatefulWidget {
  final int departmentId;
  final int pageSize;
  final void Function(Map<String, dynamic> user) onSelectLeader;

  const _LeaderPickerSheetContent({
    required this.departmentId,
    required this.pageSize,
    required this.onSelectLeader,
  });

  @override
  State<_LeaderPickerSheetContent> createState() =>
      _LeaderPickerSheetContentState();
}

class _LeaderPickerSheetContentState extends State<_LeaderPickerSheetContent> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<Map<String, dynamic>> _users = [];
  int _page = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  bool _isLoading = false;
  String _keyword = '';
  String? _selectedRole; // Filter by role

  static const List<Map<String, String?>> _roleOptions = [
    {'label': 'Tất cả', 'value': null},
    {'label': 'Mentor', 'value': 'MENTOR'},
    {'label': 'Nhân viên', 'value': 'USER'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPage() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final result = await ProjectMemberService.getUsersForProjectPaginated(
        departmentId: widget.departmentId,
        keyword: _keyword.isEmpty ? null : _keyword,
        excludeUserIds: null,
        role: _selectedRole,
        page: _page,
        size: widget.pageSize,
      );
      if (!mounted) return;
      setState(() {
        _users = result['users'] as List<Map<String, dynamic>>;
        _totalPages = result['totalPages'] as int;
        _totalElements = result['totalElements'] as int;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải danh sách: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSearch(String value) {
    setState(() {
      _keyword = value.trim();
      _page = 0;
    });
    _loadPage();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _onSearch(value);
    });
  }

  static String _roleDisplayName(String? role) {
    if (role == null) return '';
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 'Quản trị';
      case 'PROJECT_MANAGER':
        return 'Quản lý dự án';
      case 'MENTOR':
        return 'Hướng dẫn';
      default:
        return 'Nhân viên';
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF8B5CF6);
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder:
          (_, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle bar
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.engineering,
                          color: primaryPurple,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Chọn Trưởng nhóm',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: Colors.grey[600]),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                        ),
                      ),
                    ],
                  ),
                ),
                // Search
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    onSubmitted: _onSearch,
                    decoration: InputDecoration(
                      hintText: 'Tìm theo tên hoặc email...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: primaryPurple,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: primaryPurple,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Role filter chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _roleOptions.map((opt) {
                          final selected = _selectedRole == opt['value'];
                          return FilterChip(
                            label: Text(opt['label']!),
                            selected: selected,
                            onSelected: (value) {
                              setState(() {
                                _selectedRole = opt['value'];
                                _page = 0;
                              });
                              _loadPage();
                            },
                            selectedColor: primaryPurple.withOpacity(0.15),
                            checkmarkColor: primaryPurple,
                            labelStyle: TextStyle(
                              color:
                                  selected ? primaryPurple : Colors.grey[700],
                              fontWeight:
                                  selected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                              fontSize: 13,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                // List
                Expanded(
                  child:
                      _isLoading
                          ? const Center(
                            child: CircularProgressIndicator(
                              color: primaryPurple,
                            ),
                          )
                          : _users.isEmpty
                          ? Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 56,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _keyword.isEmpty
                                      ? 'Không có user phù hợp'
                                      : 'Không tìm thấy kết quả',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _users.length,
                            itemBuilder: (_, i) {
                              final u = _users[i];
                              final firstName = u['firstName'] ?? '';
                              final lastName = u['lastName'] ?? '';
                              final fullName = '$firstName $lastName'.trim();
                              final email = u['email'] ?? '';
                              final role = u['role']?.toString();
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.grey.shade100,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () {
                                      widget.onSelectLeader(u);
                                      Navigator.pop(context);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: primaryPurple,
                                            radius: 24,
                                            child: Text(
                                              firstName.isNotEmpty
                                                  ? firstName[0].toUpperCase()
                                                  : '?',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  fullName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    if (role != null &&
                                                        role.isNotEmpty) ...[
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: primaryPurple
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          _roleDisplayName(
                                                            role,
                                                          ),
                                                          style: const TextStyle(
                                                            color:
                                                                primaryPurple,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 11,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                    ],
                                                    if (email.isNotEmpty)
                                                      Flexible(
                                                        child: Text(
                                                          email,
                                                          style: TextStyle(
                                                            color:
                                                                Colors
                                                                    .grey[500],
                                                            fontSize: 12,
                                                          ),
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: primaryPurple.withOpacity(
                                                0.1,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.add,
                                              color: primaryPurple,
                                              size: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                ),
                // Pagination
                if (_totalElements > 0 && _totalPages > 0)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$_totalElements kết quả',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        Row(
                          children: [
                            _buildPaginationButton(
                              icon: Icons.chevron_left,
                              onPressed:
                                  _page > 0
                                      ? () {
                                        setState(() => _page--);
                                        _loadPage();
                                      }
                                      : null,
                              primaryColor: primaryPurple,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: primaryPurple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_page + 1} / $_totalPages',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: primaryPurple,
                                ),
                              ),
                            ),
                            _buildPaginationButton(
                              icon: Icons.chevron_right,
                              onPressed:
                                  _page < _totalPages - 1
                                      ? () {
                                        setState(() => _page++);
                                        _loadPage();
                                      }
                                      : null,
                              primaryColor: primaryPurple,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
    );
  }

  Widget _buildPaginationButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color primaryColor,
  }) {
    return Material(
      color: onPressed != null ? Colors.white : Colors.grey[100],
      borderRadius: BorderRadius.circular(8),
      elevation: onPressed != null ? 2 : 0,
      shadowColor: onPressed != null ? Colors.black12 : Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: onPressed != null ? primaryColor : Colors.grey[300],
          ),
        ),
      ),
    );
  }
}

/// Sheet chọn thành viên với search + phân trang (API /users/for-project)
class _MemberPickerSheetContent extends StatefulWidget {
  final int departmentId;
  final List<int> excludeUserIds;
  final int pageSize;
  final void Function(Map<String, dynamic> user) onSelectMember;

  const _MemberPickerSheetContent({
    required this.departmentId,
    required this.excludeUserIds,
    required this.pageSize,
    required this.onSelectMember,
  });

  @override
  State<_MemberPickerSheetContent> createState() =>
      _MemberPickerSheetContentState();
}

class _MemberPickerSheetContentState extends State<_MemberPickerSheetContent> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;

  List<Map<String, dynamic>> _users = [];

  static String roleDisplayName(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 'Quản trị';
      case 'PROJECT_MANAGER':
        return 'Quản lý dự án';
      case 'MENTOR':
        return 'Hướng dẫn';
      default:
        return 'Nhân viên';
    }
  }

  int _page = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  bool _isLoading = false;
  String _keyword = '';
  String? _selectedRole; // Filter by role
  List<int> _excludeIds = [];

  static const List<Map<String, String?>> _roleOptions = [
    {'label': 'Tất cả', 'value': null},
    {'label': 'Mentor', 'value': 'MENTOR'},
    {'label': 'Nhân viên', 'value': 'USER'},
  ];

  @override
  void initState() {
    super.initState();
    _excludeIds = List.from(widget.excludeUserIds);
    _loadPage();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPage() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final result = await ProjectMemberService.getUsersForProjectPaginated(
        departmentId: widget.departmentId,
        keyword: _keyword.isEmpty ? null : _keyword,
        excludeUserIds: _excludeIds.isEmpty ? null : _excludeIds,
        role: _selectedRole,
        page: _page,
        size: widget.pageSize,
      );
      if (!mounted) return;
      setState(() {
        _users = result['users'] as List<Map<String, dynamic>>;
        _totalPages = result['totalPages'] as int;
        _totalElements = result['totalElements'] as int;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải danh sách: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSearch(String value) {
    setState(() {
      _keyword = value.trim();
      _page = 0;
    });
    _loadPage();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _onSearch(value);
    });
  }

  void _onSelect(Map<String, dynamic> user) {
    final id = user['id'];
    if (id == null) return;
    final idInt = id is int ? id : int.tryParse(id.toString());
    if (idInt == null) return;
    setState(() => _excludeIds.add(idInt));
    _users.removeWhere((e) {
      final eid = e['id'];
      final eidInt = eid is int ? eid : int.tryParse(e['id']?.toString() ?? '');
      return eidInt == idInt;
    });
    widget.onSelectMember(user);
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF10B981);
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder:
          (_, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle bar
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.group,
                          color: primaryGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Chọn thành viên',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: Colors.grey[600]),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                        ),
                      ),
                    ],
                  ),
                ),
                // Search
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    onSubmitted: _onSearch,
                    decoration: InputDecoration(
                      hintText: 'Tìm theo tên hoặc email...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: primaryGreen,
                        size: 20,
                      ),
                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _searchController,
                        builder:
                            (_, value, __) =>
                                value.text.isNotEmpty
                                    ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        _onSearch('');
                                      },
                                    )
                                    : const SizedBox.shrink(),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: primaryGreen,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Role filter chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _roleOptions.map((opt) {
                          final selected = _selectedRole == opt['value'];
                          return FilterChip(
                            label: Text(opt['label']!),
                            selected: selected,
                            onSelected: (value) {
                              setState(() {
                                _selectedRole = opt['value'];
                                _page = 0;
                              });
                              _loadPage();
                            },
                            selectedColor: primaryGreen.withOpacity(0.15),
                            checkmarkColor: primaryGreen,
                            labelStyle: TextStyle(
                              color: selected ? primaryGreen : Colors.grey[700],
                              fontWeight:
                                  selected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                              fontSize: 13,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                // List
                Expanded(
                  child:
                      _isLoading
                          ? const Center(
                            child: CircularProgressIndicator(
                              color: primaryGreen,
                            ),
                          )
                          : _users.isEmpty
                          ? Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 56,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _keyword.isEmpty
                                      ? 'Không có thành viên khả dụng'
                                      : 'Không tìm thấy kết quả',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _users.length,
                            itemBuilder: (_, i) {
                              final member = _users[i];
                              final firstName = member['firstName'] ?? '';
                              final lastName = member['lastName'] ?? '';
                              final fullName = '$firstName $lastName'.trim();
                              final email = member['email'] ?? '';
                              final role = member['role']?.toString();
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.grey.shade100,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () => _onSelect(member),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: primaryGreen,
                                            radius: 24,
                                            child: Text(
                                              firstName.isNotEmpty
                                                  ? firstName[0].toUpperCase()
                                                  : '?',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  fullName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    if (role != null &&
                                                        role.isNotEmpty) ...[
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: primaryGreen
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          roleDisplayName(role),
                                                          style: const TextStyle(
                                                            color: primaryGreen,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 11,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                    ],
                                                    if (email.isNotEmpty)
                                                      Flexible(
                                                        child: Text(
                                                          email,
                                                          style: TextStyle(
                                                            color:
                                                                Colors
                                                                    .grey[500],
                                                            fontSize: 12,
                                                          ),
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: primaryGreen.withOpacity(
                                                0.1,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.add,
                                              color: primaryGreen,
                                              size: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                ),
                // Pagination
                if (_totalElements > 0 && _totalPages > 0)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$_totalElements kết quả',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        Row(
                          children: [
                            _buildPaginationButton(
                              icon: Icons.chevron_left,
                              onPressed:
                                  _page > 0
                                      ? () {
                                        setState(() => _page--);
                                        _loadPage();
                                      }
                                      : null,
                              primaryColor: primaryGreen,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_page + 1} / $_totalPages',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: primaryGreen,
                                ),
                              ),
                            ),
                            _buildPaginationButton(
                              icon: Icons.chevron_right,
                              onPressed:
                                  _page < _totalPages - 1
                                      ? () {
                                        setState(() => _page++);
                                        _loadPage();
                                      }
                                      : null,
                              primaryColor: primaryGreen,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
    );
  }

  Widget _buildPaginationButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color primaryColor,
  }) {
    return Material(
      color: onPressed != null ? Colors.white : Colors.grey[100],
      borderRadius: BorderRadius.circular(8),
      elevation: onPressed != null ? 2 : 0,
      shadowColor: onPressed != null ? Colors.black12 : Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: onPressed != null ? primaryColor : Colors.grey[300],
          ),
        ),
      ),
    );
  }
}
