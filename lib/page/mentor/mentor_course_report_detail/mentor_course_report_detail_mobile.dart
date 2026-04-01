import 'package:flutter/material.dart';

/// Mentor Course Report Detail - Mobile Version
class MentorCourseReportDetailMobile extends StatelessWidget {
  final String? courseId;

  const MentorCourseReportDetailMobile({super.key, this.courseId});

  @override
  Widget build(BuildContext context) {
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
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16),
                    _ReportHeaderMobile(),
                    SizedBox(height: 20),
                    _ExportButtonsMobile(),
                    SizedBox(height: 20),
                    _KpiCardsMobile(),
                    SizedBox(height: 20),
                    _WeeklyChartMobile(),
                    SizedBox(height: 20),
                    _StudentSectionMobile(),
                    SizedBox(height: 20),
                    _FooterMobile(),
                    SizedBox(height: 24),
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
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            color: const Color(0xff181C22),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Chi tiết báo cáo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff181C22),
                  ),
                ),
                Text(
                  'Thiết kế UI/UX Nâng cao (2024)',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xff64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
            color: const Color(0xff64748B),
          ),
        ],
      ),
    );
  }
}

class _ReportHeaderMobile extends StatelessWidget {
  const _ReportHeaderMobile();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xffD1FAE5),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'ĐANG DIỄN RA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff047857),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Báo cáo Chi tiết: Thiết kế UI/UX Nâng cao (2024)',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xff181C22),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.school_outlined, size: 16, color: Color(0xff64748B)),
            const SizedBox(width: 6),
            const Text(
              'Lớp: ',
              style: TextStyle(fontSize: 13, color: Color(0xff64748B)),
            ),
            const Text(
              'UIUX-ADV-01',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xff181C22),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.person_outline, size: 16, color: Color(0xff64748B)),
            const SizedBox(width: 6),
            const Text(
              'Mentor: ',
              style: TextStyle(fontSize: 13, color: Color(0xff64748B)),
            ),
            const Text(
              'Trần Hoàng Minh',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xff181C22),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ExportButtonsMobile extends StatelessWidget {
  const _ExportButtonsMobile();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.file_download_outlined, size: 18),
            label: const Text('Xuất Excel'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xff181C22),
              side: BorderSide.none,
              backgroundColor: const Color(0xffE0E2EC),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: const Text('Xuất PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff137FEC),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _KpiCardsMobile extends StatelessWidget {
  const _KpiCardsMobile();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCardMobile(
                icon: Icons.group_outlined,
                iconBg: const Color(0xffEFF6FF),
                iconColor: const Color(0xff137FEC),
                title: 'Học viên',
                value: '450',
                badgeText: 'Ổn định',
                badgeBg: const Color(0xffECFDF5),
                badgeColor: const Color(0xff059669),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCardMobile(
                icon: Icons.task_alt_outlined,
                iconBg: const Color(0xffF3E8FF),
                iconColor: const Color(0xff9333EA),
                title: 'Nộp bài tập',
                value: '92.8%',
                badgeText: '+4.2%',
                badgeBg: const Color(0xffECFDF5),
                badgeColor: const Color(0xff059669),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _KpiCardMobile(
                icon: Icons.grade_outlined,
                iconBg: const Color(0xffFFFBEB),
                iconColor: const Color(0xffD97706),
                title: 'Điểm TB Quiz',
                value: '8.9',
                badgeText: '+0.5',
                badgeBg: const Color(0xffECFDF5),
                badgeColor: const Color(0xff059669),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCardMobile(
                icon: Icons.schedule_outlined,
                iconBg: const Color(0xffECFEFF),
                iconColor: const Color(0xff0891B2),
                title: 'Giờ học/tuần',
                value: '12.5h',
                badgeText: 'Sáng',
                badgeBg: const Color(0xffECFDF5),
                badgeColor: const Color(0xff059669),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiCardMobile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String value;
  final String badgeText;
  final Color badgeBg;
  final Color badgeColor;

  const _KpiCardMobile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.badgeText,
    required this.badgeBg,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xff64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              color: Color(0xff137FEC),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyChartMobile extends StatelessWidget {
  const _WeeklyChartMobile();

  @override
  Widget build(BuildContext context) {
    final weekBars = [
      _WeekBarData('T1', 52, 48, false),
      _WeekBarData('T2', 56, 50, false),
      _WeekBarData('T3', 48, 42, false),
      _WeekBarData('T4', 60, 54, false),
      _WeekBarData('T5', 44, 38, false),
      _WeekBarData('T6', 64, 56, true),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xffF1F3FD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tiến độ bài học theo tuần',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xff181C22),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tuần 6 / 12 tuần',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xff64748B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              _LegendDot(color: Color(0xff137FEC), label: 'Đúng hạn'),
              SizedBox(width: 12),
              _LegendDot(color: Color(0xffB2CDFD), label: 'Chưa xong'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weekBars
                  .map((e) => Expanded(child: _WeekBarWidget(data: e)))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _WeekBarData {
  final String label;
  final double totalHeightFactor;
  final double filledHeightFactor;
  final bool highlighted;

  _WeekBarData(
    this.label,
    this.totalHeightFactor,
    this.filledHeightFactor,
    this.highlighted,
  );
}

class _WeekBarWidget extends StatelessWidget {
  final _WeekBarData data;

  const _WeekBarWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    const maxHeight = 140.0;

    final totalHeight = maxHeight * (data.totalHeightFactor / 64);
    final filledHeight = maxHeight * (data.filledHeightFactor / 64);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: totalHeight,
            decoration: BoxDecoration(
              color: const Color(0xffB2CDFD),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              border: data.highlighted
                  ? Border.all(
                      color: const Color(0xff137FEC).withOpacity(0.2),
                      width: 2,
                    )
                  : null,
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: filledHeight,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff137FEC), Color(0xff005BAF)],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: data.highlighted
                  ? const Color(0xff137FEC)
                  : const Color(0xff64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentSectionMobile extends StatelessWidget {
  const _StudentSectionMobile();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Học viên tiêu biểu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff181C22),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Dựa trên điểm số và tiến độ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xff64748B),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Tải .csv',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xff137FEC),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _StudentCardMobile(
          initials: 'TH',
          initialsBg: Color(0xffD1FAE5),
          initialsColor: Color(0xff047857),
          name: 'Trần Thị Hoa',
          email: 'hoa.tt@student.smets.vn',
          module: '#06 High-fidelity Prototyping',
          progress: 1.0,
          progressText: '100% hoàn thành',
          progressColor: Color(0xff137FEC),
          gpa: '9.2',
          status: 'Xuất sắc',
          statusBg: Color(0xffECFDF5),
          statusColor: Color(0xff047857),
        ),
        const SizedBox(height: 12),
        const _StudentCardMobile(
          initials: 'NV',
          initialsBg: Color(0xffDBEAFE),
          initialsColor: Color(0xff137FEC),
          name: 'Nguyễn Văn An',
          email: 'an.nv@student.smets.vn',
          module: '#06 High-fidelity Prototyping',
          progress: 0.82,
          progressText: '82% hoàn thành',
          progressColor: Color(0xff64748B),
          gpa: '8.5',
          status: 'Đúng tiến độ',
          statusBg: Color(0xffEFF6FF),
          statusColor: Color(0xff137FEC),
        ),
        const SizedBox(height: 12),
        const _StudentCardMobile(
          initials: 'LM',
          initialsBg: Color(0xffFEE2E2),
          initialsColor: Color(0xffB91C1C),
          name: 'Lê Minh',
          email: 'minh.le@student.smets.vn',
          module: '#05 Auto Layout Patterns',
          progress: 0.45,
          progressText: '45% (Chậm tiến độ)',
          progressColor: Color(0xffDC2626),
          progressBarColor: Color(0xffF87171),
          gpa: '6.8',
          status: 'Cần hỗ trợ',
          statusBg: Color(0xffFEF2F2),
          statusColor: Color(0xffB91C1C),
        ),
      ],
    );
  }
}

class _StudentCardMobile extends StatelessWidget {
  final String initials;
  final Color initialsBg;
  final Color initialsColor;
  final String name;
  final String email;
  final String module;
  final double progress;
  final String progressText;
  final Color progressColor;
  final Color progressBarColor;
  final String gpa;
  final String status;
  final Color statusBg;
  final Color statusColor;

  const _StudentCardMobile({
    required this.initials,
    required this.initialsBg,
    required this.initialsColor,
    required this.name,
    required this.email,
    required this.module,
    required this.progress,
    required this.progressText,
    required this.progressColor,
    this.progressBarColor = const Color(0xff137FEC),
    required this.gpa,
    required this.status,
    required this.statusBg,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: initialsBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: initialsColor,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xff181C22),
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xff64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    gpa,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xff137FEC),
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'GPA',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xff64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: const Color(0xffB2CDFD),
                              valueColor:
                                  AlwaysStoppedAnimation(progressBarColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(progress * 100).round()}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: progressColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterMobile extends StatelessWidget {
  const _FooterMobile();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffF1F3FD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffEBEDF7)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff137FEC), Color(0xff005BAF)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'SMETS Learning System',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xff137FEC),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                'Hướng dẫn',
                style: TextStyle(fontSize: 12, color: Color(0xff64748B)),
              ),
              Text(
                'Quy trình chấm bài',
                style: TextStyle(fontSize: 12, color: Color(0xff64748B)),
              ),
              Text(
                'Hỗ trợ',
                style: TextStyle(fontSize: 12, color: Color(0xff64748B)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '© 2024 SMETS Academic Curator.',
            style: TextStyle(fontSize: 11, color: Color(0xff64748B)),
          ),
        ],
      ),
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
        active ? const Color(0xff137FEC) : const Color(0xff64748B);

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
