import 'package:flutter/material.dart';

/// Coursera-style animation helpers — reusable, subtle transitions.
class AppAnimations {
  AppAnimations._();

  /// Standard durations
  static const Duration standard = Duration(milliseconds: 300);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration slow = Duration(milliseconds: 500);

  /// Standard curves
  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve smoothCurve = Curves.easeInOutCubic;
}

/// Animated card wrapper that lifts on hover — use in GridView/ListView.
class AnimatedCourseCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double hoverScale;
  final Duration duration;
  final Curve curve;

  const AnimatedCourseCard({
    super.key,
    required this.child,
    this.onTap,
    this.hoverScale = 1.02,
    this.duration = AppAnimations.standard,
    this.curve = AppAnimations.standardCurve,
  });

  @override
  State<AnimatedCourseCard> createState() => _AnimatedCourseCardState();
}

class _AnimatedCourseCardState extends State<AnimatedCourseCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: widget.duration,
        curve: widget.curve,
        transform: Matrix4.identity()
          ..scale(_isHovered ? widget.hoverScale : 1.0),
        transformAlignment: Alignment.center,
        child: GestureDetector(
          onTap: widget.onTap,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Fade + slide animation for list item entrance.
class AnimatedFadeSlide extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;
  final Offset slideOffset;

  const AnimatedFadeSlide({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = const Duration(milliseconds: 50),
    this.duration = AppAnimations.standard,
    this.slideOffset = const Offset(0, 12),
  });

  @override
  State<AnimatedFadeSlide> createState() => _AnimatedFadeSlideState();
}

class _AnimatedFadeSlideState extends State<AnimatedFadeSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.smoothCurve),
    );
    _slide = Tween<Offset>(begin: widget.slideOffset, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.standardCurve),
    );

    Future.delayed(widget.delay * widget.index, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Animated linear progress bar with gradient and smooth width transition.
class AnimatedProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double height;
  final Color? backgroundColor;
  final Color? valueColor;
  final Gradient? gradient;
  final BorderRadius? borderRadius;

  const AnimatedProgressBar({
    super.key,
    required this.progress,
    this.height = 6,
    this.backgroundColor,
    this.valueColor,
    this.gradient,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final radius = borderRadius ?? BorderRadius.circular(999);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFFE5E7EB),
        borderRadius: radius,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedContainer(
                duration: AppAnimations.standard,
                curve: AppAnimations.standardCurve,
                width: constraints.maxWidth * clamped,
                height: height,
                decoration: BoxDecoration(
                  gradient: gradient,
                  color: gradient == null
                      ? (valueColor ?? const Color(0xFF137FEC))
                      : null,
                  borderRadius: radius,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Circular progress ring — great for course completion % in My Courses.
class CircularProgressRing extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color? backgroundColor;
  final Color? progressColor;
  final TextStyle? textStyle;
  final bool showPercent;
  final Duration duration;

  const CircularProgressRing({
    super.key,
    required this.progress,
    this.size = 60,
    this.strokeWidth = 5,
    this.backgroundColor,
    this.progressColor,
    this.textStyle,
    this.showPercent = true,
    this.duration = AppAnimations.standard,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final color = progressColor ??
        (clamped >= 1.0 ? const Color(0xFF22C55E) : const Color(0xFF137FEC));

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: clamped),
            duration: duration,
            curve: AppAnimations.standardCurve,
            builder: (context, value, _) {
              return CustomPaint(
                size: Size(size, size),
                painter: _CircularPainter(
                  progress: value,
                  strokeWidth: strokeWidth,
                  backgroundColor: backgroundColor ?? const Color(0xFFE5E7EB),
                  progressColor: color,
                ),
              );
            },
          ),
          if (showPercent)
            Text(
              '${(clamped * 100).round()}%',
              style: textStyle ??
                  TextStyle(
                    fontSize: size * 0.22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
        ],
      ),
    );
  }
}

class _CircularPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  _CircularPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -3.14159 / 2;
    final sweepAngle = 2 * 3.14159 * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularPainter old) =>
      old.progress != progress;
}

/// Pulsing dot — used for loading/attention states.
class PulsingDot extends StatefulWidget {
  final Color? color;
  final double size;

  const PulsingDot({super.key, this.color, this.size = 8});

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: (widget.color ?? const Color(0xFF137FEC))
                .withValues(alpha: _animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
