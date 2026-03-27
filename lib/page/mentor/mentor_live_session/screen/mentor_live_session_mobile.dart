import 'package:flutter/material.dart';

/// Mentor Live Session - Mobile Layout
class MentorLiveSessionMobile extends StatefulWidget {
  const MentorLiveSessionMobile({super.key});

  @override
  State<MentorLiveSessionMobile> createState() => _MentorLiveSessionMobileState();
}

class _MentorLiveSessionMobileState extends State<MentorLiveSessionMobile>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showCreateModal = false;

  // Mock data
  final List<_LiveSessionData> _sessions = [
    _LiveSessionData(
      id: '1',
      title: 'Kỹ năng Quản lý Đội ngũ',
      course: 'Khóa học UX/UI Design',
      courseColor: const Color(0xff0074DB),
      startTime: DateTime(2026, 3, 13, 8, 30),
      endTime: DateTime(2026, 3, 13, 10, 30),
      meetingUrl: 'https://meet.google.com/abc-defg-hij',
      description: 'Buổi học về kỹ năng quản lý đội ngũ hiệu quả trong doanh nghiệp',
      status: _SessionStatus.upcoming,
      attendeeCount: 24,
      maxAttendees: 30,
    ),
    _LiveSessionData(
      id: '2',
      title: 'Văn hóa Doanh nghiệp 4.0',
      course: 'Khóa học Frontend Dev',
      courseColor: const Color(0xffBC5700),
      startTime: DateTime(2026, 3, 16, 9, 0),
      endTime: DateTime(2026, 3, 16, 12, 0),
      meetingUrl: 'https://meet.google.com/xyz-uvwx-yz',
      description: 'Workshop về văn hóa doanh nghiệp trong kỷ nguyên số',
      status: _SessionStatus.upcoming,
      attendeeCount: 18,
      maxAttendees: 25,
    ),
    _LiveSessionData(
      id: '3',
      title: 'Buổi học Live số 1 - Giới thiệu React',
      course: 'Khóa học Frontend Dev',
      courseColor: const Color(0xffBC5700),
      startTime: DateTime(2026, 3, 10, 14, 0),
      endTime: DateTime(2026, 3, 10, 16, 0),
      meetingUrl: '',
      description: 'Buổi giới thiệu tổng quan về React và các khái niệm cơ bản',
      status: _SessionStatus.past,
      attendeeCount: 30,
      maxAttendees: 30,
    ),
    _LiveSessionData(
      id: '4',
      title: 'Buổi học thực hành Node.js',
      course: 'Khóa học Backend Nodejs',
      courseColor: const Color(0xff455F89),
      startTime: DateTime(2026, 3, 8, 10, 0),
      endTime: DateTime(2026, 3, 8, 12, 0),
      meetingUrl: '',
      description: 'Thực hành xây dựng API với Node.js và Express',
      status: _SessionStatus.past,
      attendeeCount: 20,
      maxAttendees: 25,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return '${days[dt.weekday - 1]}, ${dt.day}/${dt.month}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _getDuration(DateTime start, DateTime end) {
    final diff = end.difference(start);
    return '${diff.inHours}h${diff.inMinutes % 60 > 0 ? ' ${diff.inMinutes % 60}p' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF9F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live Session',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Quản lý buổi học trực tuyến',
              style: TextStyle(
                color: Color(0xff717785),
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Color(0xff414753)),
            onPressed: () {},
          ),
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xff137FEC),
            child: Icon(Icons.person, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xff005BAF),
          unselectedLabelColor: const Color(0xff717785),
          indicatorColor: const Color(0xff005BAF),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.schedule, size: 16),
                  const SizedBox(width: 4),
                  const Text('Sắp diễn ra'),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xff005BAF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_sessions.where((s) => s.status == _SessionStatus.upcoming).length}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 16),
                  SizedBox(width: 4),
                  Text('Đã kết thúc'),
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt, size: 16),
                  SizedBox(width: 4),
                  Text('Tất cả'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSessionList(_sessions.where((s) => s.status == _SessionStatus.upcoming).toList()),
          _buildSessionList(_sessions.where((s) => s.status == _SessionStatus.past).toList()),
          _buildSessionList(_sessions),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _showCreateModal = true),
        backgroundColor: const Color(0xff005BAF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSessionList(List<_LiveSessionData> sessions) {
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'Chưa có buổi Live nào',
              style: TextStyle(fontSize: 16, color: Colors.grey[500], fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Nhấn + để tạo buổi Live mới',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildMiniStats(sessions);
        }
        return _buildSessionCard(sessions[index - 1]);
      },
    );
  }

  Widget _buildMiniStats(List<_LiveSessionData> sessions) {
    final upcoming = _sessions.where((s) => s.status == _SessionStatus.upcoming).length;
    final past = _sessions.where((s) => s.status == _SessionStatus.past).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xffE0E2EC)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xff005BAF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.schedule, color: Color(0xff005BAF), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$upcoming',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff005BAF),
                        ),
                      ),
                      const Text(
                        'Sắp diễn ra',
                        style: TextStyle(fontSize: 11, color: Color(0xff717785)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xffE0E2EC)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.history, color: Colors.grey[600], size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$past',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Text(
                        'Đã kết thúc',
                        style: TextStyle(fontSize: 11, color: Color(0xff717785)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(_LiveSessionData session) {
    final isUpcoming = session.status == _SessionStatus.upcoming;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE0E2EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Color bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: session.courseColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isUpcoming
                            ? const Color(0xff005BAF).withOpacity(0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isUpcoming ? 'SẮP DIỄN RA' : 'ĐÃ KẾT THÚC',
                        style: TextStyle(
                          color: isUpcoming ? const Color(0xff005BAF) : Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: session.courseColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: session.courseColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            session.course,
                            style: TextStyle(
                              color: session.courseColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Title
                Text(
                  session.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff181C22),
                  ),
                ),

                const SizedBox(height: 8),

                // Date & time
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 13, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(session.startTime),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.access_time, size: 13, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      '${_formatTime(session.startTime)} - ${_formatTime(session.endTime)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Attendees
                Row(
                  children: [
                    Icon(Icons.people_outline, size: 13, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      '${session.attendeeCount}/${session.maxAttendees} học viên',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.timer_outlined, size: 13, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      _getDuration(session.startTime, session.endTime),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Action buttons
                Row(
                  children: [
                    if (session.meetingUrl.isNotEmpty)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff005BAF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.video_call, size: 18),
                          label: const Text('Tham gia', style: TextStyle(fontSize: 13)),
                        ),
                      )
                    else
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xff005BAF),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xff005BAF)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.info_outline, size: 18),
                          label: const Text('Chi tiết', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xffF1F3FD),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        onPressed: () {},
                        icon: Icon(
                          isUpcoming ? Icons.edit_outlined : Icons.visibility_outlined,
                          size: 20,
                          color: const Color(0xff717785),
                        ),
                        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      decoration: BoxDecoration(
                        color: isUpcoming ? Colors.red[50] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: isUpcoming ? Colors.red[300] : Colors.grey[400],
                        ),
                        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
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

// ========================= INNER CLASSES =========================

enum _SessionStatus { upcoming, past, all }

class _LiveSessionData {
  final String id;
  final String title;
  final String course;
  final Color courseColor;
  final DateTime startTime;
  final DateTime endTime;
  final String meetingUrl;
  final String description;
  final _SessionStatus status;
  final int attendeeCount;
  final int maxAttendees;

  _LiveSessionData({
    required this.id,
    required this.title,
    required this.course,
    required this.courseColor,
    required this.startTime,
    required this.endTime,
    required this.meetingUrl,
    required this.description,
    required this.status,
    required this.attendeeCount,
    required this.maxAttendees,
  });
}
