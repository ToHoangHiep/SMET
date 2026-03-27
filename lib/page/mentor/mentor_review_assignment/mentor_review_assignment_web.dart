import 'package:flutter/material.dart';

/// Mentor Review Assignment - Web Layout
class MentorReviewAssignmentWeb extends StatelessWidget {
  const MentorReviewAssignmentWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF9F9FF),
      body: Row(
        children: [
          const _Sidebar(),
          Expanded(
            child: Column(
              children: const [
                _TopHeader(),
                Expanded(child: _MainContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      color: const Color(0xffF8FAFC),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xff005BAF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.school, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Curator Portal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xff1E40AF),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'SMETS TRAINING',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.4,
                            color: Color(0xff64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _navItem(Icons.dashboard_outlined, 'Bảng điều khiển'),
                _navItem(Icons.auto_stories_outlined, 'Khóa học của tôi'),
                _navItem(Icons.calendar_today_outlined, 'Lịch giảng dạy'),
                _navItem(Icons.group_outlined, 'Học viên'),
                _navItem(
                  Icons.assignment_turned_in,
                  'Chấm bài',
                  active: true,
                ),
                _navItem(Icons.settings_outlined, 'Cài đặt'),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0074DB),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Review Pending',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _bottomItem(Icons.contact_support_outlined, 'Support'),
                _bottomItem(
                  Icons.logout,
                  'Logout',
                  color: const Color(0xffBA1A1A),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String title, {bool active = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xffEFF6FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border:
            active
                ? const Border(
                  right: BorderSide(color: Color(0xff2563EB), width: 4),
                )
                : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: active ? const Color(0xff1D4ED8) : const Color(0xff64748B),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            color: active ? const Color(0xff1D4ED8) : const Color(0xff64748B),
          ),
        ),
        onTap: () {},
      ),
    );
  }

  Widget _bottomItem(IconData icon, String title, {Color? color}) {
    final itemColor = color ?? const Color(0xff64748B);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(icon, color: itemColor),
      title: Text(
        title,
        style: TextStyle(
          color: itemColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {},
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: const Color(0xffF9F9FF),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 420,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm học viên, bài tập...',
                prefixIcon: const Icon(Icons.search, color: Color(0xff94A3B8)),
                filled: true,
                fillColor: const Color(0xffF1F3FD),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const Spacer(),
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none),
                color: const Color(0xff64748B),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xffBA1A1A),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.help_outline),
            color: const Color(0xff64748B),
          ),
          const SizedBox(width: 20),
          Container(width: 1, height: 36, color: const Color(0xffE2E8F0)),
          const SizedBox(width: 16),
          Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text(
                    'Dr. Nguyen Mentor',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Senior UX Instructor',
                    style: TextStyle(fontSize: 10, color: Color(0xff64748B)),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              const CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuB3PCAcbr-ghpHy6q0Lph1clUVrDsf5ODrtwJagbOrOkMIktFRO7bNEjJP1J-cRd51K4pW_a1n5uKy1ohmif52QUrJOyOJCVB176jwlFQKlh02t3rlTQBVrBCegSL7UtFmAyofgSGhmIJLO2wcqNuoB6MFtZjmtl4Nw7WTyt2l0y7Gj3NpDA_FSSE6WetjKOaoPs7vgnr8G3UG1qw2MWONM7H7RWVy9v0axvOIXxutbtHvzzNhQ7a1A8WUXRk6yC4xo1vkKycLC-orO',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MainContent extends StatelessWidget {
  const _MainContent();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Review Assignment',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Color(0xff0F172A),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Xem lại kết quả bài nộp và đưa ra nhận xét cho học viên.',
              style: TextStyle(fontSize: 14, color: Color(0xff414753)),
            ),
            SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: _SubmissionList()),
                SizedBox(width: 24),
                Expanded(flex: 7, child: _ReviewDetailPanel()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmissionList extends StatelessWidget {
  const _SubmissionList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'DANH SÁCH BÀI NỘP (12)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: Color(0xff64748B),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.filter_list, size: 18),
              label: const Text(
                'Lọc bài tập',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 700,
          child: ListView(
            children: const [
              _SubmissionCard(
                active: true,
                initials: 'LB',
                studentName: 'Lê Thị B',
                dateText: 'Hoàn thành: 14:30 · Hôm nay',
                statusText: 'Chờ xem',
                statusBg: Color(0xffFEF3C7),
                statusTextColor: Color(0xffB45309),
                assignmentTitle: 'Bài tập thiết kế Persona',
                courseTitle: 'UX/UI Design Advanced',
              ),
              SizedBox(height: 12),
              _SubmissionCard(
                active: false,
                avatarUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuAGRQXULg4wdQoLm6sqLJBGoTZ40iB3sWRm59J9MZC-SjDCZ_68EQmVwCVB79BvVtNOCZFOhqpEebYBmk6_QaVpa4yH7BI28FjpZ1miOcBowxEYgtfhQ783iKcAunMhqM_l_EvLPsBRJl7sdn_v4_-TWtus0vFZ4ojcIc5qr9iYOF9nnX9TvMGvyzH3uMSju0yVlUZI5aLjFMPM2ofUXyko6uYFTDp0VoljuTgab8_G_YtVjBKmEXyJRJy73keUb10bVn8CvzXY2qsy',
                studentName: 'Trần Minh A',
                dateText: 'Hoàn thành: 20/03/2026',
                statusText: 'Đã xem',
                statusBg: Color(0xffDCFCE7),
                statusTextColor: Color(0xff15803D),
                assignmentTitle: 'Bài tập User Flow',
                courseTitle: 'UX/UI Design Advanced',
              ),
              SizedBox(height: 12),
              _SubmissionCard(
                active: false,
                initials: 'NH',
                studentName: 'Nguyễn Hùng C',
                dateText: 'Hoàn thành: 19/03/2026',
                statusText: 'Chờ xem',
                statusBg: Color(0xffFEF3C7),
                statusTextColor: Color(0xffB45309),
                assignmentTitle: 'Wireframe App Mobile',
                courseTitle: 'UX/UI Design Advanced',
              ),
              SizedBox(height: 12),
              _SubmissionCard(
                active: false,
                initials: 'PH',
                studentName: 'Phạm Thị D',
                dateText: 'Hoàn thành: 18/03/2026',
                statusText: 'Đã xem',
                statusBg: Color(0xffDCFCE7),
                statusTextColor: Color(0xff15803D),
                assignmentTitle: 'Usability Test Report',
                courseTitle: 'UX Research Fundamentals',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final bool active;
  final String? initials;
  final String? avatarUrl;
  final String studentName;
  final String dateText;
  final String statusText;
  final Color statusBg;
  final Color statusTextColor;
  final String assignmentTitle;
  final String courseTitle;

  const _SubmissionCard({
    required this.active,
    this.initials,
    this.avatarUrl,
    required this.studentName,
    required this.dateText,
    required this.statusText,
    required this.statusBg,
    required this.statusTextColor,
    required this.assignmentTitle,
    required this.courseTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: active ? Colors.white : const Color(0xffF1F3FD),
        borderRadius: BorderRadius.circular(20),
        border: active ? Border.all(color: const Color(0xff005BAF), width: 2) : null,
        boxShadow:
            active
                ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
                : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (active)
            Container(
              width: 4,
              height: 90,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                color: const Color(0xff005BAF),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (avatarUrl != null)
                      CircleAvatar(radius: 20, backgroundImage: NetworkImage(avatarUrl!))
                    else
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xffDBEAFE),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xff005BAF),
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateText,
                            style: const TextStyle(fontSize: 12, color: Color(0xff64748B)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        statusText.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: statusTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  assignmentTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.menu_book, size: 16, color: Color(0xff64748B)),
                    const SizedBox(width: 6),
                    Text(
                      courseTitle,
                      style: const TextStyle(fontSize: 12, color: Color(0xff414753)),
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

class _ReviewDetailPanel extends StatelessWidget {
  const _ReviewDetailPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student header
          Container(
            padding: const EdgeInsets.only(bottom: 28),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xffF1F5F9))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xff3B82F6), Color(0xff1D4ED8)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'LB',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Lê Thị B',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff0F172A),
                            ),
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 16,
                            runSpacing: 6,
                            children: [
                              _InlineInfo(
                                icon: Icons.book_outlined,
                                text: 'UX/UI Design Advanced',
                              ),
                              _InlineInfo(
                                icon: Icons.assignment_outlined,
                                text: 'Bài tập: Thiết kế Persona',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xff005BAF).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xff005BAF).withOpacity(0.1)),
                  ),
                  child: Column(
                    children: const [
                      Text(
                        'ĐIỂM TỰ ĐỘNG',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: Color(0xff005BAF),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '85/100',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xff005BAF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Row(
            children: const [
              Icon(Icons.analytics, color: Color(0xff005BAF)),
              SizedBox(width: 8),
              Text(
                'CHI TIẾT BÀI NỘP',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                  color: Color(0xff0F172A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const _AssignmentItem(
            correct: true,
            section: 'Phần 1',
            title: 'Nghiên cứu người dùng',
            studentContent: 'Phân tích Insight người dùng rõ ràng, có trích dẫn dữ liệu thực tế.',
            feedback: 'Tốt',
          ),
          const SizedBox(height: 12),
          const _AssignmentItem(
            correct: true,
            section: 'Phần 2',
            title: 'Thiết kế Persona',
            studentContent: '3 Persona được xây dựng hợp lý với đầy đủ thông tin nhân khẩu học.',
            feedback: 'Tốt',
          ),
          const SizedBox(height: 12),
          const _AssignmentItem(
            correct: false,
            section: 'Phần 3',
            title: 'User Journey Map',
            studentContent: 'Chưa đầy đủ các touchpoint và không có cảm xúc người dùng.',
            feedback: 'Cần bổ sung',
          ),

          const SizedBox(height: 28),

          const Text(
            'Nhận xét của Mentor',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xff334155),
            ),
          ),
          const SizedBox(height: 10),

          TextField(
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Viết phản hồi tổng quát cho học viên về bài nộp này...',
              filled: true,
              fillColor: const Color(0xffF1F3FD),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xffEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xffDBEAFE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.info_outline, color: Color(0xff3B82F6)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Gợi ý: Học viên nắm vững nghiên cứu người dùng và thiết kế Persona. Cần bổ sung chi tiết về User Journey Map để hoàn thiện bài tập.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff1D4ED8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0074DB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: const StadiumBorder(),
                    elevation: 4,
                  ),
                  child: const Text(
                    'Xác nhận đã xem',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Lưu nhận xét',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff475569)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InlineInfo({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xff64748B)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 14, color: Color(0xff64748B), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _AssignmentItem extends StatelessWidget {
  final bool correct;
  final String section;
  final String title;
  final String studentContent;
  final String feedback;

  const _AssignmentItem({
    required this.correct,
    required this.section,
    required this.title,
    required this.studentContent,
    required this.feedback,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffF1F5F9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            correct ? Icons.check_circle : Icons.cancel,
            color: correct ? const Color(0xff22C55E) : const Color(0xffBA1A1A),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xffE2E8F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        section,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff475569),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const SizedBox(
                      width: 120,
                      child: Text(
                        'Nội dung học viên:',
                        style: TextStyle(fontSize: 12, color: Color(0xff64748B)),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        studentContent,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: correct ? const Color(0xff0F172A) : const Color(0xffBA1A1A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(
                      width: 120,
                      child: Text(
                        'Đánh giá:',
                        style: TextStyle(fontSize: 12, color: Color(0xff64748B)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: correct ? const Color(0xffDCFCE7) : const Color(0xffFEF3C7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        feedback,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: correct ? const Color(0xff15803D) : const Color(0xffB45309),
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
