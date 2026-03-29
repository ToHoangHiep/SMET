import 'package:flutter/material.dart';
import 'package:smet/page/employee/widgets/shell/employee_top_header.dart';

class CourseDetailWeb extends StatelessWidget {
  final Widget hero;
  final Widget courseStats;
  final Widget syllabus;
  final Widget instructor;
  final Widget reviews;
  final Widget enrollCard;
  final Widget offeredBy;
  final Widget courseInfoCard;
  final List<BreadcrumbItem>? breadcrumbs;

  const CourseDetailWeb({
    super.key,
    required this.hero,
    required this.courseStats,
    required this.syllabus,
    required this.instructor,
    required this.reviews,
    required this.enrollCard,
    required this.offeredBy,
    required this.courseInfoCard,
    this.breadcrumbs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
                // ─── Hero ───
                hero,
                const SizedBox(height: 24),

                // ─── Stats row ───
                courseStats,
                const SizedBox(height: 32),

                // ─── 2-column layout ───
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Left column (main content) ───
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Offered by
                          offeredBy,
                          const SizedBox(height: 32),

                          // Syllabus
                          syllabus,
                          const SizedBox(height: 32),

                          // Instructor
                          instructor,
                          const SizedBox(height: 32),

                          // Reviews
                          reviews,
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),

                    const SizedBox(width: 24),

                    // ─── Right column (sticky sidebar) ───
                    SizedBox(
                      width: 360,
                      child: Column(
                        children: [
                          // Enroll card — sticky
                          _StickyEnrollCard(enrollCard: enrollCard),
                          const SizedBox(height: 16),

                          // Course info card
                          courseInfoCard,
                          const SizedBox(height: 24),

                          // Support card
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

/// Wraps the enroll card with a sticky Positioned wrapper
/// using a MediaQuery-based scroll offset.
class _StickyEnrollCard extends StatelessWidget {
  final Widget enrollCard;

  const _StickyEnrollCard({required this.enrollCard});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: enrollCard,
    );
  }
}
