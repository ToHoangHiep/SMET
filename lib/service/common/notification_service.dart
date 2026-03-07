import 'package:smet/model/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

  int get unreadCount => _unreadCount;
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);

  void initialize() {
    _notifications.clear();
    _unreadCount = 0;
    _generateMockNotifications();
  }

  void _generateMockNotifications() {
    final now = DateTime.now();
    _notifications.addAll([
      NotificationModel(
        id: '1',
        title: 'Cập nhật dự án',
        message: 'Dự án "Website ABC" đã được cập nhật tiến độ mới.',
        type: NotificationType.info,
        isRead: false,
        createdAt: now.subtract(const Duration(minutes: 30)),
      ),
      NotificationModel(
        id: '2',
        title: 'Nhắc nhở deadline',
        message: 'Dự án "Mobile App XYZ" sẽ hết hạn trong 3 ngày.',
        type: NotificationType.warning,
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      NotificationModel(
        id: '3',
        title: 'Phê duyệt thành công',
        message: 'Yêu cầu nghỉ phép của bạn đã được phê duyệt.',
        type: NotificationType.success,
        isRead: true,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      NotificationModel(
        id: '4',
        title: 'Lỗi hệ thống',
        message: 'Không thể kết nối đến server. Vui lòng thử lại sau.',
        type: NotificationType.error,
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      NotificationModel(
        id: '5',
        title: 'Thông báo họp',
        message: 'Cuộc họp team sẽ diễn ra vào lúc 14:00 hôm nay.',
        type: NotificationType.info,
        isRead: true,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ]);
    _updateUnreadCount();
  }

  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  Future<List<NotificationModel>> getNotifications() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return notifications;
  }

  Future<int> getUnreadCount() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _unreadCount;
  }

  Future<void> markAsRead(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _updateUnreadCount();
    }
  }

  Future<void> markAllAsRead() async {
    await Future.delayed(const Duration(milliseconds: 300));
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    _updateUnreadCount();
  }

  Future<void> deleteNotification(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _notifications.removeWhere((n) => n.id == notificationId);
    _updateUnreadCount();
  }

  Future<void> addNotification(NotificationModel notification) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _notifications.insert(0, notification);
    _updateUnreadCount();
  }
}
