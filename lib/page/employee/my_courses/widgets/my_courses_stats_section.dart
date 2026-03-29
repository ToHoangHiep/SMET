import 'package:flutter/material.dart';
import 'package:smet/service/employee/lms_service.dart';

class MyCoursesStatsSection extends StatelessWidget {
  final List<EnrolledCourse> courses;
  /// Tong tu API (pagination); neu null thi dung so phan tu tren trang hien tai.
  final int? totalCountOverride;

  const MyCoursesStatsSection({
    super.key,
    required this.courses,
    this.totalCountOverride,
  });

  @override
  Widget build(BuildContext context) {
    final total = totalCountOverride ?? courses.length;
    final inProgress = courses
        .where((c) => c.status == EnrollmentStatus.inProgress)
        .length;
    final completed = courses
        .where((c) => c.status == EnrollmentStatus.completed)
        .length;
    final overdue = courses
        .where((c) => c.deadlineStatus == DeadlineStatus.overdue)
        .length;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Tong khoa hoc',
            value: total.toString(),
            icon: Icons.library_books_rounded,
            color: const Color(0xFF137FEC),
            bgColor: const Color(0xFFE8F2FE),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'Dang hoc',
            value: inProgress.toString(),
            icon: Icons.play_circle_outline,
            color: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFEF3C7),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'Hoan thanh',
            value: completed.toString(),
            icon: Icons.check_circle_outline,
            color: const Color(0xFF22C55E),
            bgColor: const Color(0xFFDCFCE7),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'Qua han',
            value: overdue.toString(),
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFEF4444),
            bgColor: const Color(0xFFFEE2E2),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(_isHovered ? 1.015 : 1.0),
        transformAlignment: Alignment.center,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered
                  ? widget.color.withValues(alpha: 0.25)
                  : const Color(0xFFE5E7EB),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.06 : 0.03),
                blurRadius: _isHovered ? 12 : 8,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Rounded icon container with subtle top gradient
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    // Subtle top gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              widget.color.withValues(alpha: 0.08),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Icon(widget.icon, color: widget.color, size: 24),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: widget.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
