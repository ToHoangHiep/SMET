import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:smet/page/mentor/projects/screen/mentor_projects_web.dart';
import 'package:smet/page/mentor/projects/screen/mentor_projects_mobile.dart';
import 'package:smet/page/mentor/projects/widgets/project_detail_mentor.dart';
import 'package:smet/service/mentor/mentor_project_service.dart';
import 'package:smet/model/project_model.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'dart:developer';

class MentorProjectsPage extends StatefulWidget {
  const MentorProjectsPage({super.key});

  @override
  State<MentorProjectsPage> createState() => _MentorProjectsPageState();
}

class _MentorProjectsPageState extends State<MentorProjectsPage> {
  List<ProjectModel> _projects = [];
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
      final projects = await MentorProjectService.getMyProjects();

      final List<ProjectModel> mentorProjects = [];
      for (final project in projects) {
        if (project.mentorId != null) {
          final projectDetail = await MentorProjectService.getProjectById(project.id);
          if (projectDetail.mentorId != null) {
            mentorProjects.add(project);
          }
        }
      }

      if (mounted) {
        setState(() {
          _projects = mentorProjects;
          _isLoading = false;
        });
      }
    } catch (e) {
      log('MentorProjectsPage._loadProjects failed: $e');
      if (mounted) {
        setState(() {
          _error = 'Khong the tai danh sach du an';
          _isLoading = false;
        });
      }
    }
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MentorProjectDetailDialog(
        project: project,
        onRefresh: _loadProjects,
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
              BreadcrumbItem(label: 'Trang chu', route: '/mentor/dashboard'),
              BreadcrumbItem(label: 'Du an huong dan'),
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
      return MentorProjectsWeb(
        projects: _filteredProjects,
        onProjectTap: _onProjectTap,
        onSearchChanged: _onSearchChanged,
        onStatusFilterChanged: _onStatusFilterChanged,
        selectedStatus: _filterStatus,
        onRefresh: _loadProjects,
      );
    }

    return MentorProjectsMobile(
      projects: _filteredProjects,
      onProjectTap: _onProjectTap,
      onSearchChanged: _onSearchChanged,
      onStatusFilterChanged: _onStatusFilterChanged,
      selectedStatus: _filterStatus,
      onRefresh: _loadProjects,
    );
  }
}