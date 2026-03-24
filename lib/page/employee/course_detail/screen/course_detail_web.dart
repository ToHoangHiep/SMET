import 'package:flutter/material.dart';
import 'package:smet/page/employee/widgets/shell/employee_top_header.dart';
import 'package:smet/page/sidebar/shared_sidebar.dart';
import 'package:smet/page/sidebar/sidebar_menu_item.dart';

class CourseDetailWeb extends StatelessWidget {
  final Widget hero;
  final Widget syllabus;
  final Widget instructor;
  final Widget reviews;
  final Widget enrollCard;
  final List<SidebarMenuItem> menuItems;
  final Function(String) onNavigate;
  final VoidCallback onLogout;
  final List<BreadcrumbItem>? breadcrumbs;

  const CourseDetailWeb({
    super.key,
    required this.hero,
    required this.syllabus,
    required this.instructor,
    required this.reviews,
    required this.enrollCard,
    required this.menuItems,
    required this.onNavigate,
    required this.onLogout,
    this.breadcrumbs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SharedSidebar(
          primaryColor: const Color(0xFF137FEC),
          logoIcon: Icons.school,
          logoText: 'SMETS',
          subtitle: 'EMPLOYEE PORTAL',
          menuItems: menuItems,
          activeRoute: '/employee/courses',
          userDisplayName: 'Employee',
          userRole: 'Nhân viên',
          onLogout: onLogout,
          onProfileTap: () => onNavigate('/profile'),
        ),
        Expanded(
          child: Column(
            children: [
              EmployeeTopHeader(
                currentPage: 'Chi tiết khóa học',
                breadcrumbs: breadcrumbs,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      hero,
                      const SizedBox(height: 32),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                syllabus,
                                const SizedBox(height: 32),
                                instructor,
                                const SizedBox(height: 32),
                                reviews,
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          SizedBox(
                            width: 340,
                            child: Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.08,
                                        ),
                                        blurRadius: 20,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: enrollCard,
                                ),
                                const SizedBox(height: 24),
                                _buildSupportCard(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSupportCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Column(
        children: [
          Icon(Icons.help_outline, size: 32, color: Color(0xFF137FEC)),
          SizedBox(height: 12),
          Text(
            'Cần đào tạo doanh nghiệp?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Nhận báo giá riêng cho toàn bộ đội ngũ của bạn.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            'Liên hệ hỗ trợ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF137FEC),
            ),
          ),
        ],
      ),
    );
  }
}
