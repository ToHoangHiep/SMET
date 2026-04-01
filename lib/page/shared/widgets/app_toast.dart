import 'package:flutter/material.dart';

/// Toast hiển thị giữa màn hình, bo góc, có animation — dùng chung cho cả dự án.
/// Thay cho [SnackBar] full-width ở đáy khi cần thông báo nổi bật.
enum AppToastVariant { success, error, info }

class AppToast {
  AppToast._();

  static OverlayEntry? _active;

  static void show(
    BuildContext context,
    String message, {
    AppToastVariant variant = AppToastVariant.success,
    Duration visibleDuration = const Duration(milliseconds: 2200),
  }) {
    _active?.remove();
    _active = null;

    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _AppToastOverlay(
        message: message,
        variant: variant,
        visibleDuration: visibleDuration,
        onFinished: () {
          entry.remove();
          if (_active == entry) _active = null;
        },
      ),
    );
    _active = entry;
    overlay.insert(entry);
  }
}

class _AppToastOverlay extends StatefulWidget {
  final String message;
  final AppToastVariant variant;
  final Duration visibleDuration;
  final VoidCallback onFinished;

  const _AppToastOverlay({
    required this.message,
    required this.variant,
    required this.visibleDuration,
    required this.onFinished,
  });

  @override
  State<_AppToastOverlay> createState() => _AppToastOverlayState();
}

class _AppToastOverlayState extends State<_AppToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  late final Animation<double> _slideY;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 300),
    );
    _scale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      ),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
        reverseCurve: Curves.easeIn,
      ),
    );
    _slideY = Tween<double>(begin: 18, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );
    _controller.forward();
    _scheduleDismiss();
  }

  Future<void> _scheduleDismiss() async {
    await Future<void>.delayed(widget.visibleDuration);
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) widget.onFinished();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _backgroundColor() {
    switch (widget.variant) {
      case AppToastVariant.success:
        return const Color(0xFF22C55E);
      case AppToastVariant.error:
        return const Color(0xFFEF4444);
      case AppToastVariant.info:
        return const Color(0xFF137FEC);
    }
  }

  IconData _icon() {
    switch (widget.variant) {
      case AppToastVariant.success:
        return Icons.check_circle_rounded;
      case AppToastVariant.error:
        return Icons.error_rounded;
      case AppToastVariant.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: IgnorePointer(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _opacity.value,
                child: Transform.translate(
                  offset: Offset(0, _slideY.value),
                  child: Transform.scale(
                    scale: _scale.value,
                    child: child,
                  ),
                ),
              );
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: _backgroundColor(),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_icon(), color: Colors.white, size: 26),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension AppToastContext on BuildContext {
  void showAppToast(
    String message, {
    AppToastVariant variant = AppToastVariant.success,
    Duration visibleDuration = const Duration(milliseconds: 2200),
  }) {
    AppToast.show(this, message, variant: variant, visibleDuration: visibleDuration);
  }
}
