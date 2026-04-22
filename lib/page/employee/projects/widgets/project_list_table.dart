import 'package:flutter/material.dart';
import 'package:smet/model/project_model.dart';
import 'package:smet/model/project_member_model.dart';

class ProjectListTable extends StatelessWidget {
  final List<ProjectModel> projects;
  final Map<int, ProjectMemberRole> projectRoles;
  final Function(ProjectModel) onProjectTap;
  final bool isWeb;

  const ProjectListTable({
    super.key,
    required this.projects,
    required this.projectRoles,
    required this.onProjectTap,
    required this.isWeb,
  });

  @override
  Widget build(BuildContext context) {
    if (isWeb) {
      return _buildWebTable(context);
    }
    return _buildMobileList(context);
  }

  Widget _buildWebTable(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          const Divider(height: 1),
          ...projects.asMap().entries.map((entry) {
            return _buildTableRow(entry.key + 1, entry.value);
          }),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 48, child: Text('#', style: _headerStyle)),
          Expanded(flex: 3, child: Text('Ten du an', style: _headerStyle)),
          Expanded(flex: 2, child: Text('Trang thai', style: _headerStyle)),
          Expanded(flex: 2, child: Text('Vai tro', style: _headerStyle)),
          Expanded(flex: 2, child: Text('Thao tac', style: _headerStyle)),
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 13,
    color: Color(0xFF64748B),
  );

  Widget _buildTableRow(int index, ProjectModel project) {
    final role = projectRoles[project.id];
    return InkWell(
      onTap: () => onProjectTap(project),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  if (project.description != null && project.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        project.description!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(flex: 2, child: _buildStatusBadge(project.status)),
            Expanded(flex: 2, child: _buildRoleBadge(role)),
            Expanded(
              flex: 2,
              child: TextButton(
                onPressed: () => onProjectTap(project),
                child: const Text(
                  'Xem chi tiet',
                  style: TextStyle(
                    color: Color(0xFF137FEC),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileList(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: projects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final project = projects[index];
        final role = projectRoles[project.id];
        return _buildMobileCard(project, role);
      },
    );
  }

  Widget _buildMobileCard(ProjectModel project, ProjectMemberRole? role) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onProjectTap(project),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    _buildRoleBadge(role),
                  ],
                ),
                if (project.description != null && project.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      project.description!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatusBadge(project.status),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0xFF94A3B8),
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

  Widget _buildStatusBadge(ProjectStatus status) {
    Color color;
    switch (status) {
      case ProjectStatus.ACTIVE:
        color = const Color(0xFF22C55E);
        break;
      case ProjectStatus.COMPLETED:
        color = const Color(0xFF137FEC);
        break;
      case ProjectStatus.INACTIVE:
        color = const Color(0xFF94A3B8);
        break;
      case ProjectStatus.REVIEW_PENDING:
        color = const Color(0xFFF59E0B);
        break;
    }

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          status.label,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(ProjectMemberRole? role) {
    if (role == null) return const SizedBox();

    IconData icon;
    Color color;
    String label;

    switch (role) {
      case ProjectMemberRole.PROJECT_LEAD:
        icon = Icons.star;
        color = const Color(0xFFF59E0B);
        label = 'Truong nhom';
        break;
      case ProjectMemberRole.PROJECT_MENTOR:
        icon = Icons.school;
        color = const Color(0xFF8B5CF6);
        label = 'Nguoi huong dan';
        break;
      case ProjectMemberRole.PROJECT_MEMBER:
        icon = Icons.person;
        color = const Color(0xFF94A3B8);
        label = 'Thanh vien';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}