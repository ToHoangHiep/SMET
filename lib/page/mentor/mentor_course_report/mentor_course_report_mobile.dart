import 'package:flutter/material.dart';

/// Mentor Course Report - Mobile Version
class MentorCourseReportMobile extends StatelessWidget {
  const MentorCourseReportMobile({super.key});

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
      bottomNavigationBar: const _MobileBottomNav(),
      body: SafeArea(
        child: Column(
          children: [
            const _MobileAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const _MobileHeroSection(),
                    const SizedBox(height: 20),
                    const _MobileSearchFilterBar(),
                    const SizedBox(height: 24),
                    const Text(
                      'Danh sách khóa học',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff181C22),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: courses.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _MobileCourseCard(data: courses[index]);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileAppBar extends StatelessWidget {
  const _MobileAppBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuC50AkjtY3IIVdLQQ0hc27LDwo1EFdLLwaSD20EM6N-4XTFTpH_5FlJ51YTfwE_21GB2-s3kSnoWbmW_H8IRxzvuW4HirszWFqshR16-DOU-BCG2qT9Obmoyd3uXY-eXUDgSgN5tzjU5SyQUGZi2pqZw7rAsykW1pdRexvb7cm7CW4J68KWlIY8HwDGhl5SCk16gb7ta2uk9QAchxm9cE1irXjB70pQcCACtIo8kbEXxvGBIEEYFuCVQsRGp25t35sTrB57Qni2c3UV',
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Dr. Minh Tran',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff181C22),
                  ),
                ),
                Text(
                  'Senior Mentor',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xff414753),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
            color: const Color(0xff414753),
          ),
        ],
      ),
    );
  }
}

class _MobileHeroSection extends StatelessWidget {
  const _MobileHeroSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Báo cáo Khóa học',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xff181C22),
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Xem báo cáo chi tiết và phân tích hiệu quả đào tạo.',
          style: TextStyle(
            fontSize: 14,
            color: const Color(0xff414753).withOpacity(0.9),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _MobileSearchFilterBar extends StatelessWidget {
  const _MobileSearchFilterBar();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Tìm kiếm theo tên khóa học...',
            hintStyle: const TextStyle(color: Color(0xff717785), fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: Color(0xff717785)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: const Color(0xffB2CDFD).withOpacity(0.3),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'Tất cả',
                selected: true,
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Đang diễn ra',
                selected: false,
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Đã kết thúc',
                selected: false,
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xff005BAF) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? const Color(0xff005BAF)
                : const Color(0xffB2CDFD).withOpacity(0.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : const Color(0xff414753),
          ),
        ),
      ),
    );
  }
}

class _MobileCourseCard extends StatelessWidget {
  final CourseReportCardData data;

  const _MobileCourseCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                height: 140,
                width: double.infinity,
                child: Image.network(
                  data.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
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
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff181C22),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _InfoBadge(
                      icon: Icons.group_outlined,
                      value: '${data.studentCount} học viên',
                    ),
                    const SizedBox(width: 12),
                    _InfoBadge(
                      icon: Icons.star_outline,
                      value: 'Điểm: ${data.averageScore.toStringAsFixed(1)}',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Tiến độ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xff414753),
                                ),
                              ),
                              Text(
                                '${(data.progress * 100).round()}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff005BAF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: data.progress,
                              minHeight: 5,
                              backgroundColor: const Color(0xffB2CDFD),
                              valueColor: const AlwaysStoppedAnimation(
                                Color(0xff0074DB),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xff005BAF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Chi tiết',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward,
                              size: 14,
                              color: Colors.white,
                            ),
                          ],
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
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String value;

  const _InfoBadge({
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xff414753)),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xff414753),
          ),
        ),
      ],
    );
  }
}

class _MobileBottomNav extends StatelessWidget {
  const _MobileBottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
          ),
          _BottomNavItem(
            icon: Icons.school_outlined,
            label: 'Courses',
          ),
          _BottomNavItem(
            icon: Icons.analytics,
            label: 'Reports',
            active: true,
          ),
          _BottomNavItem(
            icon: Icons.group_outlined,
            label: 'Students',
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        active ? const Color(0xff137FEC) : const Color(0xff414753);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            color: color,
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
