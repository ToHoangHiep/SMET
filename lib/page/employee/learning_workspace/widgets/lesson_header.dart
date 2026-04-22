import 'package:flutter/material.dart';

class LessonHeader extends StatelessWidget {
  final String title;
  final String level;
  final String lessonId;
  final bool isCompleted;
  final VoidCallback onMarkComplete;

  const LessonHeader({
    super.key,
    required this.title,
    required this.level,
    required this.lessonId,
    this.isCompleted = false,
    required this.onMarkComplete,
  });

  Color _levelColor(String level) {
    final l = level.toLowerCase();
    if (l.contains('beginner') || l.contains('sơ cấp')) {
      return const Color(0xFF22C55E);
    } else if (l.contains('intermediate') || l.contains('trung cấp')) {
      return const Color(0xFFF59E0B);
    } else if (l.contains('advanced') || l.contains('cao cấp')) {
      return const Color(0xFFEF4444);
    }
    return const Color(0xFF64748B);
  }

  IconData _levelIcon(String level) {
    final l = level.toLowerCase();
    if (l.contains('beginner') || l.contains('sơ cấp')) {
      return Icons.looks_one_rounded;
    } else if (l.contains('intermediate') || l.contains('trung cấp')) {
      return Icons.looks_two_rounded;
    } else if (l.contains('advanced') || l.contains('cao cấp')) {
      return Icons.looks_3_rounded;
    }
    return Icons.signal_cellular_alt_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final levelColor = _levelColor(level);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF8FAFC),
            const Color(0xFFF1F5F9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with level badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: levelColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_levelIcon(level), size: 14, color: levelColor),
                    const SizedBox(width: 6),
                    Text(
                      level,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: levelColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Completion badge
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Color(0xFF22C55E)),
                      SizedBox(width: 6),
                      Text(
                        'Hoàn thành',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF22C55E),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              height: 1.25,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),

          // Meta info row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                _buildMetaItem(
                  _levelIcon(level),
                  level,
                  levelColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action button
          _CompleteButton(
            isCompleted: isCompleted,
            onMarkComplete: onMarkComplete,
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
          ),
        ),
      ],
    );
  }
}

class _CompleteButton extends StatefulWidget {
  final bool isCompleted;
  final VoidCallback onMarkComplete;

  const _CompleteButton({
    required this.isCompleted,
    required this.onMarkComplete,
  });

  @override
  State<_CompleteButton> createState() => _CompleteButtonState();
}

class _CompleteButtonState extends State<_CompleteButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isCompleted) {
      return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _isHovered
                ? const Color(0xFF16A34A)
                : const Color(0xFF22C55E),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF22C55E).withValues(alpha: 0.35),
                blurRadius: _isHovered ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                'Đã hoàn thành bài học',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onMarkComplete,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isHovered
                  ? [const Color(0xFF1D4ED8), const Color(0xFF137FEC)]
                  : [const Color(0xFF137FEC), const Color(0xFF0B5FC5)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF137FEC).withValues(alpha: _isHovered ? 0.5 : 0.35),
                blurRadius: _isHovered ? 16 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.white.withValues(alpha: 0.9),
                size: 20,
              ),
              const SizedBox(width: 10),
              const Text(
                'Hoàn thành bài học',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
