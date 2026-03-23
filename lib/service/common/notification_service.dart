import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smet/model/notification_model.dart';
import 'package:smet/service/common/base_url.dart';
import 'package:smet/service/common/auth_service.dart';
import 'dart:developer';

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
  }

  Future<void> _fetchNotifications({int page = 0, int size = 20}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      final url = Uri.parse("$baseUrl/notifications?page=$page&size=$size");
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> list;
        if (data is List) {
          list = data;
        } else if (data is Map) {
          list = data['data'] ?? data['content'] ?? [];
        } else {
          list = [];
        }

        _notifications.clear();
        for (final item in list) {
          _notifications.add(_parseNotification(item));
        }
        _updateUnreadCount();
      }
    } catch (e) {
      log("NotificationService._fetchNotifications failed: $e");
    }
  }

  NotificationModel _parseNotification(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? json['body'] ?? '',
      type: _parseType(json['type']),
      isRead: json['isRead'] ?? json['read'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  NotificationType _parseType(String? type) {
    switch (type?.toUpperCase()) {
      case 'WARNING':
      case 'WARN':
        return NotificationType.warning;
      case 'ERROR':
        return NotificationType.error;
      case 'SUCCESS':
        return NotificationType.success;
      default:
        return NotificationType.info;
    }
  }

  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  Future<List<NotificationModel>> getNotifications({int page = 0, int size = 20}) async {
    await _fetchNotifications(page: page, size: size);
    return notifications;
  }

  Future<int> getUnreadCount() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return 0;

      final url = Uri.parse("$baseUrl/notifications/unread-count");
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _unreadCount = data['count'] ?? data['unreadCount'] ?? 0;
        return _unreadCount;
      }
    } catch (e) {
      log("NotificationService.getUnreadCount failed: $e");
    }
    return _unreadCount;
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      final url = Uri.parse("$baseUrl/notifications/$notificationId/read");
      final response = await http.put(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
          _updateUnreadCount();
        }
      }
    } catch (e) {
      log("NotificationService.markAsRead failed: $e");
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      final url = Uri.parse("$baseUrl/notifications/mark-all-read");
      final response = await http.put(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        for (int i = 0; i < _notifications.length; i++) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
        _updateUnreadCount();
      }
    } catch (e) {
      log("NotificationService.markAllAsRead failed: $e");
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      final url = Uri.parse("$baseUrl/notifications/$notificationId");
      final response = await http.delete(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _notifications.removeWhere((n) => n.id == notificationId);
        _updateUnreadCount();
      }
    } catch (e) {
      log("NotificationService.deleteNotification failed: $e");
    }
  }

  Future<void> addNotification(NotificationModel notification) async {
    _notifications.insert(0, notification);
    _updateUnreadCount();
  }
}
