import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/service/employee/lms_service.dart';

import 'package:url_launcher/url_launcher.dart';

/// Buổi học trực tuyến (học viên) — layout giống mentor: breadcrumb, chọn khóa học, Ngày/Tuần/Tháng, lịch.
class EmployeeLiveSessionWeb extends StatefulWidget {
  const EmployeeLiveSessionWeb({super.key, this.initialCourseId});

  /// Optional course id từ query (deep link).
  final String? initialCourseId;

  @override
  State<EmployeeLiveSessionWeb> createState() => _EmployeeLiveSessionWebState();
}

class _EmployeeLiveSessionWebState extends State<EmployeeLiveSessionWeb> {
  int _selectedViewMode = 1; // 0=Day, 1=Week, 2=Month

  List<EnrolledCourse> _courses = [];
  EnrolledCourse? _selectedCourse;
  List<LiveSessionInfo> _sessions = [];
  bool _isLoadingCourses = false;
  bool _isLoadingSessions = false;
  String? _errorMessage;

  /// Ngày đang xem ở chế độ « Tuần » — lấy thứ Hai đầu tuần.
  DateTime _weekViewFocusedDate = _calendarDateOnly(_weekStartOf(DateTime.now()));

  /// Trả về thứ Hai của tuần chứa ngày d.
  static DateTime _weekStartOf(DateTime d) {
    final diff = d.weekday - 1;
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: diff));
  }

  static DateTime _calendarDateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _monthYearVietnamese(DateTime d) {
    const months = [
      '',
      'Tháng 1',
      'Tháng 2',
      'Tháng 3',
      'Tháng 4',
      'Tháng 5',
      'Tháng 6',
      'Tháng 7',
      'Tháng 8',
      'Tháng 9',
      'Tháng 10',
      'Tháng 11',
      'Tháng 12',
    ];
    return '${months[d.month]} ${d.year}';
  }

  @override
  void initState() {
    super.initState();
    _loadMyCourses();
  }

  Future<void> _loadMyCourses() async {
    setState(() => _isLoadingCourses = true);
    try {
      final result = await LmsService.getMyCourses(page: 0, size: 50);
      if (!mounted) return;
      EnrolledCourse? preselected;
      final cid = widget.initialCourseId;
      if (cid != null && cid.isNotEmpty) {
        for (final c in result.content) {
          if (c.id == cid) {
            preselected = c;
            break;
          }
        }
      }
      setState(() {
        _courses = result.content;
        _isLoadingCourses = false;
        _errorMessage = null;
        if (preselected != null) {
          _selectedCourse = preselected;
        }
      });
      if (preselected != null) {
        _loadSessions(preselected);
      }
    } catch (e) {
      if (!mounted) return;
      log('[EmployeeLiveSession] loadCourses failed: $e');
      setState(() {
        _isLoadingCourses = false;
        _errorMessage = 'Không thể tải danh sách khóa học';
      });
    }
  }

  Future<void> _loadSessions(EnrolledCourse course) async {
    setState(() {
      _selectedCourse = course;
      _isLoadingSessions = true;
      _sessions = [];
    });
    try {
      final list = await LmsService.getLiveSessions(course.id);
      if (!mounted) return;
      setState(() {
        _sessions = list;
        _isLoadingSessions = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      log('[EmployeeLiveSession] loadSessions failed: $e');
      setState(() {
        _isLoadingSessions = false;
        _errorMessage = 'Không thể tải buổi live';
      });
    }
  }

  Future<void> _joinSession(LiveSessionInfo session) async {
    ScaffoldMessenger.of(context).clearSnackBars();

    String? directUrl;
    if (session.meetingUrl.isNotEmpty) {
      directUrl = session.meetingUrl;
    }

    late String meetingUrl;
    if (directUrl != null) {
      meetingUrl = directUrl;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang kết nối buổi live...')),
      );
      try {
        meetingUrl = await LmsService.joinSession(session.id);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final uri = Uri.parse(meetingUrl);
    final canLaunch = await canLaunchUrl(uri);
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    if (canLaunch) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể mở link: $meetingUrl')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF9F9FF),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(30, 30, 30, 0),
            child: BreadcrumbPageHeader(
              pageTitle: 'Buổi học trực tuyến',
              pageIcon: Icons.live_tv_rounded,
              breadcrumbs: const [
                BreadcrumbItem(label: 'Trang chủ', route: '/employee/dashboard'),
                BreadcrumbItem(label: 'Buổi học trực tuyến'),
              ],
              primaryColor: const Color(0xFF137FEC),
            ),
          ),
          _buildTopBar(),
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              color: Colors.red.shade50,
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: _isLoadingCourses
                ? const Center(child: CircularProgressIndicator())
                : _selectedCourse == null
                    ? _buildSelectCourseHint()
                    : _selectedViewMode == 0
                        ? _EmployeeDayList(
                            sessions: _sessions,
                            isLoading: _isLoadingSessions,
                            onJoin: _joinSession,
                          )
                        : _selectedViewMode == 1
                            ? _EmployeeWeekView(
                                sessions: _sessions,
                                focusedDate: _weekViewFocusedDate,
                                monthLabel: _monthYearVietnamese(_weekViewFocusedDate),
                                onFocusedDateChanged: (d) {
                                  setState(() => _weekViewFocusedDate = _weekStartOf(d));
                                },
                                onPrevWeek: () {
                                  setState(() {
                                    _weekViewFocusedDate = _weekViewFocusedDate.subtract(const Duration(days: 7));
                                  });
                                },
                                onNextWeek: () {
                                  setState(() {
                                    _weekViewFocusedDate = _weekViewFocusedDate.add(const Duration(days: 7));
                                  });
                                },
                                isLoading: _isLoadingSessions,
                                onJoin: _joinSession,
                              )
                            : _EmployeeMonthSummary(
                                sessions: _sessions,
                                isLoading: _isLoadingSessions,
                              ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectCourseHint() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_camera_front_rounded, size: 72, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            'Chọn khóa học để xem buổi live',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dùng danh sách khóa học phía trên để xem lịch và tham gia buổi học trực tuyến.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xffF9F9FF),
        border: Border(
          bottom: BorderSide(color: const Color(0xffD7DAE3).withValues(alpha: 0.6)),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          SizedBox(
            width: 320,
            child: _isLoadingCourses
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<EnrolledCourse>(
                    initialValue: _selectedCourse,
                    decoration: InputDecoration(
                      hintText: 'Chọn khóa học',
                      filled: true,
                      fillColor: const Color(0xffF1F3FD),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    isExpanded: true,
                    items: _courses
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                              c.title,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (course) {
                      if (course != null) _loadSessions(course);
                    },
                  ),
          ),
          const SizedBox(width: 20),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xffF1F3FD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _ViewModeButton(
                  label: 'Ngày',
                  selected: _selectedViewMode == 0,
                  onTap: () => setState(() => _selectedViewMode = 0),
                ),
                _ViewModeButton(
                  label: 'Tuần',
                  selected: _selectedViewMode == 1,
                  onTap: () => setState(() => _selectedViewMode = 1),
                ),
                _ViewModeButton(
                  label: 'Tháng',
                  selected: _selectedViewMode == 2,
                  onTap: () => setState(() => _selectedViewMode = 2),
                ),
              ],
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
  final VoidCallback onTap;

  const _ViewModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? const Color(0xFF137FEC) : const Color(0xff414753),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Day: danh sách buổi (giống card mentor) ---

class _EmployeeDayList extends StatelessWidget {
  final List<LiveSessionInfo> sessions;
  final bool isLoading;
  final void Function(LiveSessionInfo) onJoin;

  const _EmployeeDayList({
    required this.sessions,
    required this.isLoading,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (sessions.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có buổi live nào',
          style: TextStyle(color: Color(0xff64748B), fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: sessions.length,
      itemBuilder: (context, i) => _SessionCard(session: sessions[i], onJoin: onJoin),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final LiveSessionInfo session;
  final void Function(LiveSessionInfo) onJoin;

  const _SessionCard({required this.session, required this.onJoin});

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _statusLabel() {
    final now = DateTime.now();
    if (now.isBefore(session.startTime)) return 'Sắp diễn ra';
    if (now.isAfter(session.endTime)) return 'Đã kết thúc';
    return 'Đang diễn ra';
  }

  Color _statusColor() {
    final now = DateTime.now();
    if (now.isBefore(session.startTime)) return const Color(0xff00875A);
    if (now.isAfter(session.endTime)) return const Color(0xff717785);
    return const Color(0xff0074DB);
  }

  bool _canShowJoin() {
    final now = DateTime.now();
    if (now.isAfter(session.endTime)) return false;
    return session.meetingUrl.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                const Spacer(),
                if (_canShowJoin())
                  ElevatedButton.icon(
                    onPressed: () => onJoin(session),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF137FEC),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.video_call, size: 18),
                    label: const Text('Tham gia'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              session.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff181C22),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bắt đầu: ${_fmt(session.startTime)} — Kết thúc: ${_fmt(session.endTime)}',
              style: const TextStyle(fontSize: 13, color: Color(0xff64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Week: lưới giống mentor ---

class _EmployeeWeekView extends StatelessWidget {
  final List<LiveSessionInfo> sessions;
  final DateTime focusedDate;
  final String monthLabel;
  final ValueChanged<DateTime> onFocusedDateChanged;
  final VoidCallback onPrevWeek;
  final VoidCallback onNextWeek;
  final bool isLoading;
  final void Function(LiveSessionInfo) onJoin;

  const _EmployeeWeekView({
    required this.sessions,
    required this.focusedDate,
    required this.monthLabel,
    required this.onFocusedDateChanged,
    required this.onPrevWeek,
    required this.onNextWeek,
    required this.isLoading,
    required this.onJoin,
  });

  static const double _timeColumnWidth = 80;
  static const double _hourRowHeight = 80;

  static const _weekdayNames = [
    'THỨ 2',
    'THỨ 3',
    'THỨ 4',
    'THỨ 5',
    'THỨ 6',
    'THỨ 7',
    'CHỦ NHẬT',
  ];

  List<DateTime> _weekDays() {
    final monday = DateTime(focusedDate.year, focusedDate.month, focusedDate.day)
        .subtract(Duration(days: focusedDate.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    final hours = List.generate(14, (index) => 7 + index);
    final days = _weekDays();
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final weekStart = days.first;
    final weekEnd = weekStart.add(const Duration(days: 7));

    final visibleSessions = sessions.where((s) {
      final loc = s.startTime.toLocal();
      return !loc.isBefore(weekStart) && loc.isBefore(weekEnd);
    }).toList();

    final hasContent = visibleSessions.isNotEmpty;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // ── Header tháng/năm + prev/next ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xffE0E2EC))),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Tuần trước',
                  onPressed: onPrevWeek,
                  icon: const Icon(Icons.chevron_left, color: Color(0xFF137FEC)),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: focusedDate,
                        firstDate: DateTime(focusedDate.year - 2),
                        lastDate: DateTime(focusedDate.year + 1, 12, 31),
                      );
                      if (picked != null) onFocusedDateChanged(picked);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        monthLabel,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF137FEC),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Tuần sau',
                  onPressed: onNextWeek,
                  icon: const Icon(Icons.chevron_right, color: Color(0xFF137FEC)),
                ),
              ],
            ),
          ),

          // ── Cột ngày trong tuần ──
          Container(
            height: 82,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xffE0E2EC))),
            ),
            child: Row(
              children: [
                Container(
                  width: _timeColumnWidth,
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
                  final d = days[index];
                  final isToday = d.year == todayOnly.year &&
                      d.month == todayOnly.month &&
                      d.day == todayOnly.day;
                  return Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            isToday
                                ? const Color(0xFF137FEC).withValues(alpha: 0.06)
                                : null,
                        border: Border(
                          right:
                              index != days.length - 1
                                  ? const BorderSide(color: Color(0xffE0E2EC))
                                  : BorderSide.none,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _weekdayNames[index],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color:
                                  isToday
                                      ? const Color(0xFF137FEC)
                                      : const Color(0xff717785),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 40,
                            height: 40,
                            decoration:
                                isToday
                                    ? BoxDecoration(
                                      color: const Color(0xFF137FEC),
                                      borderRadius: BorderRadius.circular(999),
                                    )
                                    : null,
                            alignment: Alignment.center,
                            child: Text(
                              '${d.day}',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight:
                                    isToday ? FontWeight.bold : FontWeight.w600,
                                color:
                                    isToday
                                        ? Colors.white
                                        : const Color(0xff181C22),
                              ),
                            ),
                          ),
                          if (d.month != focusedDate.month)
                            Text(
                              '${d.day}/${d.month}',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xffA0A8B3),
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

          // ── Lưới giờ + sự kiện ──
          Expanded(
            child:
                !hasContent
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.event_busy, size: 64, color: Color(0xffD1D5DB)),
                          const SizedBox(height: 16),
                          const Text(
                            'Chưa có buổi live nào',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xff64748B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              sessions.isEmpty
                                  ? 'Các buổi live sẽ hiển thị tại đây khi mentor đã lên lịch.'
                                  : 'Không có buổi live nào trong tuần này. Xem chế độ Ngày để xem toàn bộ lịch.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xff94A3B8)),
                            ),
                          ),
                        ],
                      ),
                    )
                    : SingleChildScrollView(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final fullWidth = constraints.maxWidth;
                          final dayWidth = (fullWidth - _timeColumnWidth) / 7;
                          final totalHeight = hours.length * _hourRowHeight;

                          return SizedBox(
                            height: totalHeight,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: _timeColumnWidth,
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            right: BorderSide(color: Color(0xffE0E2EC)),
                                          ),
                                        ),
                                      ),
                                      ...List.generate(7, (index) {
                                        final d = days[index];
                                        final isToday = d.year == todayOnly.year &&
                                            d.month == todayOnly.month &&
                                            d.day == todayOnly.day;
                                        return Container(
                                          width: dayWidth,
                                          decoration: BoxDecoration(
                                            color:
                                                isToday
                                                    ? const Color(
                                                      0xFF137FEC,
                                                    ).withValues(alpha: 0.02)
                                                    : Colors.transparent,
                                            border: Border(
                                              right:
                                                  index != 6
                                                      ? BorderSide(
                                                        color: const Color(
                                                          0xffE0E2EC,
                                                        ).withValues(alpha: 0.8),
                                                      )
                                                      : BorderSide.none,
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                                ...List.generate(hours.length, (index) {
                                  return Positioned(
                                    top: index * _hourRowHeight,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: _hourRowHeight,
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: const Color(
                                              0xffE0E2EC,
                                            ).withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: _timeColumnWidth,
                                            padding: const EdgeInsets.only(
                                              left: 10,
                                              top: 4,
                                            ),
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
                                ...visibleSessions.map((session) {
                                  final local = session.startTime.toLocal();
                                  final et = session.endTime.toLocal();
                                  if (local.hour < 7 || local.hour > 20) {
                                    return const SizedBox.shrink();
                                  }
                                  final day = DateTime(
                                    local.year,
                                    local.month,
                                    local.day,
                                  );
                                  final diff = day.difference(days.first).inDays;
                                  if (diff < 0 || diff >= 7) {
                                    return const SizedBox.shrink();
                                  }
                                  final dayIndex = diff;
                                  final startMinutes = local.hour * 60 + local.minute;
                                  final startOffset = (startMinutes / 60) * _hourRowHeight;
                                  final durationMinutes = et.difference(session.startTime).inMinutes;
                                  final height = (durationMinutes / 60) * _hourRowHeight;

                                  return Positioned(
                                    top: startOffset + 4,
                                    left: _timeColumnWidth + (dayIndex * dayWidth) + 4,
                                    width: dayWidth - 8,
                                    height: height - 8,
                                    child: _WeekSessionChip(
                                      session: session,
                                      onJoin: onJoin,
                                    ),
                                  );
                                }),
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
}

class _WeekSessionChip extends StatelessWidget {
  final LiveSessionInfo session;
  final void Function(LiveSessionInfo) onJoin;

  const _WeekSessionChip({required this.session, required this.onJoin});

  bool get _canJoin {
    final now = DateTime.now();
    if (now.isAfter(session.endTime)) return false;
    return session.meetingUrl.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final live = now.isAfter(session.startTime) && now.isBefore(session.endTime);
    final color = live
        ? const Color(0xff0074DB)
        : now.isAfter(session.endTime)
            ? const Color(0xff717785)
            : const Color(0xff00875A);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_canJoin) ...[
            const Spacer(),
            Material(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(4),
              child: InkWell(
                onTap: () => onJoin(session),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Tham gia',
                    style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// --- Month: tóm tắt ---

class _EmployeeMonthSummary extends StatelessWidget {
  final List<LiveSessionInfo> sessions;
  final bool isLoading;

  const _EmployeeMonthSummary({
    required this.sessions,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tháng ${now.month}, ${now.year}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xff181C22),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xffF1F3FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, color: Color(0xFF137FEC)),
                const SizedBox(width: 12),
                Text(
                  'Tháng này: ${sessions.length} buổi live',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xff414753),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chuyển sang chế độ Tuần hoặc Ngày để xem chi tiết và tham gia.',
            style: TextStyle(color: Color(0xff64748B)),
          ),
        ],
      ),
    );
  }
}
