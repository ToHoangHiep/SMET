import 'package:flutter/material.dart';
import 'package:smet/page/mentor/mentor_dashboard/mentor_sidebar.dart';

/// Mentor Course Report Detail - Web Version
class MentorCourseReportDetailWeb extends StatelessWidget {
  const MentorCourseReportDetailWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF9F9FF),
      body: Row(
        children: [
          const MentorSidebar(selectedIndex: 4),
          Expanded(
            child: Column(
              children: const [
                _TopBar(),
                Expanded(
                  child: _PageBody(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        border: const Border(
          bottom: BorderSide(color: Color(0xffEBEDF7)),
        ),
      ),
      child: Row(
        children: [
          Row(
            children: const [
              Text(
                'Báo cáo',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xff64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 18, color: Color(0xff94A3B8)),
              SizedBox(width: 8),
              Text(
                'Chi tiết khóa học',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xff137FEC),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 260,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xffE0E2EC),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              children: [
                Icon(Icons.search, size: 20, color: Color(0xff717785)),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm học viên...',
                      hintStyle: TextStyle(fontSize: 13),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, color: Color(0xff64748B)),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined, color: Color(0xff64748B)),
          ),
          const SizedBox(width: 8),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xff137FEC), width: 2),
              shape: BoxShape.circle,
            ),
            child: const CircleAvatar(
              backgroundImage: NetworkImage(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuBMARE8j-L-5Yo2qDufUVDn9bmG8NJ3sNGcNjYpH5G-olPNX8lIN0YLj5sDd2OqmAwsiyt36J7VlE-3FsSPvris1pLvK6uVvZhMdf5ou2NmazQnoeGfVBd8lUh1iDJ2a16aYYDgqZfuYAxSRClXG6Y-X3BozbZcjN2A3MbIhv9PYnVXJGfS-9rOElbQC8xaHJ_7MILoMo0czo-SEhkj_h_lIbfGCslq7uAIpn-v2bctmGHt5pQO-PI3EO-qK4X4tbN2pdSsJmZtkzuU',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageBody extends StatelessWidget {
  const _PageBody();

  @override
  Widget build(BuildContext context) {
    final weekBars = [
      _WeekBarData('Tuần 1', 52, 48, false),
      _WeekBarData('Tuần 2', 56, 50, false),
      _WeekBarData('Tuần 3', 48, 42, false),
      _WeekBarData('Tuần 4', 60, 54, false),
      _WeekBarData('Tuần 5', 44, 38, false),
      _WeekBarData('Tuần 6', 64, 56, true),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header report
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(child: _ReportHeaderSection()),
              const SizedBox(width: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.file_download_outlined),
                    label: const Text('Xuất Excel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xff181C22),
                      side: BorderSide.none,
                      backgroundColor: const Color(0xffE0E2EC),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: const StadiumBorder(),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Xuất PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff137FEC),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),

          // KPI cards
          GridView.count(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.45,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              _KpiCard(
                icon: Icons.group_outlined,
                iconBg: Color(0xffEFF6FF),
                iconColor: Color(0xff137FEC),
                title: 'Học viên tham gia',
                value: '450',
                badgeText: 'Ổn định',
                badgeBg: Color(0xffECFDF5),
                badgeColor: Color(0xff059669),
              ),
              _KpiCard(
                icon: Icons.task_alt_outlined,
                iconBg: Color(0xffF3E8FF),
                iconColor: Color(0xff9333EA),
                title: 'Tỷ lệ nộp bài tập',
                value: '92.8%',
                badgeText: '+4.2%',
                badgeBg: Color(0xffECFDF5),
                badgeColor: Color(0xff059669),
              ),
              _KpiCard(
                icon: Icons.grade_outlined,
                iconBg: Color(0xffFFFBEB),
                iconColor: Color(0xffD97706),
                title: 'Điểm trung bình Quiz',
                value: '8.9',
                badgeText: '+0.5',
                badgeBg: Color(0xffECFDF5),
                badgeColor: Color(0xff059669),
              ),
              _KpiCard(
                icon: Icons.schedule_outlined,
                iconBg: Color(0xffECFEFF),
                iconColor: Color(0xff0891B2),
                title: 'Giờ học mỗi tuần',
                value: '12.5h',
                badgeText: 'Sáng',
                badgeBg: Color(0xffECFDF5),
                badgeColor: Color(0xff059669),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Weekly progress chart
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xffF1F3FD),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tiến độ bài học theo tuần',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff181C22),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Khóa học hiện đang ở tuần thứ 6 trên tổng 12 tuần',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xff64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: const [
                        _LegendDot(
                          color: Color(0xff137FEC),
                          label: 'Bài nộp đúng hạn',
                        ),
                        SizedBox(width: 16),
                        _LegendDot(
                          color: Color(0xffB2CDFD),
                          label: 'Chưa hoàn thành',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 280,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: weekBars
                        .map((e) => Expanded(child: _WeekBarWidget(data: e)))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Student table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xffE5E7EB)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Học viên tiêu biểu trong khóa',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff181C22),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Dựa trên điểm số và tốc độ hoàn thành bài tập',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xff64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xffEBEDF7),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Tất cả',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff137FEC),
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Cần chú ý',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Tải danh sách (.csv)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xff137FEC),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xffEBEDF7)),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(
                      const Color(0xffF1F3FD),
                    ),
                    columns: const [
                      DataColumn(label: Text('Tên học viên')),
                      DataColumn(label: Text('Module hiện tại')),
                      DataColumn(label: Text('Tiến độ khóa học')),
                      DataColumn(label: Text('Điểm GPA')),
                      DataColumn(label: Text('Trạng thái')),
                    ],
                    rows: [
                      _studentRow(
                        initials: 'TH',
                        initialsBg: const Color(0xffD1FAE5),
                        initialsColor: const Color(0xff047857),
                        name: 'Trần Thị Hoa',
                        email: 'hoa.tt@student.smets.vn',
                        module: '#06 High-fidelity Prototyping',
                        progress: 1.0,
                        progressText: '100% hoàn thành tuần này',
                        progressColor: const Color(0xff137FEC),
                        gpa: '9.2',
                        status: 'Xuất sắc',
                        statusBg: const Color(0xffECFDF5),
                        statusColor: const Color(0xff047857),
                      ),
                      _studentRow(
                        initials: 'NV',
                        initialsBg: const Color(0xffDBEAFE),
                        initialsColor: const Color(0xff137FEC),
                        name: 'Nguyễn Văn An',
                        email: 'an.nv@student.smets.vn',
                        module: '#06 High-fidelity Prototyping',
                        progress: 0.82,
                        progressText: '82% hoàn thành tuần này',
                        progressColor: const Color(0xff64748B),
                        gpa: '8.5',
                        status: 'Đúng tiến độ',
                        statusBg: const Color(0xffEFF6FF),
                        statusColor: const Color(0xff137FEC),
                      ),
                      _studentRow(
                        initials: 'LM',
                        initialsBg: const Color(0xffFEE2E2),
                        initialsColor: const Color(0xffB91C1C),
                        name: 'Lê Minh',
                        email: 'minh.le@student.smets.vn',
                        module: '#05 Auto Layout Patterns',
                        progress: 0.45,
                        progressText: '45% (Chậm tiến độ)',
                        progressColor: const Color(0xffDC2626),
                        progressBarColor: const Color(0xffF87171),
                        gpa: '6.8',
                        status: 'Cần hỗ trợ',
                        statusBg: const Color(0xffFEF2F2),
                        statusColor: const Color(0xffB91C1C),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xffF1F3FD),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xffEBEDF7)),
            ),
            child: Row(
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xff137FEC), Color(0xff005BAF)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.school,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'SMETS Learning System',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xff137FEC),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Text(
                  'Hướng dẫn Mentor',
                  style: TextStyle(color: Color(0xff64748B)),
                ),
                const SizedBox(width: 24),
                const Text(
                  'Quy trình chấm bài',
                  style: TextStyle(color: Color(0xff64748B)),
                ),
                const SizedBox(width: 24),
                const Text(
                  'Hỗ trợ kỹ thuật',
                  style: TextStyle(color: Color(0xff64748B)),
                ),
                const SizedBox(width: 24),
                const Text(
                  '© 2024 SMETS Academic Curator.',
                  style: TextStyle(fontSize: 12, color: Color(0xff64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRow _studentRow({
    required String initials,
    required Color initialsBg,
    required Color initialsColor,
    required String name,
    required String email,
    required String module,
    required double progress,
    required String progressText,
    required Color progressColor,
    Color progressBarColor = const Color(0xff137FEC),
    required String gpa,
    required String status,
    required Color statusBg,
    required Color statusColor,
  }) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
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
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xff181C22),
                    ),
                  ),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xff64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        DataCell(
          Text(
            module,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(
          SizedBox(
            width: 220,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xffB2CDFD),
                    valueColor: AlwaysStoppedAnimation(progressBarColor),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  progressText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          Center(
            child: Text(
              gpa,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xff137FEC),
              ),
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportHeaderSection extends StatelessWidget {
  const _ReportHeaderSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Row(
          children: [
            Icon(Icons.auto_awesome, size: 18, color: Color(0xff137FEC)),
            SizedBox(width: 6),
            Text(
              'Báo cáo đặc quyền cho Mentor',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xff137FEC),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Text(
          'Báo cáo Chi tiết: Thiết kế UI/UX Nâng cao (2024)',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xff181C22),
            height: 1.2,
          ),
        ),
        SizedBox(height: 12),
        _HeaderMetaRow(),
      ],
    );
  }
}

class _HeaderMetaRow extends StatelessWidget {
  const _HeaderMetaRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatusChip(
          text: 'Đang diễn ra',
          bg: const Color(0xffD1FAE5),
          color: const Color(0xff047857),
        ),
        const SizedBox(width: 12),
        const Text(
          'Lớp: ',
          style: TextStyle(fontSize: 14, color: Color(0xff64748B)),
        ),
        const Text(
          'UIUX-ADV-01',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xff181C22),
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text(
          ' • Mentor: ',
          style: TextStyle(fontSize: 14, color: Color(0xff64748B)),
        ),
        const Text(
          'Trần Hoàng Minh',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xff181C22),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final Color bg;
  final Color color;

  const _StatusChip({
    required this.text,
    required this.bg,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String value;
  final String badgeText;
  final Color badgeBg;
  final Color badgeColor;

  const _KpiCard({
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xff64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              color: Color(0xff137FEC),
              fontWeight: FontWeight.bold,
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

  const _LegendDot({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
    const maxHeight = 220.0;

    final totalHeight = maxHeight * (data.totalHeightFactor / 64);
    final filledHeight = maxHeight * (data.filledHeightFactor / 64);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: totalHeight,
            decoration: BoxDecoration(
              color: const Color(0xffB2CDFD),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.label,
            style: TextStyle(
              fontSize: 12,
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
