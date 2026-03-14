import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/project_manager/project/screen/project_management_web.dart';
import 'package:smet/page/project_manager/project/screen/project_management_mobile.dart';
import 'package:smet/service/common/auth_service.dart';
import 'package:smet/model/project_model.dart';
import 'package:smet/service/project/project_service.dart';
import 'package:smet/service/project/project_member_service.dart';
import 'package:smet/model/department_model.dart';
import 'package:smet/service/admin/department_management/api_department_management.dart';
import 'package:smet/service/common/user_selection_service.dart';
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
  bool _isLoadingEmployees = false;

  // API Data
  List<ProjectModel> _projects = [];
  bool _isLoadingProjects = false;
  bool _isSubmitting = false;
  String _nameQuery = '';
  String _statusFilter = 'Tất cả';
  int _currentPage = 1;
  final int _rowsPerPage = 5;
  bool _isCreateMode = false;
  bool _isUpdateMode = false;
  String? _editingProjectId;
  final TextEditingController _createNameController = TextEditingController();
  final TextEditingController _createDescriptionController =
      TextEditingController();
  final TextEditingController _createManagerController =
      TextEditingController();
  String _createStatus = 'DRAFT';
  DateTime? _startDate;
  DateTime? _endDate;
  Map<String, dynamic>? _selectedTeamLead;
  Map<String, dynamic>? _selectedMentor;
  List<Map<String, dynamic>> _selectedMembers = [];

  // Department list for dropdown
  List<DepartmentModel> _departments = [];

  // Separate lists for Lead, Mentors, Members
  List<Map<String, dynamic>> _leadOptions = [];
  List<Map<String, dynamic>> _mentorOptions = [];
  List<Map<String, dynamic>> _memberOptions = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadEmployees();
    _loadProjects();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    try {
      final api = DepartmentService();
      final depts = await api.getDepartments();
      setState(() {
        _departments = depts;
      });
      log("Loaded ${depts.length} departments");
    } catch (e) {
      log("Error loading departments: $e");
    }
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoadingProjects = true);
    try {
      final projects = await ProjectService.getAll();
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

      // Thử lấy departmentId từ userData trước
      int? deptId;
      if (userData['departmentId'] != null) {
        deptId = userData['departmentId'] as int?;
        log("Got departmentId from direct field: $deptId");
      } else {
        // Fallback: lấy departmentId từ object department (nếu có)
        final department = userData['department'];
        log("Department raw: $department");
        if (department is Map) {
          log("Department keys: ${department.keys.toList()}");
          deptId = department['id'] as int?;
          log("Got departmentId from object: $deptId");
        }
      }

      // Nếu vẫn không có departmentId, tìm department có projectManagerId = currentUserId
      if (deptId == null && currentUserId != null) {
        try {
          final deptService = DepartmentService();
          final department = await deptService.getDepartmentByProjectManagerId(
            currentUserId,
          );
          if (department != null) {
            deptId = department.id;
            log("Got departmentId from projectManager lookup: $deptId");
          }
        } catch (e) {
          log("Error finding department by projectManagerId: $e");
        }
      }

      log("FINAL - ID: $currentUserId, DepartmentId: $deptId");

      setState(() {
        _currentUserName =
            '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'
                .trim();
        if (_currentUserName.isEmpty) {
          _currentUserName = userData['userName'] ?? 'Project Manager';
        }
        _currentUserId = currentUserId;
        _currentDepartmentId = deptId;
      });
    } catch (e) {
      debugPrint('Error loading current user: $e');
      setState(() {
        _currentUserName = 'Project Manager';
      });
    }
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoadingEmployees = true);
    try {
      // Load users with proper context for project roles
      final leads = await ProjectMemberService.getSelectableUsers(
        context: 'PROJECT_LEAD',
      );
      final mentors = await ProjectMemberService.getSelectableUsers(
        context: 'PROJECT_MENTORS',
      );
      final members = await ProjectMemberService.getSelectableUsers(
        context: 'PROJECT_MEMBERS',
      );

      log("========== LOAD USERS FOR PROJECT ==========");
      log("Leads (PROJECT_LEAD): ${leads.length}");
      log("Mentors (PROJECT_MENTORS): ${mentors.length}");
      log("Members (PROJECT_MEMBERS): ${members.length}");

      setState(() {
        _leadOptions = leads;
        _mentorOptions = mentors;
        _memberOptions = members;
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

  void setNameQuery(String v) => setState(() {
    _nameQuery = v;
    _currentPage = 1;
  });
  void setStatusFilter(String v) => setState(() {
    _statusFilter = v;
    _currentPage = 1;
  });
  void setCurrentPage(int v) => setState(() => _currentPage = v);
  void setCreateStatus(String v) => setState(() => _createStatus = v);

  void openEditProjectScreen(ProjectModel project) async {
    setState(() {
      _isUpdateMode = true;
      _isCreateMode = false;
      _editingProjectId = project.id.toString();
      _createNameController.text = project.title;
      _createDescriptionController.text = project.description ?? '';
      _createStatus = project.status.name;
    });

    // Load project chi tiết để lấy leaderName, mentorName, members
    try {
      final detailedProject = await ProjectService.getById(project.id);
      log(
        "Project details: leaderName=${detailedProject.leaderName}, mentorName=${detailedProject.mentorName}, members=${detailedProject.members}",
      );

      setState(() {
        // Trưởng nhóm
        if (detailedProject.leaderName != null &&
            detailedProject.leaderName!.isNotEmpty) {
          _selectedTeamLead = {'name': detailedProject.leaderName, 'email': ''};
        } else {
          _selectedTeamLead = null;
        }

        // Người hướng dẫn
        if (detailedProject.mentorName != null &&
            detailedProject.mentorName!.isNotEmpty) {
          _selectedMentor = {'name': detailedProject.mentorName, 'email': ''};
        } else {
          _selectedMentor = null;
        }

        // Thành viên
        _selectedMembers = [];
        if (detailedProject.members != null) {
          for (final memberName in detailedProject.members!) {
            _selectedMembers.add({'name': memberName, 'email': ''});
          }
        }
      });

      log(
        "Parsed - Lead: $_selectedTeamLead, Mentor: $_selectedMentor, Members: $_selectedMembers",
      );
    } catch (e) {
      log("Error loading project details: $e");
    }
  }

  Future<void> _loadProjectMembers(int projectId) async {
    try {
      // API trả về List<Map> với userId và role
      final members = await ProjectMemberService.getMembers(projectId);
      log("Loaded project members: $members");

      // Lấy thông tin user trước
      Map<String, dynamic>? lead;
      Map<String, dynamic>? mentor;
      List<Map<String, dynamic>> memberList = [];

      for (final m in members) {
        final role = m['role'] as String?;
        final userId = m['userId'] as int;
        final memberId = m['id'];

        // Lấy username và email từ API
        String displayName = 'User ${userId}';
        String displayEmail = '';
        try {
          final user = await getUserById(userId);
          if (user != null) {
            displayName =
                user.userName?.isNotEmpty == true
                    ? user.userName!
                    : 'User ${userId}';
            displayEmail = user.email ?? '';
          }
        } catch (e) {
          log("Error fetching user $userId: $e");
          // Giữ nguyên displayName = 'User ${userId}'
        }

        if (role == 'PROJECT_LEAD') {
          lead = {
            'id': userId,
            'memberId': memberId,
            'name': displayName,
            'email': displayEmail,
          };
        } else if (role == 'MENTOR') {
          mentor = {
            'id': userId,
            'memberId': memberId,
            'name': displayName,
            'email': displayEmail,
          };
        } else if (role == 'MEMBER') {
          memberList.add({
            'id': userId,
            'memberId': memberId,
            'name': displayName,
            'email': displayEmail,
          });
        }
      }

      setState(() {
        _selectedTeamLead = lead;
        _selectedMentor = mentor;
        _selectedMembers = memberList;
      });

      log(
        "Parsed - Lead: $_selectedTeamLead, Mentor: $_selectedMentor, Members: $_selectedMembers",
      );
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
    _createStatus = 'DRAFT';
    _startDate = null;
    _endDate = null;
    _selectedTeamLead = null;
    _selectedMentor = null;
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

    setState(() => _isSubmitting = true);

    try {
      // Tạo project trước
      final project = await ProjectService.create(
        title: _createNameController.text,
        description:
            _createDescriptionController.text.isNotEmpty
                ? _createDescriptionController.text
                : null,
        departmentId: _currentDepartmentId!,
        status: _createStatus,
        userId: _currentUserId,
      );

      // Thêm PM (người tạo) vào project TRƯỚC để có quyền thêm member
      // Backend yêu cầu user phải thuộc project mới được thêm member
      // Sau đó thêm các thành viên khác vào project (nếu có)
      if (_selectedTeamLead != null) {
        log("========== ADD PROJECT LEAD ==========");
        log("Project ID: ${project.id}");
        log("User ID: ${_selectedTeamLead!['id']}");
        log("Role: PROJECT_LEAD");
        await ProjectMemberService.addMember(
          projectId: project.id,
          userId: int.parse(_selectedTeamLead!['id'].toString()),
          role: 'PROJECT_LEAD',
        );
      }

      if (_selectedMentor != null) {
        log("========== ADD PROJECT MENTOR ==========");
        log("Project ID: ${project.id}");
        log("User ID: ${_selectedMentor!['id']}");
        log("Role: MENTOR");
        await ProjectMemberService.addMember(
          projectId: project.id,
          userId: int.parse(_selectedMentor!['id'].toString()),
          role: 'MENTOR',
        );
      }

      for (final member in _selectedMembers) {
        log("========== ADD PROJECT MEMBER ==========");
        log("Project ID: ${project.id}");
        log("User ID: ${member['id']}");
        log("Role: MEMBER");
        await ProjectMemberService.addMember(
          projectId: project.id,
          userId: int.parse(member['id'].toString()),
          role: 'MEMBER',
        );
      }

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

    setState(() => _isSubmitting = true);

    try {
      // Lấy departmentId từ project đang edit
      final editingProject = _projects.firstWhere(
        (p) => p.id.toString() == _editingProjectId,
      );

      await ProjectService.update(
        id: int.parse(_editingProjectId!),
        title: _createNameController.text,
        description:
            _createDescriptionController.text.isNotEmpty
                ? _createDescriptionController.text
                : null,
        departmentId: editingProject.departmentId,
        status: _createStatus,
      );

      // Cập nhật members - lấy danh sách members hiện tại của project
      final currentMembers = await ProjectMemberService.getMembers(
        int.parse(_editingProjectId!),
      );

      // Map current members by role
      final currentLead =
          currentMembers.where((m) => m['role'] == 'PROJECT_LEAD').firstOrNull;
      final currentMentor =
          currentMembers.where((m) => m['role'] == 'MENTOR').firstOrNull;
      final currentMemberList =
          currentMembers.where((m) => m['role'] == 'MEMBER').toList();

      // Xử lý PROJECT_LEAD
      if (_selectedTeamLead != null) {
        final newLeadId = int.parse(_selectedTeamLead!['id'].toString());
        if (currentLead == null) {
          // Thêm mới lead
          await ProjectMemberService.addMember(
            projectId: int.parse(_editingProjectId!),
            userId: newLeadId,
            role: 'PROJECT_LEAD',
          );
        } else {
          final currentLeadUser = currentLead['user'] as Map<String, dynamic>?;
          if (currentLeadUser != null && currentLeadUser['id'] != newLeadId) {
            // Xóa lead cũ và thêm mới
            await ProjectMemberService.removeMember(
              projectId: int.parse(_editingProjectId!),
              userId: currentLeadUser['id'] as int,
            );
            await ProjectMemberService.addMember(
              projectId: int.parse(_editingProjectId!),
              userId: newLeadId,
              role: 'PROJECT_LEAD',
            );
          }
        }
      } else if (currentLead != null) {
        // Nếu không chọn lead mà trước đó có lead, xóa lead cũ
        final currentLeadUser = currentLead['user'] as Map<String, dynamic>?;
        if (currentLeadUser != null) {
          await ProjectMemberService.removeMember(
            projectId: int.parse(_editingProjectId!),
            userId: currentLeadUser['id'] as int,
          );
        }
      }

      // Xử lý MENTOR
      if (_selectedMentor != null) {
        final newMentorId = int.parse(_selectedMentor!['id'].toString());
        if (currentMentor == null) {
          // Thêm mới mentor
          await ProjectMemberService.addMember(
            projectId: int.parse(_editingProjectId!),
            userId: newMentorId,
            role: 'MENTOR',
          );
        } else {
          final currentMentorUser =
              currentMentor['user'] as Map<String, dynamic>?;
          if (currentMentorUser != null &&
              currentMentorUser['id'] != newMentorId) {
            // Xóa mentor cũ và thêm mới
            await ProjectMemberService.removeMember(
              projectId: int.parse(_editingProjectId!),
              userId: currentMentorUser['id'] as int,
            );
            await ProjectMemberService.addMember(
              projectId: int.parse(_editingProjectId!),
              userId: newMentorId,
              role: 'MENTOR',
            );
          }
        }
      } else if (currentMentor != null) {
        // Nếu không chọn mentor mà trước đó có mentor, xóa mentor cũ
        final currentMentorUser =
            currentMentor['user'] as Map<String, dynamic>?;
        if (currentMentorUser != null) {
          await ProjectMemberService.removeMember(
            projectId: int.parse(_editingProjectId!),
            userId: currentMentorUser['id'] as int,
          );
        }
      }

      // Xử lý MEMBERS - đồng bộ danh sách
      final newMemberIds =
          _selectedMembers.map((m) => int.parse(m['id'].toString())).toSet();
      final currentMemberIds =
          currentMemberList
              .map((m) => (m['user'] as Map<String, dynamic>?)?['id'] as int?)
              .where((id) => id != null)
              .toSet();

      // Thêm các member mới
      for (final newMember in _selectedMembers) {
        final newMemberId = int.parse(newMember['id'].toString());
        if (!currentMemberIds.contains(newMemberId)) {
          await ProjectMemberService.addMember(
            projectId: int.parse(_editingProjectId!),
            userId: newMemberId,
            role: 'MEMBER',
          );
        }
      }

      // Xóa các member không còn trong danh sách
      for (final currentMember in currentMemberList) {
        final currentMemberUser =
            currentMember['user'] as Map<String, dynamic>?;
        if (currentMemberUser != null) {
          final currentMemberId = currentMemberUser['id'] as int?;
          if (currentMemberId != null &&
              !newMemberIds.contains(currentMemberId)) {
            await ProjectMemberService.removeMember(
              projectId: int.parse(_editingProjectId!),
              userId: currentMemberId,
            );
          }
        }
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

  Widget buildPageHeader() => Row(
    children: [
      const Text(
        'DANH SÁCH DỰ ÁN',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF64748B),
        ),
      ),
      const Spacer(),
      if (!_isCreateMode && !_isUpdateMode)
        ElevatedButton.icon(
          onPressed: openCreateProjectScreen,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF137FEC),
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.add),
          label: const Text('Tạo dự án'),
        ),
    ],
  );

  Widget buildFormCard() => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: closeFormScreen,
              icon: const Icon(Icons.arrow_back, color: Color(0xFF64748B)),
            ),
            Text(
              _isUpdateMode ? 'Cập nhật dự án' : 'Tạo dự án mới',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionCard(
          icon: Icons.info_outline,
          iconColor: const Color(0xFFEF4444),
          title: 'Thông tin chung',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildFormField(
                      label: 'Tên dự án',
                      child: TextField(
                        controller: _createNameController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Hiện đại hóa cơ sở hạ tầng',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildFormField(
                      label: 'Phòng ban',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Text(
                          _currentDepartmentId != null
                              ? _departments
                                      .where(
                                        (d) => d.id == _currentDepartmentId,
                                      )
                                      .firstOrNull
                                      ?.name ??
                                  'Không xác định'
                              : 'Chưa gán phòng ban',
                          style: TextStyle(
                            color:
                                _currentDepartmentId != null
                                    ? Colors.black87
                                    : Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildFormField(
                      label: 'Trạng thái dự án',
                      child: DropdownButtonFormField<String>(
                        value: _createStatus,
                        hint: Text(
                          'Chọn trạng thái',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'DRAFT', child: Text('Nháp')),
                          DropdownMenuItem(
                            value: 'IN_PROGRESS',
                            child: Text('Đang thực hiện'),
                          ),
                          DropdownMenuItem(
                            value: 'COMPLETED',
                            child: Text('Hoàn thành'),
                          ),
                          DropdownMenuItem(
                            value: 'CANCELLED',
                            child: Text('Đã hủy'),
                          ),
                        ],
                        onChanged: (v) => setCreateStatus(v!),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildFormField(
                label: 'Mô tả',
                child: TextField(
                  controller: _createDescriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Mô tả ngắn gọn về mục tiêu và phạm vi dự án...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const SizedBox(height: 24),
        _buildSectionCard(
          icon: Icons.person_outline,
          iconColor: const Color(0xFF8B5CF6),
          title: 'Trưởng nhóm',
          subtitle: 'Chọn trưởng nhóm dự án.',
          child:
              _selectedTeamLead != null
                  ? _buildSelectedPersonCard(
                    _selectedTeamLead!,
                    () => _showTeamLeadPicker(),
                  )
                  : _buildSelectButton(
                    'Chọn trưởng nhóm',
                    () => _showTeamLeadPicker(),
                  ),
        ),
        const SizedBox(height: 24),
        _buildSectionCard(
          icon: Icons.school_outlined,
          iconColor: const Color(0xFFF97316),
          title: 'Người hướng dẫn',
          subtitle: 'Chọn người hướng dẫn cho dự án này.',
          child:
              _selectedMentor != null
                  ? _buildSelectedPersonCard(
                    _selectedMentor!,
                    () => _showMentorPicker(),
                  )
                  : _buildSelectButton(
                    'Chọn người hướng dẫn',
                    () => _showMentorPicker(),
                  ),
        ),
        const SizedBox(height: 24),
        _buildSectionCard(
          icon: Icons.people_outline,
          iconColor: const Color(0xFF10B981),
          title: 'Thành viên nhóm',
          subtitle: 'Chọn thành viên cho dự án này.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedMembers.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      _selectedMembers
                          .map(
                            (member) => Chip(
                              avatar: CircleAvatar(
                                backgroundColor: const Color(0xFF10B981),
                                child: Text(
                                  (member['name'] as String?)?.isNotEmpty ==
                                          true
                                      ? member['name']![0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              label: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    member['name'] ?? '',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  if ((member['email'] as String?)?.isNotEmpty == true)
                                    Text(
                                      member['email'] ?? '',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted:
                                  () => setState(
                                    () => _selectedMembers.remove(member),
                                  ),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 16),
              ],
              _buildSelectButton('Thêm thành viên', () => _showMembersPicker()),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: closeFormScreen,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed:
                  _isSubmitting
                      ? null
                      : (_isUpdateMode
                          ? submitUpdateProject
                          : submitCreateProject),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF137FEC),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(_isUpdateMode ? 'Cập nhật dự án' : 'Tạo dự án mới'),
            ),
          ],
        ),
      ],
    ),
  );

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

  void _showTeamLeadPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (ctx) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chọn trưởng nhóm (USER)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (_isLoadingEmployees)
                  const Center(child: CircularProgressIndicator())
                else if (_leadOptions.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Không có user phù hợp'),
                    ),
                  )
                else
                  ..._leadOptions.map((employee) {
                    final firstName = employee['firstName'] ?? '';
                    final lastName = employee['lastName'] ?? '';
                    final fullName = '$firstName $lastName'.trim();
                    final email = employee['email'] ?? '';
                    final id = employee['id'];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF8B5CF6),
                        child: Text(
                          firstName.isNotEmpty
                              ? firstName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(fullName),
                      subtitle: Text(email),
                      onTap: () {
                        setState(
                          () =>
                              _selectedTeamLead = {
                                'id': id,
                                'name': fullName,
                                'email': email,
                              },
                        );
                        Navigator.pop(ctx);
                      },
                    );
                  }),
              ],
            ),
          ),
    );
  }

  void _showMentorPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (ctx) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chọn người hướng dẫn (MENTOR)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (_mentorOptions.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Không có user phù hợp'),
                    ),
                  )
                else
                  ..._mentorOptions.map((m) {
                    final firstName = m['firstName'] ?? '';
                    final lastName = m['lastName'] ?? '';
                    final fullName = '$firstName $lastName'.trim();
                    final email = m['email'] ?? '';
                    final id = m['id'];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFF97316),
                        child: Text(
                          firstName.isNotEmpty
                              ? firstName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(fullName),
                      subtitle: Text(email),
                      onTap: () {
                        setState(
                          () =>
                              _selectedMentor = {
                                'id': id,
                                'name': fullName,
                                'email': email,
                              },
                        );
                        Navigator.pop(ctx);
                      },
                    );
                  }),
              ],
            ),
          ),
    );
  }

  void _showMembersPicker() {
    final availableToSelect =
        _memberOptions
            .where((e) => !_selectedMembers.any((s) => s['id'] == e['id']))
            .toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (ctx) => DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.8,
            expand: false,
            builder:
                (_, controller) => Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chọn thành viên',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child:
                            availableToSelect.isEmpty
                                ? const Center(
                                  child: Text('Không có thành viên khả dụng'),
                                )
                                : ListView.builder(
                                  controller: controller,
                                  itemCount: availableToSelect.length,
                                  itemBuilder: (_, i) {
                                    final member = availableToSelect[i];
                                    final firstName = member['firstName'] ?? '';
                                    final lastName = member['lastName'] ?? '';
                                    final fullName =
                                        '$firstName $lastName'.trim();
                                    final email = member['email'] ?? '';
                                    final id = member['id'];
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: const Color(
                                          0xFF10B981,
                                        ),
                                        child: Text(
                                          firstName.isNotEmpty
                                              ? firstName[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      title: Text(fullName),
                                      subtitle: Text(email),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                          color: Color(0xFF10B981),
                                        ),
                                        onPressed: () {
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
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget buildTableSection() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    ),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: setNameQuery,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _statusFilter,
                items: const [
                  DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả')),
                  DropdownMenuItem(value: 'DRAFT', child: Text('Nháp')),
                  DropdownMenuItem(
                    value: 'IN_PROGRESS',
                    child: Text('Đang thực hiện'),
                  ),
                  DropdownMenuItem(
                    value: 'COMPLETED',
                    child: Text('Hoàn thành'),
                  ),
                  DropdownMenuItem(value: 'CANCELLED', child: Text('Đã hủy')),
                ],
                onChanged: (v) => setStatusFilter(v!),
              ),
            ],
          ),
        ),
        if (_isLoadingProjects)
          const Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          )
        else if (_projects.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.folder_open, size: 64, color: Color(0xFFE5E7EB)),
                SizedBox(height: 16),
                Text(
                  'Chưa có dự án nào',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Nhấn "Tạo dự án" để thêm dự án mới',
                  style: TextStyle(color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          )
        else
          _buildProjectsList(),
      ],
    ),
  );

  Widget _buildProjectsList() {
    final filteredProjects =
        _projects.where((p) {
          final matchesName =
              _nameQuery.isEmpty ||
              p.title.toLowerCase().contains(_nameQuery.toLowerCase());
          final matchesStatus =
              _statusFilter == 'Tất cả' || p.status.name == _statusFilter;
          return matchesName && matchesStatus;
        }).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredProjects.length,
      itemBuilder: (context, index) {
        final project = filteredProjects[index];
        return _buildProjectCard(project);
      },
    );
  }

  Widget _buildProjectCard(ProjectModel project) {
    Color statusColor;
    String statusLabel;

    switch (project.status) {
      case ProjectStatus.DRAFT:
        statusColor = Colors.grey;
        statusLabel = 'Nháp';
        break;
      case ProjectStatus.IN_PROGRESS:
        statusColor = Colors.blue;
        statusLabel = 'Đang thực hiện';
        break;
      case ProjectStatus.COMPLETED:
        statusColor = Colors.green;
        statusLabel = 'Hoàn thành';
        break;
      case ProjectStatus.CANCELLED:
        statusColor = Colors.red;
        statusLabel = 'Đã hủy';
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          project.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              project.description?.isNotEmpty ?? false
                  ? project.description!
                  : 'Không có mô tả',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF137FEC)),
              onPressed: () => openEditProjectScreen(project),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => handleDeleteProject(project),
            ),
          ],
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
