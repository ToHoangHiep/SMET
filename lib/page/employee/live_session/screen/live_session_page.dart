import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/service/employee/lms_service.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/service/common/global_notification_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer';

class LiveSessionPage extends StatefulWidget {
  final String? courseId;

  const LiveSessionPage({super.key, this.courseId});

  @override
  State<LiveSessionPage> createState() => _LiveSessionPageState();
}

class _LiveSessionPageState extends State<LiveSessionPage> {
  List<LiveSessionInfo> _sessions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.courseId != null) {
      _loadSessions();
    }
  }

  Future<void> _loadSessions() async {
    if (widget.courseId == null) return;
    setState(() => _isLoading = true);

    try {
      final sessions = await LmsService.getLiveSessions(widget.courseId!);
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải buổi live';
        _isLoading = false;
      });
    }
  }

  String _formatDateTime(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month-1]} ${dt.year} • $hour:$minute';
  }

  bool _isUpcoming(DateTime dt) => dt.isAfter(DateTime.now());

  bool _isLive(DateTime start, DateTime end) {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }

  Future<void> _openJoinDialog(LiveSessionInfo session) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Đang kết nối buổi live...'),
          ],
        ),
      ),
    );

    try {
      final meetingUrl = await LmsService.joinSession(session.id);

      if (!mounted) return;
      Navigator.of(context).pop();

      final uri = Uri.parse(meetingUrl);
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        GlobalNotificationService.show(
          context: context,
          message: 'Không thể mở link: $meetingUrl',
          type: NotificationType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      GlobalNotificationService.show(
        context: context,
        message: e.toString().replaceFirst('Exception: ', ''),
        type: NotificationType.error,
      );
    }
  }

  Widget _buildSessionCard(LiveSessionInfo session) {
    final isUpcoming = _isUpcoming(session.startTime);
    final isLive = _isLive(session.startTime, session.endTime);
    final isPast = session.endTime.isBefore(DateTime.now());

    Color statusColor;
    String statusText;
    IconData statusIcon;
    if (isLive) {
      statusColor = Colors.red;
      statusText = 'ĐANG DIỄN RA';
      statusIcon = Icons.circle;
    } else if (isUpcoming) {
      statusColor = Colors.blue;
      statusText = 'SẮP DIỄN RA';
      statusIcon = Icons.schedule;
    } else {
      statusColor = Colors.grey;
      statusText = 'ĐÃ KẾT THÚC';
      statusIcon = Icons.check_circle_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isLive && session.meetingUrl.isNotEmpty
              ? () => _openJoinDialog(session)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(26),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLive) ...[
                            _PulsingDot(),
                            const SizedBox(width: 6),
                          ],
                          Icon(statusIcon, color: statusColor, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDateTime(session.startTime),
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  session.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoChip(Icons.access_time, 'Bắt đầu: ${_formatDateTime(session.startTime)}'),
                    const SizedBox(width: 12),
                    _buildInfoChip(Icons.access_time_filled, 'Kết thúc: ${_formatDateTime(session.endTime)}'),
                  ],
                ),
                if (isLive && session.meetingUrl.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: _JoinButton(session: session),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
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
              fontSize: 11,
              padding: EdgeInsets.zero,
            ),
            const Text(
              'Buổi học trực tuyến',
              style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.grey),
            onPressed: () => context.go('/employee/dashboard'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadSessions, child: const Text('Thử lại')),
                    ],
                  ),
                )
              : _sessions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.videocam_off, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('Chưa có buổi live nào', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _sessions.length,
                      itemBuilder: (ctx, i) => _buildSessionCard(_sessions[i]),
                    ),
    );
  }
}

class _JoinButton extends StatefulWidget {
  final LiveSessionInfo session;

  const _JoinButton({required this.session});

  @override
  State<_JoinButton> createState() => _JoinButtonState();
}

class _JoinButtonState extends State<_JoinButton> {
  bool _isLoading = false;

  Future<void> _join() async {
    final state = context.findAncestorStateOfType<_LiveSessionPageState>();
    if (state != null) {
      state._openJoinDialog(widget.session);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _join,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: _isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.video_call),
      label: const Text('Tham gia ngay'),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this)..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.withOpacity(_animation.value),
          ),
        );
      },
    );
  }
}
