// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:smet/model/notification_model.dart';
// import 'package:smet/service/common/current_user_store.dart';
// import 'package:smet/service/common/notification_service.dart';
// import '../widgets/shell/notification_top_header.dart';
// import '../widgets/shell/notification_sidebar.dart';

// class NotificationPage extends StatefulWidget {
//   const NotificationPage({super.key});

//   @override
//   State<NotificationPage> createState() => _NotificationPageState();
// }

// class _NotificationPageState extends State<NotificationPage> {
//   final NotificationService _notificationService = NotificationService();
//   final Color _primaryColor = const Color(0xFF137FEC);
//   final Color _bgLight = const Color(0xFFF3F6FC);

//   List<NotificationModel> _notifications = [];
//   bool _isLoading = true;
//   String _filterType = 'ALL';

//   final List<Map<String, String>> _filterOptions = const [
//     {'value': 'ALL', 'label': 'Tất cả'},
//     {'value': 'UNREAD', 'label': 'Chưa đọc'},
//     {'value': 'READ', 'label': 'Đã đọc'},
//   ];

//   List<NotificationModel> get _filteredNotifications {
//     return _notifications.where((notification) {
//       switch (_filterType) {
//         case 'UNREAD':
//           return !notification.isRead;
//         case 'READ':
//           return notification.isRead;
//         default:
//           return true;
//       }
//     }).toList();
//   }

//   @override
//   void initState() {
//     super.initState();
//     _fetchNotifications();
//   }

//   Future<void> _fetchNotifications() async {
//     setState(() => _isLoading = true);
//     _notificationService.initialize();
//     final notifications = await _notificationService.getNotifications();
//     setState(() {
//       _notifications = notifications;
//       _isLoading = false;
//     });
//   }

//   Future<void> _markAsRead(String notificationId) async {
//     await _notificationService.markAsRead(notificationId);
//     await _fetchNotifications();
//   }

//   Future<void> _markAllAsRead() async {
//     await _notificationService.markAllAsRead();
//     await _fetchNotifications();
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Đã đánh dấu tất cả là đã đọc'),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }

//   Future<void> _deleteNotification(String notificationId) async {
//     await _notificationService.deleteNotification(notificationId);
//     await _fetchNotifications();
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Đã xóa thông báo'),
//         backgroundColor: Colors.orange,
//       ),
//     );
//   }

//   Color _getNotificationColor(NotificationType type) {
//     switch (type) {
//       case NotificationType.info:
//         return Colors.blue;
//       case NotificationType.warning:
//         return Colors.orange;
//       case NotificationType.success:
//         return Colors.green;
//       case NotificationType.error:
//         return Colors.red;
//     }
//   }

//   IconData _getNotificationIcon(NotificationType type) {
//     switch (type) {
//       case NotificationType.info:
//         return Icons.info_outline;
//       case NotificationType.warning:
//         return Icons.warning_amber_outlined;
//       case NotificationType.success:
//         return Icons.check_circle_outline;
//       case NotificationType.error:
//         return Icons.error_outline;
//     }
//   }

//   String _formatTimeAgo(DateTime dateTime) {
//     final now = DateTime.now();
//     final difference = now.difference(dateTime);

//     if (difference.inMinutes < 1) {
//       return 'Vừa xong';
//     } else if (difference.inMinutes < 60) {
//       return '${difference.inMinutes} phút trước';
//     } else if (difference.inHours < 24) {
//       return '${difference.inHours} giờ trước';
//     } else if (difference.inDays < 7) {
//       return '${difference.inDays} ngày trước';
//     } else {
//       return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: _bgLight,
//       body: SafeArea(
//         child: Row(
//           children: [
//             NotificationSidebar(
//               primaryColor: _primaryColor,
//               userDisplayName: CurrentUserStore.currentUser.fullName,
//               onLogout: () => context.go('/login'),
//             ),
//             Expanded(
//               child: Column(
//                 children: [
//                   NotificationTopHeader(
//                     primaryColor: _primaryColor,
//                     filterOptions: _filterOptions,
//                     selectedFilter: _filterType,
//                     onFilterChanged: (value) {
//                       setState(() => _filterType = value);
//                     },
//                     onMarkAllRead: _markAllAsRead,
//                   ),
//                   Expanded(
//                     child: _isLoading
//                         ? const Center(child: CircularProgressIndicator())
//                         : _filteredNotifications.isEmpty
//                             ? Center(
//                                 child: Column(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Icon(
//                                       Icons.notifications_none,
//                                       size: 64,
//                                       color: Colors.grey[400],
//                                     ),
//                                     const SizedBox(height: 16),
//                                     Text(
//                                       'Không có thông báo nào',
//                                       style: TextStyle(
//                                         fontSize: 18,
//                                         color: Colors.grey[600],
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               )
//                             : ListView.builder(
//                                 padding: const EdgeInsets.all(16),
//                                 itemCount: _filteredNotifications.length,
//                                 itemBuilder: (context, index) {
//                                   final notification =
//                                       _filteredNotifications[index];
//                                   return _NotificationCard(
//                                     notification: notification,
//                                     color: _getNotificationColor(notification.type),
//                                     icon: _getNotificationIcon(notification.type),
//                                     timeAgo: _formatTimeAgo(notification.createdAt),
//                                     onTap: () => _markAsRead(notification.id),
//                                     onDelete: () => _deleteNotification(notification.id),
//                                   );
//                                 },
//                               ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _NotificationCard extends StatelessWidget {
//   final NotificationModel notification;
//   final Color color;
//   final IconData icon;
//   final String timeAgo;
//   final VoidCallback onTap;
//   final VoidCallback onDelete;

//   const _NotificationCard({
//     required this.notification,
//     required this.color,
//     required this.icon,
//     required this.timeAgo,
//     required this.onTap,
//     required this.onDelete,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       elevation: notification.isRead ? 0 : 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//         side: notification.isRead
//             ? BorderSide(color: Colors.grey.shade200)
//             : BorderSide(color: color.withOpacity(0.3)),
//       ),
//       color: notification.isRead ? Colors.grey.shade50 : Colors.white,
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   color: color.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Icon(icon, color: color, size: 24),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Text(
//                             notification.title,
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: notification.isRead
//                                   ? FontWeight.w500
//                                   : FontWeight.w600,
//                               color: Colors.grey[800],
//                             ),
//                           ),
//                         ),
//                         if (!notification.isRead)
//                           Container(
//                             width: 8,
//                             height: 8,
//                             decoration: BoxDecoration(
//                               color: color,
//                               shape: BoxShape.circle,
//                             ),
//                           ),
//                       ],
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       notification.message,
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.grey[600],
//                       ),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         Icon(
//                           Icons.access_time,
//                           size: 14,
//                           color: Colors.grey[500],
//                         ),
//                         const SizedBox(width: 4),
//                         Text(
//                           timeAgo,
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey[500],
//                           ),
//                         ),
//                         const Spacer(),
//                         InkWell(
//                           onTap: onDelete,
//                           child: Icon(
//                             Icons.delete_outline,
//                             size: 20,
//                             color: Colors.grey[400],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
