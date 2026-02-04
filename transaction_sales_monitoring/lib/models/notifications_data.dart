// notifications_data.dart
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;
  final NotificationType type;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    required this.type,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

enum NotificationType {
  system,
  order,
  inventory,
  payment,
}

class NotificationsData {
  static List<NotificationItem> notifications = [
    NotificationItem(
      id: '1',
      title: 'Low Stock Alert',
      message: 'Lechon Belly is running low (5 remaining)',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      type: NotificationType.inventory,
    ),
    NotificationItem(
      id: '2',
      title: 'New Order Received',
      message: 'Order #ORD-2024-001 for ₱2,700',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      type: NotificationType.order,
    ),
    NotificationItem(
      id: '3',
      title: 'System Update',
      message: 'Database backup completed successfully',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      type: NotificationType.system,
    ),
    NotificationItem(
      id: '4',
      title: 'Payment Received',
      message: 'Payment of ₱8,000 confirmed for Order #ORD-2024-002',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      type: NotificationType.payment,
    ),
    NotificationItem(
      id: '5',
      title: 'Scheduled Maintenance',
      message: 'System maintenance scheduled for tomorrow 2:00 AM',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      type: NotificationType.system,
    ),
  ];

  static int get unreadCount {
    return notifications.where((notification) => !notification.isRead).length;
  }

  static void markAsRead(String id) {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index].isRead = true;
    }
  }

  static void markAllAsRead() {
    for (var notification in notifications) {
      notification.isRead = true;
    }
  }

  static void addNotification(NotificationItem notification) {
    notifications.insert(0, notification);
  }

  static void clearAll() {
    notifications.clear();
  }

  static int get readCount {
    return notifications.where((notification) => notification.isRead).length;
  }

  static List<NotificationItem> getNotificationsByType(NotificationType type) {
    return notifications.where((notification) => notification.type == type).toList();
  }

  static List<NotificationItem> get unreadNotifications {
    return notifications.where((notification) => !notification.isRead).toList();
  }

  static void removeOldNotifications(int days) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    notifications.removeWhere((notification) => notification.timestamp.isBefore(cutoffDate));
  }

  static void toggleReadStatus(String id) {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index].isRead = !notifications[index].isRead;
    }
  }
}