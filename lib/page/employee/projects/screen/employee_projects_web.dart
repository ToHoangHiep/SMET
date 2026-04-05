import 'package:flutter/material.dart';
import 'package:smet/page/employee/projects/widgets/project_list_table.dart';
import 'package:smet/model/project_model.dart';
import 'package:smet/model/project_member_model.dart';

class EmployeeProjectsWeb extends StatelessWidget {
  final List<ProjectModel> projects;
  final Map<int, ProjectMemberRole> projectRoles;
  final Function(ProjectModel) onProjectTap;
  final Function(String) onSearchChanged;
  final Function(ProjectStatus?) onStatusFilterChanged;
  final ProjectStatus? selectedStatus;
  final VoidCallback onRefresh;

  const EmployeeProjectsWeb({
    super.key,
    required this.projects,
    required this.projectRoles,
    required this.onProjectTap,
    required this.onSearchChanged,
    required this.onStatusFilterChanged,
    required this.selectedStatus,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Du an cua toi',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF137FEC).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${projects.length} du an',
                  style: const TextStyle(
                    color: Color(0xFF137FEC),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildFilterBar(context),
          const SizedBox(height: 16),
          Expanded(
            child: projects.isEmpty
                ? _buildEmptyState()
                : ProjectListTable(
                    projects: projects,
                    projectRoles: projectRoles,
                    onProjectTap: onProjectTap,
                    isWeb: true,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Tim kiem du an...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF137FEC), width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: onSearchChanged,
          ),
        ),
        const SizedBox(width: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ProjectStatus?>(
              value: selectedStatus,
              hint: const Text('Loc trang thai'),
              items: [
                const DropdownMenuItem<ProjectStatus?>(
                  value: null,
                  child: Text('Tat ca trang thai'),
                ),
                ...ProjectStatus.values.map((status) {
                  return DropdownMenuItem<ProjectStatus>(
                    value: status,
                    child: Text(status.label),
                  );
                }),
              ],
              onChanged: onStatusFilterChanged,
            ),
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          tooltip: 'Lam moi',
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Chua co du an nao',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ban chua tham gia du an nao hoac chua co du an nao trong he thong',
            style: TextStyle(
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}