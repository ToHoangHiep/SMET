import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';

/// Mentor Course Report - Web Version
class MentorCourseReportWeb extends StatelessWidget {
  const MentorCourseReportWeb({super.key});

  @override
  Widget build(BuildContext context) {
    final courses = [
      CourseReportCardData(
        title: 'Thiết kế UI/UX Nâng cao 2024',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDPeuw70DzLZsXlQ-CMe6UfGJHCOJj9p5fKOeMHgA5bDz7Xpu90ZaitpzXYWlCzauuuCQU1k3xoZkcon-uMdP2RxQqO-eKlvbfi3kVowS0uGpu1P2b2EWRkWFJp_NnOw1bRRSjgeqsrD4AGW36uhFh3J0NlTuEutD0Mn1cj8zMB4xhYFpVomZ2z41dL6Sq7fbDjr9t9G6thVcrTWu906tZn-tA8_j89NAaNQP6GZUW5G6lENgjtQ2mAUH90eoQoMho8Xq5cEUh-sURT',
        studentCount: 120,
        progress: 0.75,
        averageScore: 8.2,
        status: 'Đang diễn ra',
        active: true,
      ),
      CourseReportCardData(
        title: 'Lập trình Frontend cơ bản',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuC8_xX4Cs4R65Ng_dMmc2PmxFoktwk7fa1UQd2ClyUXVvu2gEeq0i1fRx4hXfrulXkSVilSZ9KtrqjHaOsdbS3ahpOdqUgC6jHATw-YcbjS0ERwaYtgf9YIndeZLkd2RnpJqU5VBbMew5yTmTiWd3Zr7nE_1tm2jOK_enNZsFopvnL-w-Lt-8YZhceqTTGZdgHPRWwJRHZw1zDuVeCsPEL9xuBvN5NRGwX6JAmTt-BhXRhK8AOBu27QarNcQ1gF4tC17gJ2OcfRnEAL',
        studentCount: 85,
        progress: 0.42,
        averageScore: 7.5,
        status: 'Đang diễn ra',
        active: true,
      ),
      CourseReportCardData(
        title: 'Quản lý dự án Agile',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAg9uaiFnN7IaGWPgL41mPQYe0CCoAgGco_m8Jcgf32eEClBhRmbEK5ObELq3ODvH8UogBM9lxINBvgQtjyLiBaUPUO2oiBLmqSFN6O5sF6yJL_-3Vh2t0NYo5KsJclFlrTg7jqGCVTlWqHDQnEHYG0mAynWWOLOgooQgmkIRw9kdI6GMiO06AFUrdTQwYJI_PLCxJQP_EuOgkPDjWoF9DmmaWkFSxrRFdSsP4fLkdlzRwSclw4WB7uBODfViw_iXwY-2w9ZSilEQtO',
        studentCount: 45,
        progress: 1.0,
        averageScore: 9.0,
        status: 'Đã kết thúc',
        active: false,
      ),
      CourseReportCardData(
        title: 'Khoa học dữ liệu với Python',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAWt6H-4FdFQjpMN7nUwXaWHp7uHR01_xTeuwo0fzYCwfUzEbIU9VeRE86y8xXkaY1RuZmzo1sqB2XzeE6VOT7T9mTL1byaj9TjFsydahVFjxzeRGuJV5gIOReVbW7zoAfuIi9GiMlXut08YXKCNBJZGJlTbHJa8HNQjM85UDpiAi-mzW7X1MUUuegOF4_igLEfhn5pczGV25mwAfrJ4Dc11yHRTc9-wlansep7xb5aCOsN6NxapkNqLYx3AGCMO3X_q-ZHwcpNyD0L',
        studentCount: 62,
        progress: 0.28,
        averageScore: 7.8,
        status: 'Đang diễn ra',
        active: true,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xffF9F9FF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(30, 30, 30, 0),
              child: BreadcrumbPageHeader(
                pageTitle: 'Báo cáo Khóa học',
                pageIcon: Icons.assessment_rounded,
                breadcrumbs: const [
                  BreadcrumbItem(label: 'Tổng quan', route: '/mentor/dashboard'),
                  BreadcrumbItem(label: 'Báo cáo'),
                ],
                primaryColor: const Color(0xFF6366F1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 28),
                      _PageContent(courses: courses),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  final List<CourseReportCardData> courses;

  const _PageContent({required this.courses});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _HeroSection(),
        const SizedBox(height: 28),
        const _SearchFilterBar(),
        const SizedBox(height: 32),
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 1;
            if (constraints.maxWidth >= 1100) {
              crossAxisCount = 3;
            } else if (constraints.maxWidth >= 700) {
              crossAxisCount = 2;
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: courses.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 0.76,
              ),
              itemBuilder: (context, index) {
                return _CourseReportCard(data: courses[index]);
              },
            );
          },
        ),
      ],
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Báo cáo Khóa học của Tôi',
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w800,
            color: Color(0xff181C22),
            height: 1.1,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Chọn một khóa học để xem báo cáo chi tiết và phân tích hiệu quả đào tạo.',
          style: TextStyle(
            fontSize: 18,
            color: Color(0xff414753),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _SearchFilterBar extends StatelessWidget {
  const _SearchFilterBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xffF1F3FD),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Expanded(
            child: SizedBox(
              width: 500,
              child: _CourseSearchField(),
            ),
          ),
          const SizedBox(width: 20),
          const SizedBox(
            width: 220,
            child: _StatusDropdown(),
          ),
        ],
      ),
    );
  }
}

class _CourseSearchField extends StatelessWidget {
  const _CourseSearchField();

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Tìm kiếm theo tên khóa học...',
        hintStyle: const TextStyle(color: Color(0xff717785)),
        prefixIcon: const Icon(Icons.search, color: Color(0xff717785)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown();

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: null,
      decoration: InputDecoration(
        hintText: 'Trạng thái',
        hintStyle: const TextStyle(color: Color(0xff181C22)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      items: const [
        DropdownMenuItem(
          value: 'active',
          child: Text('Đang diễn ra'),
        ),
        DropdownMenuItem(
          value: 'finished',
          child: Text('Đã kết thúc'),
        ),
      ],
      onChanged: (value) {},
      icon: const Icon(Icons.filter_list, color: Color(0xff717785)),
    );
  }
}

class _CourseReportCard extends StatelessWidget {
  final CourseReportCardData data;

  const _CourseReportCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xffffffff),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 190,
                width: double.infinity,
                child: Image.network(
                  data.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: data.active
                        ? const Color(0xff005BAF)
                        : const Color(0xff717785),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    data.status.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff181C22),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _infoRow(
                    Icons.group_outlined,
                    'Số học viên:',
                    '${data.studentCount}',
                  ),
                  const SizedBox(height: 12),
                  _infoRow(
                    Icons.trending_up,
                    'Tiến độ TB:',
                    '${(data.progress * 100).round()}%',
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: data.progress,
                      minHeight: 6,
                      backgroundColor: const Color(0xffB2CDFD),
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xff0074DB),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _infoRow(
                    Icons.star_outline,
                    'Điểm TB:',
                    data.averageScore.toStringAsFixed(1),
                    valueColor: const Color(0xff005BAF),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.go('/mentor/course-report-detail?courseId=${data.title}');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff005BAF),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const StadiumBorder(),
                      ),
                      iconAlignment: IconAlignment.end,
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text(
                        'Xem báo cáo chi tiết',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    Color valueColor = const Color(0xff181C22),
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xff414753)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xff414753),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class CourseReportCardData {
  final String title;
  final String imageUrl;
  final int studentCount;
  final double progress;
  final double averageScore;
  final String status;
  final bool active;

  CourseReportCardData({
    required this.title,
    required this.imageUrl,
    required this.studentCount,
    required this.progress,
    required this.averageScore,
    required this.status,
    required this.active,
  });
}
