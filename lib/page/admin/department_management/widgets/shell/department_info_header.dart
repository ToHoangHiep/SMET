import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/department_model.dart';

class DepartmentInfoHeader extends StatelessWidget {
  final DepartmentModel department;
  final Color primaryColor;

  const DepartmentInfoHeader({
    super.key,
    required this.department,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBreadcrumb(context),
        const SizedBox(height: 20),
        _buildDepartmentCard(context),
      ],
    );
  }

  Widget _buildBreadcrumb(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _BreadcrumbItem(
          label: 'Trang chủ',
          onTap: () => context.go('/home'),
          primaryColor: primaryColor,
        ),
        const SizedBox(width: 4),
        Icon(
          Icons.chevron_right,
          size: 16,
          color: Colors.grey[400],
        ),
        const SizedBox(width: 4),
        _BreadcrumbItem(
          label: 'Quản lý phòng ban',
          onTap: () => context.go('/department_management'),
          primaryColor: primaryColor,
        ),
        const SizedBox(width: 4),
        Icon(
          Icons.chevron_right,
          size: 16,
          color: Colors.grey[400],
        ),
        const SizedBox(width: 4),
        _BreadcrumbItem(
          label: department.name,
          isLast: true,
          primaryColor: primaryColor,
        ),
      ],
    );
  }

  Widget _buildDepartmentCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor,
                      primaryColor.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.business,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      department.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            department.code,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: department.isActive
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            department.isActive
                                ? 'Đang hoạt động'
                                : 'Không hoạt động',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: department.isActive
                                  ? Colors.green[700]
                                  : Colors.red[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.person_outline,
            'Quản lý',
            department.projectManagerName ?? 'Chưa có',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.confirmation_number_outlined,
            'Mã phòng ban',
            department.code,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: primaryColor.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _BreadcrumbItem extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLast;
  final Color primaryColor;

  const _BreadcrumbItem({
    required this.label,
    this.onTap,
    this.isLast = false,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    if (isLast || onTap == null) {
      return Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
          color: isLast ? primaryColor : Colors.grey[600],
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
