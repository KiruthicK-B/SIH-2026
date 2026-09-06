import '../models/enums.dart';
import '../models/notification.dart';

/// Builds notification records. There is no real SMS/push provider — this
/// simulates the delivery event so the UI has something truthful to show,
/// including an occasional simulated delivery failure with a retry path
/// (README §7 "Notifications" edge cases).
class NotificationService {
  const NotificationService();

  NotificationItem createNotification({
    required String id,
    required String userId,
    required String title,
    required String message,
    required DateTime timestamp,
    NotificationType type = NotificationType.general,
    NotificationChannel channel = NotificationChannel.app,
    String language = 'en',
    NotificationDeliveryStatus deliveryStatus = NotificationDeliveryStatus.sent,
  }) {
    return NotificationItem(
      id: id,
      userId: userId,
      title: title,
      message: message,
      timestamp: timestamp,
      type: type,
      channel: channel,
      language: language,
      deliveryStatus: deliveryStatus,
    );
  }

  NotificationItem markRead(NotificationItem item) => item.copyWith(read: true);

  NotificationItem retry(NotificationItem item) => item.copyWith(
    deliveryStatus: NotificationDeliveryStatus.sent,
    retryCount: item.retryCount + 1,
  );
}
