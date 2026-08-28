import '../models/notification.dart';

/// Builds notification records. There is no real SMS/push provider — this
/// simulates the delivery event so the UI has something truthful to show.
class NotificationService {
  const NotificationService();

  NotificationItem createNotification({
    required String id,
    required String userId,
    required String title,
    required String message,
    required DateTime timestamp,
    NotificationKind kind = NotificationKind.general,
  }) {
    return NotificationItem(
      id: id,
      userId: userId,
      title: title,
      message: message,
      timestamp: timestamp,
      kind: kind,
    );
  }

  NotificationItem markRead(NotificationItem item) => item.copyWith(read: true);

  NotificationItem retry(NotificationItem item) =>
      item.copyWith(deliveryFailed: false);
}
