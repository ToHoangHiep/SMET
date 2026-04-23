import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/service/employee/lms_service.dart';
import 'package:smet/service/common/global_notification_service.dart';

import 'package:url_launcher/url_launcher.dart';

class EmployeeLiveSessionMobile extends StatefulWidget {
  const EmployeeLiveSessionMobile({super.key, this.initialCourseId});

  final String? initialCourseId;

  @override
  State<EmployeeLiveSessionMobile> createState() => _EmployeeLiveSessionMobileState();
}

class _EmployeeLiveSessionMobileState extends State<EmployeeLiveSessionMobile> {
  List<EnrolledCourse> _courses = [];
  EnrolledCourse? _selectedCourse;
  List<LiveSessionInfo> _sessions = [];
  bool _isLoadingCourses = false;
  bool _isLoadingSessions = false;
  String? _errorMessage;

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
        if (preselected != null) {
          _selectedCourse = preselected;
        } else if (_courses.isNotEmpty) {
          _selectedCourse = _courses.first;
        }
      });
      if (preselected != null) {
        _loadSessions(preselected);
      } else if (_courses.isNotEmpty) {
        _loadSessions(_courses.first);
      }
    } catch (e) {
      log('[EmployeeLiveSessionMobile] loadCourses failed: $e');
      if (!mounted) return;
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
      log('[EmployeeLiveSessionMobile] loadSessions failed: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingSessions = false;
        _errorMessage = 'Không thể tải buổi live';
      });
    }
  }

  Future<void> _joinSession(LiveSessionInfo session) async {
    String? directUrl;
    if (session.meetingUrl.isNotEmpty) {
      directUrl = session.meetingUrl;
    }

    late String meetingUrl;
    if (directUrl != null) {
      meetingUrl = directUrl;
    } else {
      GlobalNotificationService.show(
        context: context,
        message: 'Đang kết nối buổi live...',
        type: NotificationType.info,
      );
      try {
        meetingUrl = await LmsService.joinSession(session.id);
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
    if (!mounted) return;
    if (canLaunch) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      GlobalNotificationService.show(
        context: context,
        message: 'Không thể mở link: $meetingUrl',
        type: NotificationType.error,
      );
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _fmtTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _statusLabel(LiveSessionInfo session) {
    final now = DateTime.now();
    if (now.isBefore(session.startTime)) return 'Sắp diễn ra';
    if (now.isAfter(session.endTime)) return 'Đã kết thúc';
    return 'Đang diễn ra';
  }

  Color _statusColor(LiveSessionInfo session) {
    final now = DateTime.now();
    if (now.isBefore(session.startTime)) return const Color(0xFF00875A);
    if (now.isAfter(session.endTime)) return const Color(0xFF717785);
    return const Color(0xFF005BAF);
  }

  bool _canJoin(LiveSessionInfo session) {
    final now = DateTime.now();
    if (now.isAfter(session.endTime)) return false;
    return session.meetingUrl.isNotEmpty;
  }

  Widget _buildSessionCard(LiveSessionInfo session) {
    final color = _statusColor(session);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showSessionDetail(session),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_statusLabel(session) == 'Đang diễn ra')
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red.withAlpha((255 * 0.7).toInt()),
                              ),
                            ),
                          Icon(
                            _statusLabel(session) == 'Sắp diễn ra'
                                ? Icons.schedule
                                : _statusLabel(session) == 'Đang diễn ra'
                                    ? Icons.live_tv
                                    : Icons.check_circle_outline,
                            color: color,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _statusLabel(session),
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _fmtDate(session.startTime),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  session.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '${_fmtTime(session.startTime)} - ${_fmtTime(session.endTime)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (_canJoin(session)) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _joinSession(session),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF005BAF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.video_call, size: 18),
                      label: const Text('Tham gia ngay'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSessionDetail(LiveSessionInfo session) {
    final color = _statusColor(session);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _statusLabel(session),
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              session.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            _detailRow(Icons.calendar_today, 'Ngày', _fmtDate(session.startTime)),
            const SizedBox(height: 10),
            _detailRow(Icons.access_time, 'Bắt đầu', _fmtTime(session.startTime)),
            const SizedBox(height: 10),
            _detailRow(Icons.access_time_filled, 'Kết thúc', _fmtTime(session.endTime)),
            const SizedBox(height: 24),
            if (_canJoin(session))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _joinSession(session);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.video_call),
                  label: const Text('Tham gia buổi live'),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3FD),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF137FEC)),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SharedBreadcrumb(
              items: const [
                BreadcrumbItem(label: 'Trang chủ', route: '/employee/dashboard'),
                BreadcrumbItem(label: 'Buổi học trực tuyến'),
              ],
              primaryColor: const Color(0xFF137FEC),
              fontSize: 10,
              padding: EdgeInsets.zero,
            ),
            const Text(
              'Buổi học trực tuyến',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Course selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chọn khóa học',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                if (_isLoadingCourses)
                  const LinearProgressIndicator()
                else if (_courses.isEmpty)
                  Text(
                    'Bạn chưa đăng ký khóa học nào',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F6FC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<EnrolledCourse>(
                        value: _selectedCourse,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: _courses
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(
                                  c.title,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (course) {
                          if (course != null) _loadSessions(course);
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),

          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // Sessions list
          Expanded(
            child: _isLoadingSessions
                ? const Center(child: CircularProgressIndicator())
                : _selectedCourse == null
                    ? _buildEmptySelectCourse()
                    : _sessions.isEmpty
                        ? _buildEmptySessions()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _sessions.length,
                            itemBuilder: (ctx, i) => _buildSessionCard(_sessions[i]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySelectCourse() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Vui lòng chọn khóa học',
              style: TextStyle(fontSize: 17, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySessions() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có buổi live nào',
              style: TextStyle(fontSize: 17, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Các buổi học trực tuyến sẽ xuất hiện khi mentor lên lịch.',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
