import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smet/service/common/notification_service.dart';
import 'package:smet/page/shared/widgets/notification_bell_panel.dart';

class NotificationBellButton extends StatefulWidget {
  final Color primaryColor;
  final VoidCallback? onOpenPanel;

  const NotificationBellButton({
    super.key,
    required this.primaryColor,
    this.onOpenPanel,
  });

  @override
  State<NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<NotificationBellButton>
    with SingleTickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _refreshTimer;
  bool _hasUnread = false;
  bool _panelOpen = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _checkUnreadStatus();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkUnreadStatus();
    });
  }

  Future<void> _checkUnreadStatus() async {
    final count = await _notificationService.getUnreadCount();
    if (mounted) {
      setState(() {
        _hasUnread = count > 0;
        if (_hasUnread && !_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        } else if (!_hasUnread) {
          _pulseController.stop();
          _pulseController.reset();
        }
      });
    }
  }

  void _showPanel(BuildContext context) {
    if (_panelOpen) return;
    setState(() => _panelOpen = true);

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      useSafeArea: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: NotificationBellPanel(
            primaryColor: widget.primaryColor,
            onClose: () {
              Navigator.of(dialogContext).pop();
            },
            onViewAll: () {
              widget.onOpenPanel?.call();
              Navigator.of(dialogContext).pop();
            },
          ),
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() => _panelOpen = false);
        _checkUnreadStatus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AnimatedIconButton(
      icon: Icons.notifications_outlined,
      primaryColor: widget.primaryColor,
      hasUnread: _hasUnread,
      pulseAnimation: _pulseAnimation,
      onPressed: () => _showPanel(context),
      tooltip: 'Thông báo',
    );
  }
}

class _AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final Color primaryColor;
  final bool hasUnread;
  final Animation<double> pulseAnimation;
  final VoidCallback onPressed;
  final String tooltip;

  const _AnimatedIconButton({
    required this.icon,
    required this.primaryColor,
    required this.hasUnread,
    required this.pulseAnimation,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isHovered
                  ? widget.primaryColor.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SizedBox(
              width: 24,
              height: 24,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedBuilder(
                    animation: widget.pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: widget.hasUnread ? widget.pulseAnimation.value : 1.0,
                        child: Icon(
                          widget.icon,
                          color: _isHovered
                              ? widget.primaryColor
                              : Colors.grey[600],
                          size: 22,
                        ),
                      );
                    },
                  ),
                  if (widget.hasUnread)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: AnimatedBuilder(
                        animation: widget.pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: widget.pulseAnimation.value,
                            child: child,
                          );
                        },
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFEF4444),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
