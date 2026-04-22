import 'package:flutter/material.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/service/mentor/mentor_live_session_service.dart';
import 'package:smet/model/mentor_live_session_model.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/service/common/auth_service.dart';
import 'package:smet/model/user_model.dart';
import 'package:smet/service/common/global_notification_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer';

DateTime _calendarDateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String _weekdayVietnamese(DateTime d) {
  const names = [
    '',
    'Thứ 2',
    'Thứ 3',
    'Thứ 4',
    'Thứ 5',
    'Thứ 6',
    'Thứ 7',
    'Chủ nhật',
  ];
  return names[d.weekday];
}

/// Mentor Live Session - Web Layout
class MentorLiveSessionWeb extends StatefulWidget {
  const MentorLiveSessionWeb({super.key});

  @override
  State<MentorLiveSessionWeb> createState() => _MentorLiveSessionWebState();
}

class _MentorLiveSessionWebState extends State<MentorLiveSessionWeb> {
  int _selectedViewMode = 1; // 0=Day, 1=Week, 2=Month
  int get _viewMode => _selectedViewMode;

  // =========== STATE ===========
  final _service = MentorLiveSessionService();
  List<CourseResponse> _courses = [];
  CourseResponse? _selectedCourse;
  List<LiveSessionInfo> _sessions = [];
  bool _isLoadingCourses = false;
  bool _isLoadingSessions = false;
  bool _isAdmin = false;
  bool _isGoogleConnected = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  /// Ngày đang xem ở chế độ « Ngày » (local, không giờ).
  DateTime _dayViewFocusedDate = _calendarDateOnly(DateTime.now());

  /// Ngày đang xem ở chế độ « Tuần » — lấy thứ Hai đầu tuần.
  DateTime _weekViewFocusedDate = _calendarDateOnly(_weekStartOf(DateTime.now()));

  /// Trả về thứ Hai của tuần chứa ngày d.
  static DateTime _weekStartOf(DateTime d) {
    // weekday: 1=Mon, 7=Sun
    final diff = d.weekday - 1;
    return _calendarDateOnly(d.subtract(Duration(days: diff)));
  }

  /// Lọc sessions rơi vào tuần đang xem.
  List<LiveSessionInfo> _sessionsForFocusedWeek() {
    final start = _weekViewFocusedDate;
    final end = start.add(const Duration(days: 7));
    return _sessions.where((s) {
      final st = s.startTime;
      if (st == null) return false;
      final loc = st.toLocal();
      return !loc.isBefore(start) && loc.isBefore(end);
    }).toList();
  }

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

  List<LiveSessionInfo> _sessionsForFocusedDay() {
    final d = _dayViewFocusedDate;
    final list =
        _sessions.where((s) {
          final st = s.startTime;
          if (st == null) return false;
          final loc = st.toLocal();
          return loc.year == d.year && loc.month == d.month && loc.day == d.day;
        }).toList();
    list.sort((a, b) {
      final as = a.startTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bs = b.startTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      return as.compareTo(bs);
    });
    return list;
  }

  @override
  void initState() {
    super.initState();
    _loadMyCourses();
    _checkUserRole();
    _checkGoogleStatus();
  }

  Future<void> _loadMyCourses() async {
    setState(() => _isLoadingCourses = true);
    try {
      final result = await _service.getMyCourses(page: 0, size: 50);
      if (!mounted) return;
      setState(() {
        _courses = result.content;
        _isLoadingCourses = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      log("[LiveSession] loadCourses failed: $e");
      setState(() {
        _isLoadingCourses = false;
        _errorMessage = 'Không thể tải danh sách khóa học';
      });
    }
  }

  Future<void> _checkUserRole() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (!mounted) return;
      setState(() => _isAdmin = user.role == UserRole.ADMIN);
    } catch (e) {
      log("[LiveSession] cannot get user role: $e");
    }
  }

  Future<void> _checkGoogleStatus() async {
    try {
      final connected = await _service.checkGoogleStatus();
      if (!mounted) return;
      setState(() => _isGoogleConnected = connected);
    } catch (e) {
      if (!mounted) return;
      log("[LiveSession] checkGoogleStatus failed: $e");
      // Non-blocking: show a subtle indicator instead of crashing
      setState(() => _isGoogleConnected = false);
    }
  }

  Future<void> _connectGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      final url = await _service.getGoogleOAuthUrl();
      if (!mounted) return;
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

      // Poll for status change after user returns from OAuth flow
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      await _checkGoogleStatus();
    } catch (e) {
      if (!mounted) return;
      GlobalNotificationService.show(
        context: context,
        message: 'Không thể kết nối Google: $e',
        type: NotificationType.error,
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _showGoogleRequiredDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Cần kết nối Google Calendar',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn cần kết nối tài khoản Google để tạo buổi Live Session có link Google Meet.',
              style: TextStyle(fontSize: 15, height: 1.5, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nhấn "Kết nối Google" bên phải màn hình để liên kết tài khoản.',
                      style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xff005BAF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Kết nối Google'),
          ),
        ],
      ),
    );

    if (result == true) {
      _connectGoogle();
    }
  }

  void _showGoogleNotConnectedSnackBar() {
    GlobalNotificationService.show(
      context: context,
      message: 'Tạo thành công nhưng chưa có link. Vui lòng kết nối Google Calendar.',
      type: NotificationType.warning,
    );
  }

  Future<void> _loadSessions(CourseResponse course) async {
    setState(() {
      _selectedCourse = course;
      _isLoadingSessions = true;
      _sessions = [];
    });
    try {
      final result = await _service.getSessionsByCourse(course.id);
      if (!mounted) return;
      setState(() {
        _sessions = result;
        _isLoadingSessions = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      log("[LiveSession] loadSessions failed: $e");
      setState(() {
        _isLoadingSessions = false;
        _errorMessage = 'Không thể tải lịch live';
      });
    }
  }

  Future<void> _showEditSessionDialog(LiveSessionInfo session) async {
    final titleController = TextEditingController(text: session.title);
    DateTime startDate = session.startTime ?? DateTime.now();
    TimeOfDay startTime =
        session.startTime != null
            ? TimeOfDay.fromDateTime(session.startTime!)
            : const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime =
        session.endTime != null
            ? TimeOfDay.fromDateTime(session.endTime!)
            : const TimeOfDay(hour: 11, minute: 0);

    await showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (ctx, setDialogState) {
              String fmt(TimeOfDay t) =>
                  '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

              DateTime buildDt(TimeOfDay t) => DateTime(
                startDate.year,
                startDate.month,
                startDate.day,
                t.hour,
                t.minute,
              );

              return AlertDialog(
                title: const Text('Sửa buổi Live'),
                content: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Tiêu đề buổi live',
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: const Text('Ngày'),
                        subtitle: Text(
                          '${startDate.day}/${startDate.month}/${startDate.year}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: startDate,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 365),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (picked != null)
                              setDialogState(() => startDate = picked);
                          },
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              title: const Text('Bắt đầu'),
                              subtitle: Text(fmt(startTime)),
                              trailing: IconButton(
                                icon: const Icon(Icons.access_time),
                                onPressed: () async {
                                  final picked = await showTimePicker(
                                    context: ctx,
                                    initialTime: startTime,
                                  );
                                  if (picked != null)
                                    setDialogState(() => startTime = picked);
                                },
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              title: const Text('Kết thúc'),
                              subtitle: Text(fmt(endTime)),
                              trailing: IconButton(
                                icon: const Icon(Icons.access_time),
                                onPressed: () async {
                                  final picked = await showTimePicker(
                                    context: ctx,
                                    initialTime: endTime,
                                  );
                                  if (picked != null)
                                    setDialogState(() => endTime = picked);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Hủy'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty) {
                        GlobalNotificationService.show(
                          context: ctx,
                          message: 'Vui lòng nhập tiêu đề',
                          type: NotificationType.warning,
                        );
                        return;
                      }
                      final start = buildDt(startTime);
                      final end = buildDt(endTime);
                      try {
                        await _service.updateSession(
                          session.id,
                          UpdateLiveSessionRequest(
                            title: titleController.text.trim(),
                            startTime: start.toIso8601String(),
                            endTime: end.toIso8601String(),
                          ),
                        );
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        GlobalNotificationService.show(
                          context: context,
                          message: 'Cập nhật thành công!',
                          type: NotificationType.success,
                        );
                        if (_selectedCourse != null)
                          _loadSessions(_selectedCourse!);
                      } catch (e) {
                        if (!mounted) return;
                        GlobalNotificationService.show(
                          context: ctx,
                          message: 'Cập nhật thất bại: $e',
                          type: NotificationType.error,
                        );
                      }
                    },
                    child: const Text('Cập nhật'),
                  ),
                ],
              );
            },
          ),
    );
  }

  Future<void> _deleteSession(LiveSessionInfo session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Xóa buổi Live'),
            content: Text('Bạn có chắc muốn xóa "${session.title}" không?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Xóa', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteSession(session.id);
      if (!mounted) return;
      GlobalNotificationService.show(
        context: context,
        message: 'Xóa thành công!',
        type: NotificationType.success,
      );
      if (_selectedCourse != null) _loadSessions(_selectedCourse!);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      final isForbidden = msg.contains('403') || msg.contains('không có quyền');
      GlobalNotificationService.show(
        context: context,
        message: isForbidden
            ? 'Bạn không có quyền xóa buổi live. Chỉ Admin mới được phép xóa.'
            : 'Xóa thất bại: $e',
        type: isForbidden ? NotificationType.warning : NotificationType.error,
      );
    }
  }

  Future<void> _joinSession(LiveSessionInfo session) async {
    String? directUrl;
    if (session.meetingUrl != null && session.meetingUrl!.isNotEmpty) {
      directUrl = session.meetingUrl;
    }

    String meetingUrl;
    if (directUrl != null) {
      meetingUrl = directUrl;
    } else {
      GlobalNotificationService.show(
        context: context,
        message: 'Đang kết nối buổi live...',
        type: NotificationType.info,
      );
      try {
        meetingUrl = await _service.joinSession(session.id);
      } catch (e) {
        if (!mounted) return;
        GlobalNotificationService.show(
          context: context,
          message: e.toString().replaceFirst('Exception: ', ''),
          type: NotificationType.error,
        );
        return;
      }
    }

    final uri = Uri.parse(meetingUrl);
    final canLaunch = await canLaunchUrl(uri);
    if (canLaunch) {
      if (!mounted) return;
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      GlobalNotificationService.show(
        context: context,
        message: 'Không thể mở link: $meetingUrl',
        type: NotificationType.error,
      );
    }
  }

  Future<void> _showCreateSessionDialog({DateTime? initialDate}) async {
    if (_selectedCourse == null) {
      GlobalNotificationService.show(
        context: context,
        message: 'Vui lòng chọn khóa học trước',
        type: NotificationType.warning,
      );
      return;
    }

    const accent = Color(0xff005BAF);
    const surfaceTint = Color(0xffF4F6FC);

    final titleController = TextEditingController();
    final today = _calendarDateOnly(DateTime.now());
    DateTime startDate =
        initialDate != null
            ? _calendarDateOnly(initialDate)
            : today.add(const Duration(days: 1));
    if (startDate.isBefore(today)) startDate = today;
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 11, minute: 0);

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black38,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            String fmt(TimeOfDay t) =>
                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

            DateTime buildDt(TimeOfDay t) => DateTime(
              startDate.year,
              startDate.month,
              startDate.day,
              t.hour,
              t.minute,
            );

            Widget pickRow({
              required IconData icon,
              required String label,
              required String valueText,
              required VoidCallback onTap,
            }) {
              return Material(
                color: surfaceTint,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(icon, size: 20, color: accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                valueText,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff181C22),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.video_call_rounded,
                              color: accent,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              'Tạo buổi Live mới',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff181C22),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        controller: titleController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Tiêu đề buổi live',
                          hintText: 'VD: Kỹ năng Quản lý Đội ngũ',
                          filled: true,
                          fillColor: surfaceTint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: accent,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      pickRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Ngày',
                        valueText:
                            '${startDate.day}/${startDate.month}/${startDate.year}',
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: startDate,
                            firstDate: today,
                            lastDate: today.add(const Duration(days: 365 * 2)),
                          );
                          if (picked != null) {
                            setDialogState(
                              () => startDate = _calendarDateOnly(picked),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: pickRow(
                              icon: Icons.schedule_outlined,
                              label: 'Bắt đầu',
                              valueText: fmt(startTime),
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: ctx,
                                  initialTime: startTime,
                                );
                                if (picked != null) {
                                  setDialogState(() => startTime = picked);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: pickRow(
                              icon: Icons.schedule_outlined,
                              label: 'Kết thúc',
                              valueText: fmt(endTime),
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: ctx,
                                  initialTime: endTime,
                                );
                                if (picked != null) {
                                  setDialogState(() => endTime = picked);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: TextButton.styleFrom(
                              foregroundColor: accent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            child: const Text('Hủy'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () async {
                              if (titleController.text.trim().isEmpty) {
                                GlobalNotificationService.show(
                                  context: ctx,
                                  message: 'Vui lòng nhập tiêu đề',
                                  type: NotificationType.warning,
                                );
                                return;
                              }
                              final start = buildDt(startTime);
                              final end = buildDt(endTime);
                              if (!end.isAfter(start)) {
                                GlobalNotificationService.show(
                                  context: ctx,
                                  message: 'Giờ kết thúc phải sau giờ bắt đầu',
                                  type: NotificationType.warning,
                                );
                                return;
                              }
                              try {
                                final result = await _service.createSession(
                                  CreateLiveSessionRequest(
                                    courseId: _selectedCourse!.id,
                                    title: titleController.text.trim(),
                                    startTime: start.toIso8601String(),
                                    endTime: end.toIso8601String(),
                                  ),
                                );
                                if (!mounted || !context.mounted) return;
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (!context.mounted) return;
                                if (result.meetingUrl != null && result.meetingUrl!.isNotEmpty) {
                                  GlobalNotificationService.show(
                                    context: context,
                                    message: 'Tạo buổi live thành công!',
                                    type: NotificationType.success,
                                  );
                                } else {
                                  _showGoogleNotConnectedSnackBar();
                                }
                                _loadSessions(_selectedCourse!);
                              } catch (e) {
                                if (!ctx.mounted) return;
                                GlobalNotificationService.show(
                                  context: ctx,
                                  message: 'Tạo thất bại: $e',
                                  type: NotificationType.error,
                                );
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: const Text('Tạo'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
              pageTitle: 'Lịch Mentor',
              pageIcon: Icons.calendar_month_rounded,
              breadcrumbs: const [
                BreadcrumbItem(label: 'Tổng quan', route: '/mentor/dashboard'),
                BreadcrumbItem(label: 'Lịch mentor'),
              ],
              primaryColor: const Color(0xFF6366F1),
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
            child:
                _isLoadingCourses
                    ? const Center(child: CircularProgressIndicator())
                    : _viewMode == 0
                    ? _DayView(
                      sessions: _sessionsForFocusedDay(),
                      focusedDate: _dayViewFocusedDate,
                      onFocusedDateChanged: (d) {
                        setState(() => _dayViewFocusedDate = _calendarDateOnly(d));
                      },
                      onAddLive: () {
                        if (!_isGoogleConnected) {
                          _showGoogleRequiredDialog();
                          return;
                        }
                        _showCreateSessionDialog(
                          initialDate: _dayViewFocusedDate,
                        );
                      },
                      courseSelected: _selectedCourse != null,
                      isLoading: _isLoadingSessions,
                      onEditSession: _showEditSessionDialog,
                      onDeleteSession: _deleteSession,
                      onJoinSession: _joinSession,
                      isAdmin: _isAdmin,
                    )
                    : _viewMode == 1
                    ? _WeekView(
                      sessions: _sessionsForFocusedWeek(),
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
                      onAddLive: () {
                        if (!_isGoogleConnected) {
                          _showGoogleRequiredDialog();
                          return;
                        }
                        _showCreateSessionDialog(
                          initialDate: _weekViewFocusedDate,
                        );
                      },
                      courseSelected: _selectedCourse != null,
                      isLoading: _isLoadingSessions,
                      onEditSession: _showEditSessionDialog,
                      onDeleteSession: _deleteSession,
                      onJoinSession: _joinSession,
                      isAdmin: _isAdmin,
                    )
                    : _MonthView(
                      sessions: _sessions,
                      isLoading: _isLoadingSessions,
                    ),
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
            width: 280,
            child:
                _isLoadingCourses
                    ? const LinearProgressIndicator()
                    : DropdownButtonFormField<CourseResponse>(
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
                      items:
                          _courses.map((course) {
                            return DropdownMenuItem(
                              value: course,
                              child: Text(
                                course.title,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                      onChanged: (course) {
                        if (course != null) _loadSessions(course);
                      },
                    ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed:
                _selectedCourse != null
                    ? () {
                        if (!_isGoogleConnected) {
                          _showGoogleRequiredDialog();
                          return;
                        }
                        _showCreateSessionDialog();
                      }
                    : null,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Tạo buổi live'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff005BAF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: const StadiumBorder(),
            ),
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: 220,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: const Color(0xffF1F3FD),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
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
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isGoogleLoading ? null : _connectGoogle,
            child: MouseRegion(
              cursor: _isGoogleLoading
                  ? SystemMouseCursors.forbidden
                  : SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      _isGoogleConnected
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color:
                        _isGoogleConnected
                            ? Colors.green.shade300
                            : Colors.orange.shade300,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _isGoogleLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.orange.shade700,
                            ),
                          )
                        : Icon(
                            _isGoogleConnected
                                ? Icons.check_circle
                                : Icons.warning_amber_rounded,
                            size: 16,
                            color:
                                _isGoogleConnected
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                          ),
                    const SizedBox(width: 6),
                    Text(
                      _isGoogleLoading
                          ? 'Đang kết nối...'
                          : _isGoogleConnected
                              ? 'Google đã kết nối'
                              : 'Kết nối Google',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:
                            _isGoogleConnected
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
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
                color:
                    selected
                        ? const Color(0xff005BAF)
                        : const Color(0xff414753),
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
  final List<LiveSessionInfo> sessions;
  final DateTime focusedDate;
  final String monthLabel;
  final ValueChanged<DateTime> onFocusedDateChanged;
  final VoidCallback onPrevWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onAddLive;
  final bool courseSelected;
  final bool isLoading;
  final void Function(LiveSessionInfo)? onEditSession;
  final void Function(LiveSessionInfo)? onDeleteSession;
  final void Function(LiveSessionInfo)? onJoinSession;
  final bool isAdmin;

  const _WeekView({
    required this.sessions,
    required this.focusedDate,
    required this.monthLabel,
    required this.onFocusedDateChanged,
    required this.onPrevWeek,
    required this.onNextWeek,
    required this.onAddLive,
    required this.courseSelected,
    required this.isLoading,
    this.onEditSession,
    this.onDeleteSession,
    this.onJoinSession,
    required this.isAdmin,
  });

  static const double timeColumnWidth = 80;
  static const double hourRowHeight = 80;

  static const _weekdayNames = [
    'THỨ 2',
    'THỨ 3',
    'THỨ 4',
    'THỨ 5',
    'THỨ 6',
    'THỨ 7',
    'CHỦ NHẬT',
  ];

  /// 7 ngày trong tuần tính từ focusedDate (thứ Hai).
  List<DateTime> _weekDays() {
    return List.generate(
      7,
      (i) => _calendarDateOnly(focusedDate.add(Duration(days: i))),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    final days = _weekDays();
    final today = _calendarDateOnly(DateTime.now());
    final hours = List.generate(24, (index) => index);

    final bool hasContent = sessions.isNotEmpty;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // ── Header: tháng/năm + prev/next + thêm buổi live ──
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
                  icon: const Icon(Icons.chevron_left, color: Color(0xff005BAF)),
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
                          color: Color(0xff005BAF),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Tuần sau',
                  onPressed: onNextWeek,
                  icon: const Icon(Icons.chevron_right, color: Color(0xff005BAF)),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed:
                      courseSelected
                          ? onAddLive
                          : () {
                            GlobalNotificationService.show(
                              context: context,
                              message: 'Vui lòng chọn khóa học trước',
                              type: NotificationType.warning,
                            );
                          },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Thêm buổi live'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xff005BAF),
                    side: const BorderSide(color: Color(0xff005BAF)),
                  ),
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
                  final isToday = day == today;
                  return Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            isToday
                                ? const Color(0xff005BAF).withValues(alpha: 0.06)
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
                                      ? const Color(0xff005BAF)
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
                                      color: const Color(0xff005BAF),
                                      borderRadius: BorderRadius.circular(999),
                                    )
                                    : null,
                            alignment: Alignment.center,
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight:
                                    isToday
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                color:
                                    isToday
                                        ? Colors.white
                                        : const Color(0xff181C22),
                              ),
                            ),
                          ),
                          if (day.month != focusedDate.month)
                            Text(
                              '${day.day}/${day.month}',
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
                        children: const [
                          Icon(Icons.event_busy, size: 64, color: Color(0xffD1D5DB)),
                          SizedBox(height: 16),
                          Text(
                            'Chưa có buổi live nào',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xff64748B),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Chọn khóa học và tạo buổi live đầu tiên',
                            style: TextStyle(color: Color(0xff94A3B8)),
                          ),
                        ],
                      ),
                    )
                    : SingleChildScrollView(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final fullWidth = constraints.maxWidth;
                          final dayWidth = (fullWidth - timeColumnWidth) / 7;
                          final totalHeight = hours.length * hourRowHeight;

                          return SizedBox(
                            height: totalHeight,
                            child: Stack(
                              children: [
                                // Nền cột ngày
                                Positioned.fill(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: timeColumnWidth,
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            right: BorderSide(
                                              color: Color(0xffE0E2EC),
                                            ),
                                          ),
                                        ),
                                      ),
                                      ...List.generate(7, (index) {
                                        final day = days[index];
                                        final isToday = day == today;
                                        return Container(
                                          width: dayWidth,
                                          decoration: BoxDecoration(
                                            color:
                                                isToday
                                                    ? const Color(
                                                      0xff005BAF,
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
                                // Vạch giờ
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
                                            color: const Color(
                                              0xffE0E2EC,
                                            ).withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: timeColumnWidth,
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
                                // Thẻ buổi live
                                ...sessions.map((session) {
                                  if (session.startTime == null) {
                                    return const SizedBox.shrink();
                                  }
                                  final st = session.startTime!.toLocal();
                                  final et =
                                      session.endTime?.toLocal() ??
                                      st.add(const Duration(hours: 1));
                                  final day = _calendarDateOnly(st);

                                  // Tìm dayIndex trong tuần
                                  final diff = day.difference(days.first).inDays;
                                  if (diff < 0 || diff >= 7) {
                                    return const SizedBox.shrink();
                                  }
                                  final dayIndex = diff;

                                  // Tính vị trí pixel
                                  final startMinutes =
                                      st.hour * 60 + st.minute;
                                  final startOffset =
                                      (startMinutes / 60) * hourRowHeight;
                                  final durationMinutes =
                                      et.difference(st).inMinutes;
                                  final height =
                                      (durationMinutes / 60) * hourRowHeight;

                                  return Positioned(
                                    top: startOffset + 4,
                                    left:
                                        timeColumnWidth +
                                        (dayIndex * dayWidth) +
                                        4,
                                    width: dayWidth - 8,
                                    height: height - 8,
                                    child: _WeekEventCard(
                                      session: session,
                                      onEdit:
                                          onEditSession != null
                                              ? () => onEditSession!(session)
                                              : null,
                                      onDelete:
                                          onDeleteSession != null
                                              ? () => onDeleteSession!(session)
                                              : null,
                                      onJoin:
                                          onJoinSession != null
                                              ? () => onJoinSession!(session)
                                              : null,
                                      isAdmin: isAdmin,
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

/// Nút ⋮ cố định 22×22 + showMenu — tránh PopupMenuButton trong Row (cột hẹp bị overflow ngang ~40px).
class _WeekEventActionsButton extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isAdmin;

  const _WeekEventActionsButton({
    this.onEdit,
    this.onDelete,
    required this.isAdmin,
  });

  Future<void> _openMenu(BuildContext context) async {
    final hasEdit = onEdit != null;
    final hasDelete = isAdmin && onDelete != null;
    if (!hasEdit && !hasDelete) return;

    final box = context.findRenderObject() as RenderBox?;
    final overlay =
        Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null || !box.hasSize) return;

    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final bottomRight = box.localToGlobal(
      box.size.bottomRight(Offset.zero),
      ancestor: overlay,
    );
    final rect = Rect.fromPoints(topLeft, bottomRight);

    final chosen = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(rect, Offset.zero & overlay.size),
      items: [
        if (hasEdit)
          const PopupMenuItem<String>(
            value: 'edit',
            child: ListTile(
              dense: true,
              leading: Icon(Icons.edit_outlined, size: 18),
              title: Text('Sửa'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (hasDelete)
          const PopupMenuItem<String>(
            value: 'delete',
            child: ListTile(
              dense: true,
              leading: Icon(Icons.delete_outline, size: 18, color: Colors.red),
              title: Text('Xóa', style: TextStyle(color: Colors.red)),
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
    );

    if (!context.mounted) return;
    if (chosen == 'edit') onEdit?.call();
    if (chosen == 'delete') onDelete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final show = onEdit != null || (isAdmin && onDelete != null);
    if (!show) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openMenu(context),
        borderRadius: BorderRadius.circular(4),
        child: const SizedBox(
          width: 22,
          height: 22,
          child: Center(
            child: Icon(Icons.more_vert, color: Colors.white, size: 14),
          ),
        ),
      ),
    );
  }
}

class _WeekEventCard extends StatelessWidget {
  final LiveSessionInfo session;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onJoin;
  final bool isAdmin;

  const _WeekEventCard({
    required this.session,
    this.onEdit,
    this.onDelete,
    this.onJoin,
    required this.isAdmin,
  });

  static String _formatTimeRange(LiveSessionInfo s) {
    if (s.startTime == null) return '—';
    final start = s.startTime!;
    final end = s.endTime ?? start;
    String two(int n) => n.toString().padLeft(2, '0');
    String fmt(DateTime d) => '${two(d.hour)}:${two(d.minute)}';
    return '${fmt(start)} – ${fmt(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final color =
        session.isOngoing
            ? const Color(0xff0074DB)
            : session.isPast
            ? const Color(0xff717785)
            : const Color(0xff00875A);

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 4, 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(64),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 22),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    session.isOngoing
                        ? 'ĐANG DIỄN RA'
                        : session.isUpcoming
                        ? 'SẮP DIỄN RA'
                        : 'ĐÃ KẾT THÚC',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatTimeRange(session),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (session.meetingUrl != null)
                    const Padding(
                      padding: EdgeInsets.only(left: 2),
                      child: Icon(
                        Icons.videocam,
                        color: Colors.white70,
                        size: 11,
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3, right: 2),
                  child: Text(
                    session.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (session.meetingUrl != null && !session.isPast && onJoin != null)
                Material(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(4),
                  child: InkWell(
                    onTap: onJoin,
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.video_call, color: Colors.white, size: 9),
                          SizedBox(width: 2),
                          Text(
                            'Vào học',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: _WeekEventActionsButton(
              onEdit: onEdit,
              onDelete: onDelete,
              isAdmin: isAdmin,
            ),
          ),
        ],
      ),
    );
  }
}

// ========================= DAY VIEW =========================

class _DayView extends StatelessWidget {
  final List<LiveSessionInfo> sessions;
  final DateTime focusedDate;
  final ValueChanged<DateTime> onFocusedDateChanged;
  final VoidCallback onAddLive;
  final bool courseSelected;
  final bool isLoading;
  final void Function(LiveSessionInfo)? onEditSession;
  final void Function(LiveSessionInfo)? onDeleteSession;
  final void Function(LiveSessionInfo)? onJoinSession;
  final bool isAdmin;

  const _DayView({
    required this.sessions,
    required this.focusedDate,
    required this.onFocusedDateChanged,
    required this.onAddLive,
    required this.courseSelected,
    required this.isLoading,
    this.onEditSession,
    this.onDeleteSession,
    this.onJoinSession,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Ngày trước',
                onPressed:
                    () => onFocusedDateChanged(
                      focusedDate.subtract(const Duration(days: 1)),
                    ),
                icon: const Icon(Icons.chevron_left, color: Color(0xff005BAF)),
              ),
              const Icon(Icons.calendar_today, color: Color(0xff005BAF)),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: focusedDate,
                      firstDate: DateTime(focusedDate.year - 1),
                      lastDate: DateTime(focusedDate.year + 1, 12, 31),
                    );
                    if (picked != null) onFocusedDateChanged(picked);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '${_weekdayVietnamese(focusedDate)}, '
                      '${focusedDate.day.toString().padLeft(2, '0')}/'
                      '${focusedDate.month.toString().padLeft(2, '0')}/'
                      '${focusedDate.year}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff181C22),
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Ngày sau',
                onPressed:
                    () => onFocusedDateChanged(
                      focusedDate.add(const Duration(days: 1)),
                    ),
                icon: const Icon(Icons.chevron_right, color: Color(0xff005BAF)),
              ),
              OutlinedButton.icon(
                onPressed:
                    courseSelected
                        ? onAddLive
                        : () {
                          GlobalNotificationService.show(
                            context: context,
                            message: 'Vui lòng chọn khóa học trước',
                            type: NotificationType.warning,
                          );
                        },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Thêm buổi live'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xff005BAF),
                  side: const BorderSide(color: Color(0xff005BAF)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xffE0E2EC)),
          const SizedBox(height: 16),
          Expanded(
            child:
                sessions.isEmpty
                    ? const Center(child: Text('Không có buổi live nào'))
                    : ListView.builder(
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        return _DaySessionCard(
                          session: session,
                          onEdit:
                              onEditSession != null
                                  ? () => onEditSession!(session)
                                  : null,
                          onDelete:
                              onDeleteSession != null
                                  ? () => onDeleteSession!(session)
                                  : null,
                          onJoin:
                              onJoinSession != null
                                  ? () => onJoinSession!(session)
                                  : null,
                          isAdmin: isAdmin,
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

class _DaySessionCard extends StatelessWidget {
  final LiveSessionInfo session;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onJoin;
  final bool isAdmin;

  const _DaySessionCard({
    required this.session,
    this.onEdit,
    this.onDelete,
    this.onJoin,
    required this.isAdmin,
  });

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Widget _chip(IconData icon, String text) {
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

  @override
  Widget build(BuildContext context) {
    final color =
        session.isOngoing
            ? const Color(0xff0074DB)
            : session.isPast
            ? const Color(0xff717785)
            : const Color(0xff00875A);
    final statusColor =
        session.isOngoing
            ? Colors.red
            : session.isPast
            ? const Color(0xff717785)
            : const Color(0xff00875A);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
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
                            session.statusLabel,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withAlpha(26),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.live_tv, size: 14, color: color),
                          const SizedBox(width: 4),
                          Text(
                            'LIVE SESSION',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        session.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff181C22),
                        ),
                      ),
                    ),
                    if (session.meetingUrl != null && !session.isPast && onJoin != null)
                      Tooltip(
                        message: 'Tham gia buổi live',
                        child: InkWell(
                          onTap: onJoin,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha(13),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.red.withAlpha(51),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.video_call,
                                  size: 16,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Vào học',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (onEdit != null)
                      _ActionButton(
                        icon: Icons.edit_outlined,
                        color: const Color(0xff005BAF),
                        onTap: onEdit!,
                        tooltip: 'Sửa',
                      ),
                    if (isAdmin && onDelete != null) ...[
                      const SizedBox(width: 4),
                      _ActionButton(
                        icon: Icons.delete_outline,
                        color: Colors.red,
                        onTap: onDelete!,
                        tooltip: 'Xóa',
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (session.startTime != null)
                      _chip(
                        Icons.access_time,
                        '${_fmt(session.startTime!)} - ${_fmt(session.endTime ?? session.startTime!)}',
                      ),
                    if (session.meetingUrl != null)
                      _chip(Icons.videocam_outlined, 'Google Meet'),
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withAlpha(13),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withAlpha(51)),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

// ========================= MONTH VIEW =========================

class _MonthView extends StatelessWidget {
  final List<LiveSessionInfo> sessions;
  final bool isLoading;
  const _MonthView({required this.sessions, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

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
          Expanded(
            child: Column(
              children: [
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
                Expanded(
                  child: Column(
                    children: [
                      _monthWeekRow([
                        _monthDayCell(27, false, [
                          _monthEventItem(
                            const Color(0xff0074DB),
                            'Live Session',
                            Icons.live_tv,
                          ),
                          _monthEventItem(
                            const Color(0xff455F89),
                            'Workshop',
                            Icons.groups,
                          ),
                        ]),
                        _monthDayCell(28, true, [
                          _monthEventItem(
                            const Color(0xff0074DB),
                            'Live Session',
                            Icons.live_tv,
                          ),
                        ]),
                        _monthDayCell(29, false, []),
                        _monthDayCell(30, false, []),
                        _monthDayCell(31, false, []),
                        _monthDayCell(1, false, []),
                        _monthDayCell(2, false, []),
                      ]),
                      Expanded(
                        child: Row(
                          children: List.generate(
                            7,
                            (i) => const Expanded(child: SizedBox()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xffF1F3FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.insights, color: Color(0xff005BAF)),
                const SizedBox(width: 12),
                Text(
                  'Tháng này: ${sessions.length} buổi live',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xff414753),
                  ),
                ),
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
        children:
            cells.asMap().entries.map((entry) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: entry.key < cells.length - 1 ? 4 : 0,
                  ),
                  child: entry.value,
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _monthDayCell(int day, bool selected, List<Widget> events) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color:
              selected
                  ? const Color(0xff005BAF).withAlpha(13)
                  : Colors.transparent,
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
                color:
                    selected
                        ? const Color(0xff005BAF)
                        : const Color(0xff181C22),
              ),
            ),
            if (events.isNotEmpty) ...[
              const SizedBox(height: 4),
              ...events.take(3),
            ],
          ],
        ),
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
