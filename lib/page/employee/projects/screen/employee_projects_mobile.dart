import 'package:flutter/material.dart';
import 'package:smet/page/employee/projects/widgets/project_list_table.dart';
import 'package:smet/model/project_model.dart';
import 'package:smet/model/project_member_model.dart';

class EmployeeProjectsMobile extends StatelessWidget {
  final List<ProjectModel> projects;
  final Map<int, ProjectMemberRole> projectRoles;
  final Function(ProjectModel) onProjectTap;
  final Function(String) onSearchChanged;
  final Function(ProjectStatus?) onStatusFilterChanged;
  final ProjectStatus? selectedStatus;
  final VoidCallback onRefresh;

  const EmployeeProjectsMobile({
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
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Du an cua toi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
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
                  fillColor: const Color(0xFFF5F7FA),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: onSearchChanged,
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStatusChip(null, 'Tat ca'),
                    ...ProjectStatus.values.map((status) {
                      return _buildStatusChip(status, status.label);
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: projects.isEmpty
              ? _buildEmptyState()
              : ProjectListTable(
                  projects: projects,
                  projectRoles: projectRoles,
                  onProjectTap: onProjectTap,
                  isWeb: false,
                ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(ProjectStatus? status, String label) {
    final isSelected = selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onStatusFilterChanged(status),
        selectedColor: const Color(0xFF137FEC).withOpacity(0.2),
        checkmarkColor: const Color(0xFF137FEC),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF137FEC) : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
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
            'Ban chua tham gia du an nao',
            style: TextStyle(
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}