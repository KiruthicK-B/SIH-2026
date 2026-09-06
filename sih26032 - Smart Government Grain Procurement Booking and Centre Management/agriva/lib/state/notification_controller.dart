import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/notification.dart';
import '../repositories/repository_providers.dart';
import 'data_revision.dart';

final notificationsForUserProvider =
    FutureProvider.family<List<NotificationItem>, String>((ref, userId) {
      ref.watch(dataRevisionProvider);
      return ref.read(notificationRepositoryProvider).forUser(userId);
    });

final notificationControllerProvider = Provider<NotificationController>(
  (ref) => NotificationController(ref),
);

/// In-app notification center (README §5.1 "Notifications") — read state,
/// mark-all-read, and retrying a simulated failed delivery.
class NotificationController {
  final Ref ref;
  const NotificationController(this.ref);

  void _bump() => ref.read(dataRevisionProvider.notifier).bump();

  Future<void> markRead(String id) async {
    final repo = ref.read(notificationRepositoryProvider);
    final item = await repo.getById(id);
    if (item == null) return;
    await repo.save(item.copyWith(read: true));
    _bump();
  }

  Future<void> markAllRead(String userId) async {
    final repo = ref.read(notificationRepositoryProvider);
    final items = await repo.forUser(userId);
    for (final item in items.where((n) => !n.read)) {
      await repo.save(item.copyWith(read: true));
    }
    _bump();
  }

  Future<void> retryDelivery(String id) async {
    final repo = ref.read(notificationRepositoryProvider);
    final item = await repo.getById(id);
    if (item == null) return;
    await repo.save(
      item.copyWith(
        deliveryStatus: NotificationDeliveryStatus.sent,
        retryCount: item.retryCount + 1,
      ),
    );
    _bump();
  }
}
