import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';

enum NotificationType { success, error, warning, info }

class GlobalNotificationService {
  static void show({
    required BuildContext context,
    required String message,
    NotificationType type = NotificationType.success,
  }) {
    if (!context.mounted) {
      debugPrint('[GlobalNotificationService.show] STOP: context not mounted, message=$message');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _NotificationDialog(
        message: message,
        type: type,
      ),
    );
  }

  static Future<void> showAsync({
    required BuildContext context,
    required Future<String?> Function() messageProvider,
    NotificationType successType = NotificationType.success,
    NotificationType errorType = NotificationType.error,
  }) async {
    try {
      final message = await messageProvider();
      if (!context.mounted) return;
      if (message != null && message.isNotEmpty) {
        show(context: context, message: message, type: successType);
      }
    } catch (e) {
      if (!context.mounted) return;
      show(
        context: context,
        message: e.toString(),
        type: errorType,
      );
    }
  }
}

class _NotificationDialog extends StatelessWidget {
  final String message;
  final NotificationType type;

  const _NotificationDialog({
    required this.message,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 360,
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getBackgroundColor(),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(),
                color: _getColor(),
                size: 48,
              ),
            ),
            SizedBox(height: 20),
            Text(
              _getTitle(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _getColor(),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getColor(),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Đóng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (type) {
      case NotificationType.success:
        return Icons.check_rounded;
      case NotificationType.error:
        return Icons.close_rounded;
      case NotificationType.warning:
        return Icons.warning_rounded;
      case NotificationType.info:
        return Icons.info_rounded;
    }
  }

  Color _getColor() {
    switch (type) {
      case NotificationType.success:
        return Color(0xFF22C55E);
      case NotificationType.error:
        return Color(0xFFEF4444);
      case NotificationType.warning:
        return Color(0xFFF59E0B);
      case NotificationType.info:
        return Color(0xFF3B82F6);
    }
  }

  Color _getBackgroundColor() {
    switch (type) {
      case NotificationType.success:
        return Color(0xFFDCFCE7);
      case NotificationType.error:
        return Color(0xFFFEE2E2);
      case NotificationType.warning:
        return Color(0xFFFEF3C7);
      case NotificationType.info:
        return Color(0xFFDBEAFE);
    }
  }

  String _getTitle() {
    switch (type) {
      case NotificationType.success:
        return 'Thành công';
      case NotificationType.error:
        return 'Lỗi';
      case NotificationType.warning:
        return 'Cảnh báo';
      case NotificationType.info:
        return 'Thông tin';
    }
  }
}
