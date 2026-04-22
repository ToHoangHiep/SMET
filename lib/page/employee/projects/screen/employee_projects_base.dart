import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:smet/page/employee/projects/screen/employee_projects_web.dart';
import 'package:smet/page/employee/projects/screen/employee_projects_mobile.dart';
import 'package:smet/page/employee/projects/widgets/project_detail_lead.dart';
import 'package:smet/page/employee/projects/widgets/project_detail_member.dart';
import 'package:smet/service/employee/employee_project_service.dart';
import 'package:smet/service/common/auth_service.dart';
import 'package:smet/model/project_model.dart';
import 'package:smet/model/project_member_model.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';

class EmployeeProjectsPage extends StatefulWidget {
  const EmployeeProjectsPage({super.key});

  @override
  State<EmployeeProjectsPage> createState() => _EmployeeProjectsPageState();
}

class _EmployeeProjectsPageState extends State<EmployeeProjectsPage> {
  List<ProjectModel> _projects = [];
  Map<int, ProjectMemberRole> _projectRoles = {};
  bool _isLoading = true;
  String? _error;
  String _searchKeyword = '';
  ProjectStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final projects = await EmployeeProjectService.getMyProjects();
      final userId = (await AuthService.getCurrentUser()).id;

      final Map<int, ProjectMemberRole> roles = {};
      for (final project in projects) {
        final role = await _determineRole(project, userId);
        if (role != null) {
          roles[project.id] = role;
        }
      }

      if (mounted) {
        setState(() {
          _projects = projects;
          _projectRoles = roles;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading projects: $e');
      if (mounted) {
        setState(() {
          _error = 'Khong the tai danh sach du an';
          _isLoading = false;
        });
      }
    }
  }

  Future<ProjectMemberRole?> _determineRole(
    ProjectModel project,
    int userId,
  ) async {
    if (project.leaderId == userId) {
      return ProjectMemberRole.PROJECT_LEAD;
    }
    if (project.mentorId == userId) {
      return ProjectMemberRole.PROJECT_MENTOR;
    }
    if (project.memberIds != null && project.memberIds!.contains(userId)) {
      return ProjectMemberRole.PROJECT_MEMBER;
    }
    return null;
  }

  List<ProjectModel> get _filteredProjects {
    var filtered = _projects;

    if (_searchKeyword.isNotEmpty) {
      filtered = filtered.where((p) {
        return p.title.toLowerCase().contains(_searchKeyword.toLowerCase()) ||
            (p.description?.toLowerCase().contains(_searchKeyword.toLowerCase()) ?? false);
      }).toList();
    }

    if (_filterStatus != null) {
      filtered = filtered.where((p) => p.status == _filterStatus).toList();
    }

    return filtered;
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchKeyword = value;
    });
  }

  void _onStatusFilterChanged(ProjectStatus? status) {
    setState(() {
      _filterStatus = status;
    });
  }

  void _onProjectTap(ProjectModel project) {
    final role = _projectRoles[project.id];
    if (role == null) return;

    if (role == ProjectMemberRole.PROJECT_LEAD) {
      _showLeadDetail(project);
    } else if (role == ProjectMemberRole.PROJECT_MEMBER) {
      _showMemberDetail(project);
    }
  }

  void _showLeadDetail(ProjectModel project) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProjectDetailLeadDialog(
        project: project,
        onRefresh: _loadProjects,
      ),
    );
  }

  void _showMemberDetail(ProjectModel project) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProjectDetailMemberDialog(
        project: project,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb || MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          SharedBreadcrumb(
            items: [
              BreadcrumbItem(label: 'Trang chu', route: '/employee/dashboard'),
              BreadcrumbItem(label: 'Du an cua toi'),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorState()
                    : _buildContent(isWeb),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error ?? 'Da xay ra loi'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadProjects,
            child: const Text('Thu lai'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isWeb) {
    if (isWeb) {
      return EmployeeProjectsWeb(
        projects: _filteredProjects,
        projectRoles: _projectRoles,
        onProjectTap: _onProjectTap,
        onSearchChanged: _onSearchChanged,
        onStatusFilterChanged: _onStatusFilterChanged,
        selectedStatus: _filterStatus,
        onRefresh: _loadProjects,
      );
    }

    return EmployeeProjectsMobile(
      projects: _filteredProjects,
      projectRoles: _projectRoles,
      onProjectTap: _onProjectTap,
      onSearchChanged: _onSearchChanged,
      onStatusFilterChanged: _onStatusFilterChanged,
      selectedStatus: _filterStatus,
      onRefresh: _loadProjects,
    );
  }
}