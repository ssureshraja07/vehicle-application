import '../entities/notification_entity.dart';

abstract class NotificationsRepository {
  Future<List<NotificationEntity>> getNotifications();
  Future<NotificationEntity> markAsRead(int notificationId);
  Future<int> getUnreadCount();
}
