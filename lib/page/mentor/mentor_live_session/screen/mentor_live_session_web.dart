import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Mentor Live Session - Web Layout
/// Based on MentorTeachingSchedulePage design pattern
class MentorLiveSessionWeb extends StatefulWidget {
  const MentorLiveSessionWeb({super.key});

  @override
  State<MentorLiveSessionWeb> createState() => _MentorLiveSessionWebState();
}

class _MentorLiveSessionWebState extends State<MentorLiveSessionWeb> {
  int _selectedViewMode = 1; // 0=Day, 1=Week, 2=Month

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF9F9FF),
      body: Row(
        children: [
          // SIDEBAR
          _Sidebar(
            selectedIndex: 4,
            onItemSelected: (index) => _navigateTo(context, index),
          ),

          // MAIN CONTENT
          Expanded(
            child: Column(
              children: [
                const _TopBar(),
                Expanded(
                  child: _viewMode == 0
                      ? _DayView()
                      : _viewMode == 1
                          ? _WeekView()
                          : _MonthView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int get _viewMode => _selectedViewMode;

  void _navigateTo(BuildContext context, int index) {
    // Navigation handled via callback
  }
}

// ========================= SIDEBAR =========================

class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int)? onItemSelected;

  const _Sidebar({this.selectedIndex = 0, this.onItemSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: double.infinity,
      color: const Color(0xffF1F3FD),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'SMETS Mentor',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xff137FEC),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'HỆ THỐNG GIẢNG DẠY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Color(0xff717785),
            ),
          ),
          const SizedBox(height: 24),

          // Create button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Tạo buổi live',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff005BAF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
            ),
          ),

          const SizedBox(height: 16),

          _navItem(Icons.dashboard_outlined, 'Bảng điều khiển', 0),
          _navItem(Icons.school_outlined, 'Khóa học của tôi', 1),
          _navItem(Icons.calendar_month, 'Lịch giảng dạy', 2),
          _navItem(Icons.live_tv, 'Live Session', 3, selected: true),
          _navItem(Icons.group_outlined, 'Học viên', 5),
          _navItem(Icons.settings_outlined, 'Cài đặt', 6),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          const Text(
            'TRẠNG THÁI',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xff717785),
            ),
          ),
          const SizedBox(height: 12),

          _legendItem(const Color(0xff0074DB), 'Đang diễn ra'),
          _legendItem(const Color(0xff00875A), 'Sắp diễn ra'),
          _legendItem(const Color(0xff717785), 'Đã kết thúc'),

          const SizedBox(height: 16),

          const Text(
            'LOẠI SỰ KIỆN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xff717785),
            ),
          ),
          const SizedBox(height: 12),

          _legendItem(const Color(0xff005BAF), 'Live Session'),
          _legendItem(const Color(0xff455F89), 'Workshop'),
          _legendItem(const Color(0xffBC5700), 'Deadline'),

          const Spacer(),

          _navItem(Icons.help_outline, 'Trợ giúp', 7),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String title, int index, {bool selected = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        boxShadow:
            selected
                ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                : null,
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Icon(
          icon,
          color: selected ? const Color(0xff137FEC) : const Color(0xff717785),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? const Color(0xff137FEC) : const Color(0xff414753),
          ),
        ),
        onTap: () {
          if (onItemSelected != null) {
            onItemSelected!(index);
          }
        },
      ),
    );
  }

  Widget _legendItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Color(0xff414753)),
            ),
          ),
        ],
      ),
    );
  }
}

// ========================= TOP BAR =========================

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xffF9F9FF),
        border: Border(
          bottom: BorderSide(color: const Color(0xffD7DAE3).withOpacity(0.6)),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Live Session',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xff181C22),
            ),
          ),
          const SizedBox(width: 20),

          // Search
          SizedBox(
            width: 320,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm buổi live, học viên...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xffF1F3FD),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),

          // View mode toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xffF1F3FD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: const [
                _ViewModeButton(label: 'Ngày'),
                _ViewModeButton(label: 'Tuần', selected: true),
                _ViewModeButton(label: 'Tháng'),
              ],
            ),
          ),

          const Spacer(),

          // Filter dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xffE0E2EC)),
            ),
            child: const Row(
              children: [
                Icon(Icons.filter_list, size: 18, color: Color(0xff717785)),
                SizedBox(width: 8),
                Text(
                  'Lọc',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff414753),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Notifications
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
            color: const Color(0xff414753),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined),
            color: const Color(0xff414753),
          ),

          Container(
            width: 1,
            height: 30,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: const Color(0xffD7DAE3),
          ),

          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Nguyễn Phi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Giảng viên',
                style: TextStyle(fontSize: 11, color: Color(0xff717785)),
              ),
            ],
          ),
          const SizedBox(width: 12),

          const CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuA_d6unktizuFMX1wn4XTUU9yzmiB3Di4jF3qARSZd33NBUFz8tBv5IzF-OHZHMjlI__pkPDuzkiDsN1WsPPWUbQncb_jUuYcEFAw2p994qOM7PKfxazFiXk8Wvr1F4iu-kkWGPzfHIrN9xy4gI3NaXqA3rLV60t_fmg50ORzlE7tud4QDAuGLTUAt5dKQoLVNPs0FK32YE3UE6uZdo1V0AW1bpB_1T85V4rIWpFFJUISFY92m20SFnx_nuTcy4hGWOkT3TQ9LVOmrd',
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewModeButton extends StatelessWidget {
  final String label;
  final bool selected;

  const _ViewModeButton({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? const Color(0xff005BAF) : const Color(0xff414753),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ========================= WEEK VIEW =========================

class _WeekView extends StatelessWidget {
  static const double timeColumnWidth = 80;
  static const double hourRowHeight = 80;

  const _WeekView();

  @override
  Widget build(BuildContext context) {
    final days = [
      {'name': 'THỨ 2', 'date': '27', 'selected': false},
      {'name': 'THỨ 3', 'date': '28', 'selected': true},
      {'name': 'THỨ 4', 'date': '29', 'selected': false},
      {'name': 'THỨ 5', 'date': '30', 'selected': false},
      {'name': 'THỨ 6', 'date': '31', 'selected': false},
      {'name': 'THỨ 7', 'date': '01', 'selected': false},
      {'name': 'CHỦ NHẬT', 'date': '02', 'selected': false},
    ];

    final hours = List.generate(14, (index) => 7 + index);

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header days
          Container(
            height: 82,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xffE0E2EC))),
            ),
            child: Row(
              children: [
                Container(
                  width: timeColumnWidth,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: Color(0xffE0E2EC))),
                  ),
                  child: const Text(
                    'GMT+7',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff717785),
                    ),
                  ),
                ),
                ...List.generate(days.length, (index) {
                  final day = days[index];
                  final selected = day['selected'] as bool;
                  return Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xff0074DB).withOpacity(0.05) : null,
                        border: Border(
                          right: index != days.length - 1
                              ? const BorderSide(color: Color(0xffE0E2EC))
                              : BorderSide.none,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            day['name'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: selected ? const Color(0xff005BAF) : const Color(0xff717785),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            day['date'] as String,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                              color: selected ? const Color(0xff005BAF) : const Color(0xff181C22),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Calendar body
          Expanded(
            child: SingleChildScrollView(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final fullWidth = constraints.maxWidth;
                  final dayWidth = (fullWidth - timeColumnWidth) / 7;
                  final totalHeight = hours.length * hourRowHeight;

                  return SizedBox(
                    height: totalHeight,
                    child: Stack(
                      children: [
                        // Background columns
                        Positioned.fill(
                          child: Row(
                            children: [
                              Container(
                                width: timeColumnWidth,
                                decoration: const BoxDecoration(
                                  border: Border(right: BorderSide(color: Color(0xffE0E2EC))),
                                ),
                              ),
                              ...List.generate(7, (index) {
                                final isSelectedDay = index == 1;
                                return Container(
                                  width: dayWidth,
                                  decoration: BoxDecoration(
                                    color: isSelectedDay
                                        ? const Color(0xff0074DB).withOpacity(0.02)
                                        : Colors.transparent,
                                    border: Border(
                                      right: index != 6
                                          ? BorderSide(color: const Color(0xffE0E2EC).withOpacity(0.8))
                                          : BorderSide.none,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),

                        // Hour rows
                        ...List.generate(hours.length, (index) {
                          return Positioned(
                            top: index * hourRowHeight,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: hourRowHeight,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: const Color(0xffE0E2EC).withOpacity(0.5),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: timeColumnWidth,
                                    padding: const EdgeInsets.only(left: 10, top: 4),
                                    child: Text(
                                      '${hours[index].toString().padLeft(2, '0')}:00',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xff717785),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                        // Event 1 - Tuesday - Live Session
                        Positioned(
                          top: 100,
                          left: timeColumnWidth + (1 * dayWidth) + 4,
                          width: dayWidth - 8,
                          height: 160,
                          child: _eventCard(
                            color: const Color(0xff0074DB),
                            tag: 'LIVE SESSION',
                            icon: Icons.live_tv,
                            title: 'Kỹ năng Quản lý Đội ngũ',
                            time: '08:30 - 10:30',
                            footer: 'Google Meet',
                            footerIcon: Icons.videocam_outlined,
                            participants: '24/30 học viên',
                          ),
                        ),

                        // Event 2 - Wednesday - Workshop
                        Positioned(
                          top: 160,
                          left: timeColumnWidth + (2 * dayWidth) + 4,
                          width: dayWidth - 8,
                          height: 240,
                          child: _eventCard(
                            color: const Color(0xff455F89),
                            tag: 'WORKSHOP',
                            icon: Icons.groups_outlined,
                            title: 'Văn hóa Doanh nghiệp 4.0',
                            time: '09:00 - 12:00',
                            footer: 'Phòng họp Lớn',
                            footerIcon: Icons.location_on_outlined,
                            participants: '18/25 học viên',
                          ),
                        ),

                        // Event 3 - Thursday - Deadline
                        Positioned(
                          top: 560,
                          left: timeColumnWidth + (3 * dayWidth) + 4,
                          width: dayWidth - 8,
                          height: 100,
                          child: _eventCard(
                            color: const Color(0xffBC5700),
                            tag: 'DEADLINE',
                            icon: Icons.assignment_outlined,
                            title: 'Nộp báo cáo Dự án',
                            time: 'Hạn: 15:30',
                            participants: 'Đã nộp: 20/30',
                          ),
                        ),

                        // Event 4 - Friday - Live Session
                        Positioned(
                          top: 200,
                          left: timeColumnWidth + (4 * dayWidth) + 4,
                          width: dayWidth - 8,
                          height: 160,
                          child: _eventCard(
                            color: const Color(0xff00875A),
                            tag: 'SẮP DIỄN RA',
                            icon: Icons.live_tv_outlined,
                            title: 'Buổi Q&A - Frontend Dev',
                            time: '14:00 - 15:30',
                            footer: 'Zoom Meeting',
                            footerIcon: Icons.videocam_outlined,
                            participants: '0/40 đăng ký',
                          ),
                        ),

                        // Current time indicator
                        Positioned(
                          top: 280,
                          left: timeColumnWidth,
                          right: 0,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const Expanded(
                                child: SizedBox(
                                  height: 2,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(color: Colors.red),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _eventCard({
    required Color color,
    required String tag,
    required IconData icon,
    required String title,
    required String time,
    String? footer,
    IconData? footerIcon,
    String? participants,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 12,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Icon(icon, color: Colors.white, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            time,
            style: TextStyle(
              color: Colors.white.withOpacity(0.92),
              fontSize: 11,
            ),
          ),
          if (participants != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.people_outline, color: Colors.white.withOpacity(0.85), size: 13),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    participants,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const Spacer(),
          if (footer != null)
            Row(
              children: [
                if (footerIcon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(footerIcon, color: Colors.white, size: 14),
                  ),
                Expanded(
                  child: Text(
                    footer,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ========================= DAY VIEW =========================

class _DayView extends StatelessWidget {
  const _DayView();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Color(0xff005BAF)),
              const SizedBox(width: 12),
              const Text(
                'Thứ 3, 28/03/2026',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff181C22),
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Thêm buổi live'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xff005BAF),
                  side: const BorderSide(color: Color(0xff005BAF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xffE0E2EC)),
          const SizedBox(height: 16),

          // Sessions list
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _daySessionCard(
                    color: const Color(0xff0074DB),
                    status: 'ĐANG DIỄN RA',
                    statusColor: Colors.red,
                    tag: 'LIVE SESSION',
                    icon: Icons.live_tv,
                    title: 'Kỹ năng Quản lý Đội ngũ',
                    time: '08:30 - 10:30',
                    location: 'Google Meet',
                    participants: '24/30 học viên đã tham gia',
                    description:
                        'Buổi học về kỹ năng quản lý đội ngũ hiệu quả trong môi trường doanh nghiệp hiện đại.',
                    progress: 0.45,
                  ),
                  const SizedBox(height: 16),

                  _daySessionCard(
                    color: const Color(0xff00875A),
                    status: 'SẮP DIỄN RA',
                    statusColor: const Color(0xff00875A),
                    tag: 'LIVE SESSION',
                    icon: Icons.live_tv_outlined,
                    title: 'Workshop - Thiết kế UX/UI Nâng cao',
                    time: '14:00 - 16:30',
                    location: 'Phòng học A2',
                    participants: '15/25 đã đăng ký',
                    description:
                        'Workshop thực hành về thiết kế UX/UI với Figma và các công cụ hiện đại.',
                  ),

                  const SizedBox(height: 32),

                  // Quick stats
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xffF1F3FD),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        _quickStat(Icons.people, 'Tổng học viên', '156'),
                        const SizedBox(width: 32),
                        _quickStat(Icons.live_tv, 'Buổi đã tổ chức', '24'),
                        const SizedBox(width: 32),
                        _quickStat(Icons.access_time, 'Giờ đã giảng dạy', '48h'),
                        const SizedBox(width: 32),
                        _quickStat(Icons.star, 'Đánh giá TB', '4.8/5'),
                      ],
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

  Widget _quickStat(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xff005BAF), size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xff717785),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff181C22),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _daySessionCard({
    required Color color,
    required String status,
    required Color statusColor,
    required String tag,
    required IconData icon,
    required String title,
    required String time,
    required String location,
    required String participants,
    required String description,
    double? progress,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE0E2EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Color accent bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status and tag
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(26),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withAlpha(26),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 14, color: color),
                          const SizedBox(width: 4),
                          Text(
                            tag,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (progress != null)
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff181C22),
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xff717785),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Progress bar
                if (progress != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: const Color(0xffE0E2EC),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Info chips
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _infoChip(Icons.access_time, time),
                    _infoChip(Icons.location_on_outlined, location),
                    _infoChip(Icons.people_outline, participants),
                  ],
                ),
                const SizedBox(height: 16),

                // Actions
                Row(
                  children: [
                    if (progress != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.video_call, size: 20),
                          label: const Text('Tiếp tục buổi học'),
                        ),
                      )
                    else
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: color,
                            side: BorderSide(color: color),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          label: const Text('Chỉnh sửa'),
                        ),
                      ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.copy_outlined),
                      color: const Color(0xff717785),
                      tooltip: 'Sao chép',
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red[300],
                      tooltip: 'Xóa',
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

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xffF1F3FD),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xff717785)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: Color(0xff414753)),
          ),
        ],
      ),
    );
  }
}

// ========================= MONTH VIEW =========================

class _MonthView extends StatelessWidget {
  const _MonthView();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tháng 3, 2026',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xff181C22),
            ),
          ),
          const SizedBox(height: 24),

          // Calendar grid
          Expanded(
            child: Column(
              children: [
                // Day headers
                const Row(
                  children: [
                    _MonthDayHeader(label: 'T2'),
                    _MonthDayHeader(label: 'T3'),
                    _MonthDayHeader(label: 'T4'),
                    _MonthDayHeader(label: 'T5'),
                    _MonthDayHeader(label: 'T6'),
                    _MonthDayHeader(label: 'T7'),
                    _MonthDayHeader(label: 'CN'),
                  ],
                ),
                const SizedBox(height: 8),
                // Calendar cells
                Expanded(
                  child: Column(
                    children: [
                      _monthWeekRow([
                        _monthDayCell(27, false, [
                          _monthEventItem(const Color(0xff455F89), 'Workshop', Icons.groups),
                          _monthEventItem(const Color(0xff0074DB), 'Live Session', Icons.live_tv),
                        ]),
                        _monthDayCell(28, true, [
                          _monthEventItem(const Color(0xff0074DB), 'Kỹ năng QLĐN', Icons.live_tv),
                          _monthEventItem(const Color(0xff00875A), 'Q&A Frontend', Icons.live_tv_outlined),
                        ]),
                        _monthDayCell(29, false, [
                          _monthEventItem(const Color(0xffBC5700), 'Deadline', Icons.assignment),
                        ]),
                        _monthDayCell(30, false, [
                          _monthEventItem(const Color(0xff455F89), 'Workshop UX/UI', Icons.groups),
                        ]),
                        _monthDayCell(31, false, [
                          _monthEventItem(const Color(0xff0074DB), 'Kỹ năng MC', Icons.live_tv),
                        ]),
                        _monthDayCell(1, false, []),
                        _monthDayCell(2, false, []),
                      ]),
                      _monthWeekRow([
                        _monthDayCell(3, false, []),
                        _monthDayCell(4, false, [
                          _monthEventItem(const Color(0xff0074DB), 'Node.js Advanced', Icons.live_tv),
                        ]),
                        _monthDayCell(5, false, [
                          _monthEventItem(const Color(0xff00875A), 'Career Path', Icons.live_tv_outlined),
                        ]),
                        _monthDayCell(6, false, []),
                        _monthDayCell(7, false, []),
                        _monthDayCell(8, false, []),
                        _monthDayCell(9, false, []),
                      ]),
                      _monthWeekRow([
                        _monthDayCell(10, false, []),
                        _monthDayCell(11, false, []),
                        _monthDayCell(12, false, []),
                        _monthDayCell(13, false, []),
                        _monthDayCell(14, false, []),
                        _monthDayCell(15, false, []),
                        _monthDayCell(16, false, []),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xffF1F3FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.insights, color: Color(0xff005BAF)),
                SizedBox(width: 12),
                Text(
                  'Tháng này:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff414753)),
                ),
                SizedBox(width: 16),
                _SummaryChip(color: Color(0xff0074DB), text: '8 Live Sessions'),
                SizedBox(width: 12),
                _SummaryChip(color: Color(0xff455F89), text: '3 Workshops'),
                SizedBox(width: 12),
                _SummaryChip(color: Color(0xff00875A), text: '12h giảng dạy'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthWeekRow(List<Widget> cells) {
    return Expanded(
      child: Row(
        children: cells.asMap().entries.map((entry) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: entry.key < cells.length - 1 ? 4 : 0),
              child: entry.value,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _monthDayCell(int day, bool selected, List<Widget> events) {
    return Container(
      decoration: BoxDecoration(
        color: selected ? const Color(0xff005BAF).withAlpha(13) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: selected ? Border.all(color: const Color(0xff005BAF)) : null,
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            day.toString(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.bold : FontWeight.w600,
              color: selected ? const Color(0xff005BAF) : const Color(0xff181C22),
            ),
          ),
          if (events.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...events.take(3),
            if (events.length > 3)
              Text(
                '+${events.length - 3} more',
                style: const TextStyle(fontSize: 9, color: Color(0xff717785)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _monthEventItem(Color color, String text, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(3),
        border: Border(left: BorderSide(color: color, width: 2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 8, color: color),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 9,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final Color color;
  final String text;

  const _SummaryChip({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _MonthDayHeader extends StatelessWidget {
  final String label;

  const _MonthDayHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xff717785),
          ),
        ),
      ),
    );
  }
}
