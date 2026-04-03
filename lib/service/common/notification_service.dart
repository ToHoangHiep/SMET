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

  Future<void> _fetchNotifications({int page = 0, int size = 10}) async {
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
        List<dynamic> content;

        if (data is Map) {
          final pageData = data['content'] ?? data['data'] ?? [];
          content = pageData is List ? pageData : [];
        } else if (data is List) {
          content = data;
        } else {
          content = [];
        }

        _notifications.clear();
        for (final item in content) {
          _notifications.add(NotificationModel.fromJson(item));
        }
        _updateUnreadCount();
      }
    } catch (e) {
      log("NotificationService._fetchNotifications failed: $e");
    }
  }

  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  Future<List<NotificationModel>> getNotifications({int page = 0, int size = 10}) async {
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
        if (data is num) {
          _unreadCount = data.toInt();
        } else if (data is Map) {
          _unreadCount = (data['count'] ?? data['unreadCount'] ?? 0).toInt();
        }
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

  Future<void> addNotification(NotificationModel notification) async {
    _notifications.insert(0, notification);
    _updateUnreadCount();
  }
}
